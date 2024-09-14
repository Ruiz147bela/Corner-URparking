import RPi.GPIO as GPIO
import time
import cv2

# Configuración del sensor PIR
PIR_PIN = 17
RELAY_PIN = 27

GPIO.setmode(GPIO.BCM)
GPIO.setup(PIR_PIN, GPIO.IN)
GPIO.setup(RELAY_PIN, GPIO.OUT)

# Función para capturar imagen de la cámara
def capturar_imagen():
    cam = cv2.VideoCapture(0)  # Ajusta según la cámara que estés usando
    ret, frame = cam.read()
    if ret:
        cv2.imwrite('/home/pi/placa.jpg', frame)  # Guarda la imagen
        print("Imagen capturada y guardada como 'placa.jpg'")
    else:
        print("Error al capturar la imagen")
    cam.release()

# Función para activar el láser (usando relé)
def activar_laser():
    GPIO.output(RELAY_PIN, GPIO.HIGH)
    print("Láser activado")
    time.sleep(5)  # Mantiene el láser activado por 5 segundos (ajustable)
    GPIO.output(RELAY_PIN, GPIO.LOW)
    print("Láser desactivado")

# Detección del sensor PIR
def deteccion_pir():
    if GPIO.input(PIR_PIN):
        print("Movimiento detectado, capturando imagen...")
        capturar_imagen()
    else:
        print("No se detecta movimiento")

try:
    while True:
        deteccion_pir()
        time.sleep(1)
except KeyboardInterrupt:
    print("Sistema terminado")
finally:
    GPIO.cleanup()
