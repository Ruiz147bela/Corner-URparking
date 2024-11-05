import cv2
import numpy as np
import pytesseract
import time
from picamera2 import Picamera2  # Biblioteca para manejar la cámara del Raspberry Pi
import RPi.GPIO as GPIO

# Configurar la ruta a Tesseract en tu sistema
pytesseract.pytesseract.tesseract_cmd = '/usr/bin/tesseract'  # Cambiar la ruta según la ubicación en Raspberry Pi

# Configuración de los relés conectados a los láseres
LASER_PINS = [18, 23, 24, 25]  # Pines a los que están conectados los relés que controlan los láseres
GPIO.setmode(GPIO.BCM)
for pin in LASER_PINS:
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.HIGH)  # Encender todos los láseres al inicio

# Inicializar la cámara de Raspberry Pi
camera = Picamera2()
camera_config = camera.create_still_configuration()
camera.configure(camera_config)

# Función para mejorar la imagen
def mejorar_imagen(imagen):
    gris = cv2.cvtColor(imagen, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gris = clahe.apply(gris)
    gris = cv2.GaussianBlur(gris, (5, 5), 0)
    altura_optima = 400
    escala = altura_optima / gris.shape[0]
    gris = cv2.resize(gris, None, fx=escala, fy=escala, interpolation=cv2.INTER_LINEAR)
    imagen_binarizada = cv2.adaptiveThreshold(
        gris, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 15, 10
    )
    kernel = np.ones((3, 3), np.uint8)
    imagen_binarizada = cv2.morphologyEx(imagen_binarizada, cv2.MORPH_CLOSE, kernel)

    # Mostrar la imagen binarizada
    cv2.imshow("Imagen Binarizada", imagen_binarizada)
    cv2.waitKey(1)

    return imagen_binarizada

# Función para detectar la placa en la imagen
def detectar_placa(imagen):
    imagen_mejorada = mejorar_imagen(imagen)
    imagen_mejorada = cv2.bilateralFilter(imagen_mejorada, 11, 17, 17)
    bordes = cv2.Canny(imagen_mejorada, 30, 200)
    cnts, _ = cv2.findContours(bordes.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:10]
    placa_imagen = None

    for c in cnts:
        perimetro = cv2.arcLength(c, True)
        aproximacion = cv2.approxPolyDP(c, 0.018 * perimetro, True)
        if len(aproximacion) == 4:
            x, y, w, h = cv2.boundingRect(c)
            placa_imagen = imagen_mejorada[y:y + h, x:x + w]
            break

    if placa_imagen is None:
        print("No se encontró una placa en la imagen.")
        return None

    altura_optima = 150
    escala = altura_optima / placa_imagen.shape[0]
    placa_redimensionada = cv2.resize(placa_imagen, None, fx=escala, fy=escala, interpolation=cv2.INTER_LINEAR)
    _, placa_binaria = cv2.threshold(placa_redimensionada, 110, 255, cv2.THRESH_BINARY)
    kernel = np.ones((3, 3), np.uint8)
    placa_binaria = cv2.morphologyEx(placa_binaria, cv2.MORPH_CLOSE, kernel)

    # Mostrar la imagen de la placa detectada
    cv2.imshow("Placa Detectada", placa_binaria)
    cv2.waitKey(1)

    config = '--psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    texto = pytesseract.image_to_string(placa_binaria, config=config)
    texto = ''.join(e for e in texto if e.isalnum())

    if texto:
        print(f"Placa detectada: {texto}")
        return texto
    else:
        print("No se pudo reconocer el texto de la placa.")
        return None

# Función para capturar imagen con la cámara del Raspberry Pi
def capturar_imagen_con_raspberry_pi_camera():
    print("Capturando imagen...")
    camera.start()
    time.sleep(2)  # Esperar a que la cámara se estabilice
    frame = camera.capture_array()
    camera.stop()
    return frame

# Función para apagar los láseres temporalmente
def apagar_lasers_temporalmente():
    print("Apagando láseres...")
    for pin in LASER_PINS:
        GPIO.output(pin, GPIO.LOW)
    time.sleep(5)  # Esperar 5 segundos
    for pin in LASER_PINS:
        GPIO.output(pin, GPIO.HIGH)
    print("Láseres encendidos nuevamente.")

# Proceso principal
if __name__ == "__main__":
    print("Esperando 10 segundos antes de comenzar...")
    time.sleep(10)  # Espera inicial para estabilizar el sistema

    while True:
        imagen = capturar_imagen_con_raspberry_pi_camera()
        if imagen is not None:
            texto_placa = detectar_placa(imagen)
            if texto_placa:
                print("Realizando acción con los láseres...")
                apagar_lasers_temporalmente()  # Simula el parpadeo de los láseres
        time.sleep(10)  # Intervalo entre capturas
