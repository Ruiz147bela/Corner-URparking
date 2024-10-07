import cv2
import numpy as np
import pytesseract
import datetime
import firebase_admin
from firebase_admin import credentials, firestore

# Configurar la ruta a Tesseract en tu sistema
pytesseract.pytesseract.tesseract_cmd = '/opt/homebrew/bin/tesseract'

# Inicializar Firebase
cred = credentials.Certificate("/Users/isabela/Desktop/ur-parking-68811-firebase-adminsdk-5bpqm-441bed5224.json")
firebase_admin.initialize_app(cred)

# Conectar a Firestore
db = firestore.client()

def mejorar_imagen(imagen):
    # Convertir a escala de grises
    gris = cv2.cvtColor(imagen, cv2.COLOR_BGR2GRAY)
    
    # Aumentar el contraste usando la ecualización del histograma
    gris = cv2.equalizeHist(gris)
    
    # Aplicar desenfoque gaussiano para reducir el ruido
    gris = cv2.GaussianBlur(gris, (3, 3), 0)
    
    # Aumentar el contraste manualmente
    alfa = 1.5  # Contraste
    beta = 50   # Brillo
    gris = cv2.convertScaleAbs(gris, alpha=alfa, beta=beta)
    
    # Redimensionar la imagen para que tenga un tamaño óptimo para Tesseract
    altura_optima = 400
    escala = altura_optima / gris.shape[0]
    gris = cv2.resize(gris, None, fx=escala, fy=escala, interpolation=cv2.INTER_LINEAR)
    
    # Aplicar un umbral binario ajustado
    _, imagen_binarizada = cv2.threshold(gris, 110, 255, cv2.THRESH_BINARY)
    
    # Aplicar un filtro morfológico de cierre para eliminar ruido (artefactos pequeños)
    kernel = np.ones((3, 3), np.uint8)
    imagen_binarizada = cv2.morphologyEx(imagen_binarizada, cv2.MORPH_CLOSE, kernel)
    
    return imagen_binarizada

def detectar_placa(imagen):
    imagen_mejorada = mejorar_imagen(imagen)
    
    # Aplicar filtro bilateral para reducir el ruido
    imagen_mejorada = cv2.bilateralFilter(imagen_mejorada, 11, 17, 17)
    
    # Detectar bordes con Canny
    bordes = cv2.Canny(imagen_mejorada, 30, 200)
    
    # Encontrar contornos
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

    # Redimensionar la placa para la detección
    altura_optima = 150
    escala = altura_optima / placa_imagen.shape[0]
    placa_redimensionada = cv2.resize(placa_imagen, None, fx=escala, fy=escala, interpolation=cv2.INTER_LINEAR)
    
    _, placa_binaria = cv2.threshold(placa_redimensionada, 110, 255, cv2.THRESH_BINARY)
    
    # Aplicar un filtro morfológico para limpieza
    kernel = np.ones((3, 3), np.uint8)
    placa_binaria = cv2.morphologyEx(placa_binaria, cv2.MORPH_CLOSE, kernel)

    # Configurar Tesseract
    config = '--psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    
    texto = pytesseract.image_to_string(placa_binaria, config=config)
    texto = ''.join(e for e in texto if e.isalnum())
    
    if texto:
        print(f"Placa detectada: {texto}")
        return texto
    else:
        print("No se pudo reconocer el texto de la placa.")
        return None

def capturar_imagen_con_webcam(nombre_imagen):
    # Iniciar la captura de video
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        print("Error al abrir la cámara")
        return None

    print("Presiona 's' para capturar la imagen")

    while True:
        ret, frame = cap.read()
        if not ret:
            print("Error al capturar la imagen")
            break

        cv2.imshow("Capturando Imagen", frame)

        if cv2.waitKey(1) & 0xFF == ord('s'):
            print("Imagen capturada")
            cv2.imwrite(nombre_imagen, frame)
            break

    cap.release()
    cv2.destroyAllWindows()
    
    return frame

def buscar_placa_en_firebase(placa):
    fecha_actual = datetime.datetime.now().strftime("%Y-%m-%d")
    
    coleccion_reservas = db.collection('reservas')
    consulta = coleccion_reservas.where('placa', '==', placa).where('fecha', '==', fecha_actual).get()

    if consulta:
        reserva = consulta[0].to_dict()

        if 'horaIngreso' in reserva and 'horaSalida' in reserva:
            hora_ingreso = reserva['horaIngreso']
            hora_salida = reserva['horaSalida']
            formato_fecha_hora = "%Y-%m-%d %H:%M"
            hora_actual = datetime.datetime.now()
            fecha_hora_ingreso = datetime.datetime.strptime(f"{fecha_actual} {hora_ingreso}", formato_fecha_hora)
            fecha_hora_salida = datetime.datetime.strptime(f"{fecha_actual} {hora_salida}", formato_fecha_hora)

            if fecha_hora_ingreso <= hora_actual <= fecha_hora_salida:
                return True
            else:
                return False
        else:
            return False
    else:
        return False

def proceso_ingreso_salida():
    print("Capturando imagen de ingreso...")
    imagen_ingreso = capturar_imagen_con_webcam("ingreso.jpg")

    if imagen_ingreso is not None:
        texto_placa = detectar_placa(imagen_ingreso)
        
        if texto_placa and buscar_placa_en_firebase(texto_placa):
            print("Acceso permitido")
            
            # Capturar imagen al salir
            print("Capturando imagen de salida...")
            imagen_salida = capturar_imagen_con_webcam("salida.jpg")
            if imagen_salida is not None:
                detectar_placa(imagen_salida)
        else:
            print("Acceso denegado")

if __name__ == "__main__":
    proceso_ingreso_salida()
