import RPi.GPIO as GPIO
import time
import cv2
import pytesseract
import firebase_admin
from firebase_admin import credentials, firestore

# Configuración del hardware
PIR_PIN = 17
RELAY_PIN = 27

GPIO.setmode(GPIO.BCM)
GPIO.setup(PIR_PIN, GPIO.IN)
GPIO.setup(RELAY_PIN, GPIO.OUT)

# Conectar con Firebase
cred = credentials.Certificate("/ruta/a/credenciales.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Función para capturar imagen de la cámara
def capturar_imagen():
    cam = cv2.VideoCapture(0)
    ret, frame = cam.read()
    if ret:
        cv2.imwrite('/home/pi/placa.jpg', frame)
        print("Imagen capturada y guardada como 'placa.jpg'")
        return '/home/pi/placa.jpg'
    else:
        print("Error al capturar la imagen")
    cam.release()
    return None

# Función para extraer la placa de la imagen usando OCR
def leer_placa(imagen_path):
    img = cv2.imread(imagen_path)
    texto = pytesseract.image_to_string(img, config='--psm 8')  # 'psm 8' es adecuado para una sola línea de texto
    placa = ''.join(e for e in texto if e.isalnum())  # Limpiar caracteres no alfanuméricos
    print(f"Placa detectada: {placa}")
    return placa

# Verificación de la placa en Firebase
def verificar_placa(placa):
    doc_ref = db.collection('reservas').document(placa)
    doc = doc_ref.get()
    if doc.exists:
        print(f"Placa {placa} encontrada, acceso permitido.")
        return True
    else:
        print(f"Placa {placa} no encontrada, acceso denegado.")
        return False

# Activar el láser usando el relé
def activar_laser():
    GPIO.output(RELAY_PIN, GPIO.HIGH)
    print("Láser activado")
    time.sleep(5)
    GPIO.output(RELAY_PIN, GPIO.LOW)
    print("Láser desactivado")

# Procesar el flujo completo del sistema
def deteccion_pir():
    if GPIO.input(PIR_PIN):
        print("Movimiento detectado, capturando imagen...")
        imagen = capturar_imagen()
        if imagen:
            placa = leer_placa(imagen)  # Extraer la placa de la imagen
            if verificar_placa(placa):
                activar_laser()
            else:
                print("Acceso denegado, láser activado.")
        else:
            print("No se pudo capturar la imagen")
    else:
        print("No se detecta movimiento")

# Ejecución del sistema
try:
    while True:
        deteccion_pir()
        time.sleep(1)
except KeyboardInterrupt:
    print("Sistema terminado")
finally:
    GPIO.cleanup()
