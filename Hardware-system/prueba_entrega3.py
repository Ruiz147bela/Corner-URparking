import cv2
import numpy as np
import pytesseract
import time
import firebase_admin
from firebase_admin import credentials, firestore
from picamera2 import Picamera2  # Biblioteca para manejar la cámara del Raspberry Pi
import RPi.GPIO as GPIO

# Configurar la ruta a Tesseract en tu sistema
pytesseract.pytesseract.tesseract_cmd = '/usr/bin/tesseract'  # Cambiar la ruta según la ubicación en Raspberry Pi

# Inicializar Firebase
cred = credentials.Certificate("/home/raspberry/Downloads/Corner-URparking-main/iOS-app/ur-parking-68811-firebase-adminsdk-5bpqm-58ecf1becb.json")
firebase_admin.initialize_app(cred)

# Conectar a Firestore
db = firestore.client()

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

def mejorar_imagen(imagen):
    gris = cv2.cvtColor(imagen, cv2.COLOR_BGR2GRAY)
    gris = cv2.equalizeHist(gris)
    gris = cv2.GaussianBlur(gris, (3, 3), 0)
    alfa = 1.5
    beta = 50
    gris = cv2.convertScaleAbs(gris, alpha=alfa, beta=beta)
    altura_optima = 400
    escala = altura_optima / gris.shape[0]
    gris = cv2.resize(gris, None, fx=escala, fy=escala, interpolation=cv2.INTER_LINEAR)
    _, imagen_binarizada = cv2.threshold(gris, 110, 255, cv2.THRESH_BINARY)
    kernel = np.ones((3, 3), np.uint8)
    imagen_binarizada = cv2.morphologyEx(imagen_binarizada, cv2.MORPH_CLOSE, kernel)
    cv2.imshow("Imagen Binarizada", imagen_binarizada)
    cv2.waitKey(3000)
    cv2.destroyAllWindows()

    return imagen_binarizada

def detectar_placa(imagen):
    imagen_mejorada = mejorar_imagen(imagen)
    imagen_mejorada = cv2.bilateralFilter(imagen_mejorada, 11, 17, 17)
    bordes = cv2.Canny(imagen_mejorada, 30, 200)
    cnts, _ = cv2.findContours(bordes.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:10]
    placa_contorno = None
    placa_imagen = None
    
    for c in cnts:
        perimetro = cv2.arcLength(c, True)
        aproximacion = cv2.approxPolyDP(c, 0.018 * perimetro, True)
        if len(aproximacion) == 4:
            placa_contorno = aproximacion
            x, y, w, h = cv2.boundingRect(c)
            placa_imagen = imagen_mejorada[y:y + h, x:x + w]
            break
    
    if placa_contorno is None:
        return None

    altura_optima = 150
    escala = altura_optima / placa_imagen.shape[0]
    placa_redimensionada = cv2.resize(placa_imagen, None, fx=escala, fy=escala, interpolation=cv2.INTER_LINEAR)
    _, placa_binaria = cv2.threshold(placa_redimensionada, 110, 255, cv2.THRESH_BINARY)
    kernel = np.ones((3, 3), np.uint8)
    placa_binaria = cv2.morphologyEx(placa_binaria, cv2.MORPH_CLOSE, kernel)
    cv2.imshow("Placa Binarizada", placa_binaria)
    cv2.waitKey(3000)
    cv2.destroyAllWindows()

    config = '--psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    texto = pytesseract.image_to_string(placa_binaria, config=config)
    texto = ''.join(e for e in texto if e.isalnum())

    return texto if texto else None

def capturar_imagen_con_raspberry_pi_camera():
    # Capturar una imagen usando la cámara del Raspberry Pi
    print("Capturando imagen...")
    camera.start()
    time.sleep(2)  # Esperar a que la cámara se estabilice
    frame = camera.capture_array()
    camera.stop()
    return frame

def buscar_placa_en_firebase(placa):
    coleccion_reservas = db.collection('reservas')
    consulta = coleccion_reservas.where('placa', '==', placa).get()
    return bool(consulta)

def apagar_lasers_temporalmente():
    print("Apagando láseres...")
    for pin in LASER_PINS:
        GPIO.output(pin, GPIO.LOW)
    time.sleep(5)  # Esperar 5 segundos
    for pin in LASER_PINS:
        GPIO.output(pin, GPIO.HIGH)
    print("Láseres encendidos nuevamente.")

def iniciar_proceso():
    print("Esperando 10 segundos antes de comenzar...")
    time.sleep(10)  # Espera inicial para estabilizar el sistema
    while True:
        imagen = capturar_imagen_con_raspberry_pi_camera()
        if imagen is not None:
            texto_placa = detectar_placa(imagen)
            if texto_placa:
                if buscar_placa_en_firebase(texto_placa):
                    print("Acceso permitido")
                    apagar_lasers_temporalmente()
                else:
                    print("Acceso denegado")
        time.sleep(10)  # Intervalo entre capturas

if __name__ == "__main__":
    iniciar_proceso()
