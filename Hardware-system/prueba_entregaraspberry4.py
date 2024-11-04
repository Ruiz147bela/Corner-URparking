import cv2
import numpy as np
import pytesseract
import datetime
import firebase_admin
from firebase_admin import credentials, firestore
import json
import os
import time
from picamera2 import Picamera2  # Biblioteca para manejar la cámara del Raspberry Pi
import RPi.GPIO as GPIO

# Configurar la ruta a Tesseract en tu sistema
pytesseract.pytesseract.tesseract_cmd = '/usr/bin/tesseract'  # Cambiar la ruta según la ubicación en Raspberry Pi

# Inicializar Firebase
cred = credentials.Certificate("/home/raspberry/Downloads/Corner-URparking-main/iOS-app/ur-parking-68811-firebase-adminsdk-5bpqm-58ecf1becb.json")
firebase_admin.initialize_app(cred)

# Conectar a Firestore
db = firestore.client()

# Descargar los datos de Firebase y guardarlos localmente
def descargar_datos_firebase():
    coleccion_reservas = db.collection('reservas')
    reservas = coleccion_reservas.stream()
    datos = []

    for reserva in reservas:
        datos.append(reserva.to_dict())

    # Guardar los datos en un archivo JSON
    with open('reservas_data.json', 'w') as archivo:
        json.dump(datos, archivo)
    print("Datos descargados y guardados en reservas_data.json")

# Cargar datos desde un archivo JSON
def cargar_datos_locales():
    if os.path.exists('reservas_data.json'):
        with open('reservas_data.json', 'r') as archivo:
            return json.load(archivo)
    else:
        return []

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

# Función para buscar localmente
def buscar_placa_localmente(placa, datos_locales):
    fecha_actual = datetime.datetime.now().strftime("%Y-%m-%d")
    for reserva in datos_locales:
        if reserva.get('placa') == placa and reserva.get('fecha') == fecha_actual:
            hora_ingreso = reserva.get('horaIngreso')
            hora_salida = reserva.get('horaSalida')
            formato_fecha_hora = "%Y-%m-%d %H:%M"
            hora_actual = datetime.datetime.now()

            if hora_ingreso and hora_salida:
                fecha_hora_ingreso = datetime.datetime.strptime(f"{fecha_actual} {hora_ingreso}", formato_fecha_hora)
                fecha_hora_salida = datetime.datetime.strptime(f"{fecha_actual} {hora_salida}", formato_fecha_hora)

                if fecha_hora_ingreso <= hora_actual <= fecha_hora_salida:
                    return True
    return False

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
    descargar_datos_firebase()  # Descargar los datos de Firebase al iniciar
    datos_locales = cargar_datos_locales()  # Cargar los datos descargados

    print("Esperando 10 segundos antes de comenzar...")
    time.sleep(10)  # Espera inicial para estabilizar el sistema

    while True:
        imagen = capturar_imagen_con_raspberry_pi_camera()
        if imagen is not None:
            texto_placa = detectar_placa(imagen)
            if texto_placa:
                if buscar_placa_localmente(texto_placa, datos_locales):
                    print("Acceso permitido")
                    apagar_lasers_temporalmente()
                else:
                    print("Acceso denegado")
        time.sleep(10)  # Intervalo entre capturas
