import RPi.GPIO as GPIO
import time
import subprocess
import os
import cv2
import pytesseract
import numpy as np

# Configuración de GPIO
PIR_PIN = 17  # GPIO 17
GPIO.setmode(GPIO.BCM)
GPIO.setup(PIR_PIN, GPIO.IN)

def tomar_foto():
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    nombre_imagen = f"imagen_{timestamp}.jpg"
    ruta_imagen = f"/home/pi/{nombre_imagen}"
    comando_foto = ["libcamera-still", "-o", ruta_imagen, "--nopreview"]
    resultado = subprocess.run(comando_foto)
    if resultado.returncode == 0:
        print(f"Imagen capturada: {nombre_imagen}")
        return ruta_imagen
    else:
        print("Error al capturar la imagen.")
        return None

def detectar_placa(ruta_imagen):
    if ruta_imagen is None:
        return None
    # Leer la imagen
    imagen = cv2.imread(ruta_imagen)
    if imagen is None:
        print("No se pudo leer la imagen.")
        return None

    # Convertir a escala de grises
    gris = cv2.cvtColor(imagen, cv2.COLOR_BGR2GRAY)
    # Aplicar filtro bilateral para reducir el ruido
    gris = cv2.bilateralFilter(gris, 11, 17, 17)
    # Detectar bordes
    bordes = cv2.Canny(gris, 30, 200)
    # Encontrar contornos
    cnts, _ = cv2.findContours(bordes.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:10]
    placa_contorno = None

    for c in cnts:
        perimetro = cv2.arcLength(c, True)
        aproximacion = cv2.approxPolyDP(c, 0.018 * perimetro, True)
        if len(aproximacion) == 4:
            placa_contorno = aproximacion
            x, y, w, h = cv2.boundingRect(c)
            placa_imagen = imagen[y:y + h, x:x + w]
            break

    if placa_contorno is None:
        print("No se encontró placa en la imagen.")
        return None

    # Reconocer texto con Tesseract
    placa_gris = cv2.cvtColor(placa_imagen, cv2.COLOR_BGR2GRAY)
    _, placa_binaria = cv2.threshold(placa_gris, 127, 255, cv2.THRESH_BINARY)
    texto = pytesseract.image_to_string(placa_binaria, config='--psm 8')

    # Limpiar el texto reconocido
    texto = ''.join(e for e in texto if e.isalnum())
    if texto:
        print(f"Placa detectada: {texto}")
        return texto
    else:
        print("No se pudo reconocer el texto de la placa.")
        return None

def guardar_placa(texto_placa):
    if texto_placa is None:
        return
    ruta_archivo = "/home/pi/placas_detectadas.txt"
    with open(ruta_archivo, "a") as archivo:
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        archivo.write(f"{timestamp}: {texto_placa}\n")
    print(f"Placa guardada en {ruta_archivo}")
    transferir_archivo(ruta_archivo)

def transferir_imagen(ruta_imagen):
    if ruta_imagen is None:
        return
    # Datos de tu computador
    usuario_pc = "isabela"
    ip_pc = "192.168.10.9"
    ruta_destino = "/Users/isabela/Desktop/Raspberrypi_fotos/"
    comando_scp = [
        "scp",
        ruta_imagen,
        f"{usuario_pc}@{ip_pc}:{ruta_destino}"
    ]
    print(f"Ejecutando comando: {' '.join(comando_scp)}")
    resultado = subprocess.run(comando_scp, capture_output=True, text=True)
    if resultado.returncode == 0:
        print(f"Imagen transferida a {usuario_pc}@{ip_pc}:{ruta_destino}")
    else:
        print("Error al transferir la imagen:")
        print(resultado.stderr)

def transferir_archivo(ruta_archivo):
    # Datos de tu computador
    usuario_pc = "isabela"
    ip_pc = "192.168.10.9"
    ruta_destino = "/Users/isabela/Desktop/Raspberrypi_fotos/"
    comando_scp = [
        "scp",
        ruta_archivo,
        f"{usuario_pc}@{ip_pc}:{ruta_destino}"
    ]
    print(f"Transfiriendo archivo de placas: {' '.join(comando_scp)}")
    resultado = subprocess.run(comando_scp, capture_output=True, text=True)
    if resultado.returncode == 0:
        print(f"Archivo de placas transferido a {usuario_pc}@{ip_pc}:{ruta_destino}")
    else:
        print("Error al transferir el archivo de placas:")
        print(resultado.stderr)

try:
    print("Esperando detección de movimiento...")
    while True:
        if GPIO.input(PIR_PIN):
            print("¡Movimiento detectado!")
            ruta_imagen = tomar_foto()
            texto_placa = detectar_placa(ruta_imagen)
            guardar_placa(texto_placa)
            transferir_imagen(ruta_imagen)
            # Esperar para evitar múltiples capturas consecutivas
            time.sleep(5)
        time.sleep(0.1)
except KeyboardInterrupt:
    print("Programa terminado por el usuario")
finally:
    GPIO.cleanup()
