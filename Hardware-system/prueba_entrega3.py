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
    # (tu función de mejora de imagen aquí)
    return imagen_binarizada

def detectar_placa(imagen):
    # (tu función de detección de placa aquí)
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
