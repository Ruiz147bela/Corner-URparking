import cv2
import numpy as np
import pytesseract
import datetime
import firebase_admin
from firebase_admin import credentials, firestore

# Configurar la ruta a Tesseract en tu sistema
pytesseract.pytesseract.tesseract_cmd = '/opt/homebrew/bin/tesseract'

# Inicializar Firebase
cred = credentials.Certificate("/Users/isabela/Desktop/Corner-URparking/Hardware-system/ur-parking-68811-firebase-adminsdk-5bpqm-441bed5224.json")
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
    altura_optima = 400  # Aumentamos un poco la altura para una mejor detección
    escala = altura_optima / gris.shape[0]
    gris = cv2.resize(gris, None, fx=escala, fy=escala, interpolation=cv2.INTER_LINEAR)
    
    # Aplicar un umbral binario ajustado
    _, imagen_binarizada = cv2.threshold(gris, 110, 255, cv2.THRESH_BINARY)  # Reducir el valor del umbral
    
    # Aplicar un filtro morfológico de cierre para eliminar ruido (artefactos pequeños)
    kernel = np.ones((3, 3), np.uint8)
    imagen_binarizada = cv2.morphologyEx(imagen_binarizada, cv2.MORPH_CLOSE, kernel)
    
    # Mostrar la imagen binarizada por un tiempo limitado (3 segundos)
    cv2.imshow("Imagen Binarizada", imagen_binarizada)
    cv2.waitKey(3000)  # Esperar 3 segundos
    cv2.destroyAllWindows()

    return imagen_binarizada

def detectar_placa(imagen):
    # Mejorar la imagen antes de buscar la placa
    imagen_mejorada = mejorar_imagen(imagen)
    
    # Aplicar filtro bilateral para reducir el ruido
    imagen_mejorada = cv2.bilateralFilter(imagen_mejorada, 11, 17, 17)
    
    # Detectar bordes con Canny
    bordes = cv2.Canny(imagen_mejorada, 30, 200)
    
    # Encontrar contornos
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
            print(f"Posible placa detectada en las coordenadas: x={x}, y={y}, ancho={w}, alto={h}")
            break
    
    if placa_contorno is None:
        print("No se encontró una placa en la imagen.")
        return None
    
    # Redimensionar la placa si es muy pequeña o muy grande
    altura_optima = 150  # Ajustar la altura para la placa
    escala = altura_optima / placa_imagen.shape[0]
    placa_redimensionada = cv2.resize(placa_imagen, None, fx=escala, fy=escala, interpolation=cv2.INTER_LINEAR)
    
    # Aplicar un filtro de limpieza adicional
    _, placa_binaria = cv2.threshold(placa_redimensionada, 110, 255, cv2.THRESH_BINARY)
    
    # Aplicar un filtro morfológico a la placa binarizada para eliminar el ruido
    kernel = np.ones((3, 3), np.uint8)
    placa_binaria = cv2.morphologyEx(placa_binaria, cv2.MORPH_CLOSE, kernel)

    # Mostrar la imagen de la placa binarizada antes de pasarla a Tesseract
    cv2.imshow("Placa Binarizada", placa_binaria)
    cv2.waitKey(3000)
    cv2.destroyAllWindows()

    # Configurar Tesseract con `psm 8` (una sola línea de texto)
    config = '--psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    
    texto = pytesseract.image_to_string(placa_binaria, config=config)

    # Limpiar el texto reconocido
    texto = ''.join(e for e in texto if e.isalnum())
    
    if texto:
        print(f"Placa detectada: {texto}")
        return texto
    else:
        print("No se pudo reconocer el texto de la placa.")
        return None

def capturar_imagen_con_webcam():
    # Iniciar la captura de video desde la webcam
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        print("Error al abrir la cámara")
        return None

    print("Presiona 's' para capturar la imagen")

    while True:
        # Leer cuadro por cuadro de la webcam
        ret, frame = cap.read()

        if not ret:
            print("Error al capturar la imagen")
            break

        # Mostrar la imagen en tiempo real
        cv2.imshow("Presiona 's' para capturar la imagen", frame)

        # Esperar a que el usuario presione la tecla 's' para capturar la imagen
        if cv2.waitKey(1) & 0xFF == ord('s'):
            print("Imagen capturada")
            break

    # Liberar la cámara y cerrar todas las ventanas
    cap.release()
    cv2.destroyAllWindows()
    
    return frame

def guardar_texto_en_archivo(texto):
    # Crear un archivo de texto con el nombre basado en la fecha y hora actual
    timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    ruta_archivo = f"placa_{timestamp}.txt"

    # Guardar el texto en el archivo
    with open(ruta_archivo, 'w') as archivo:
        archivo.write(texto)
    
    print(f"Texto guardado en {ruta_archivo}")

def buscar_placa_en_firebase(placa):
    # Obtener la fecha actual en el formato esperado
    fecha_actual = datetime.datetime.now().strftime("%Y-%m-%d")
    
    # Buscar la placa en la colección de reservas en Firestore para la fecha actual
    coleccion_reservas = db.collection('reservas')
    consulta = coleccion_reservas.where('placa', '==', placa).where('fecha', '==', fecha_actual).get()

    if consulta:
        reserva = consulta[0].to_dict()  # Asumiendo que solo hay una reserva para la placa y la fecha actual
        print(f"Datos de la reserva: {reserva}")  # Imprime los datos recuperados para depuración

        if 'horaIngreso' in reserva and 'horaSalida' in reserva:
            hora_ingreso = reserva['horaIngreso']
            hora_salida = reserva['horaSalida']

            # Unir la fecha actual con la hora para crear los objetos datetime
            formato_fecha_hora = "%Y-%m-%d %H:%M"
            hora_actual = datetime.datetime.now()
            fecha_hora_ingreso = datetime.datetime.strptime(f"{fecha_actual} {hora_ingreso}", formato_fecha_hora)
            fecha_hora_salida = datetime.datetime.strptime(f"{fecha_actual} {hora_salida}", formato_fecha_hora)

            if fecha_hora_ingreso <= hora_actual <= fecha_hora_salida:
                if hora_actual > fecha_hora_ingreso:
                    tiempo_tarde = hora_actual - fecha_hora_ingreso
                    minutos_tarde = tiempo_tarde.total_seconds() / 60
                    print(f"Reserva activa encontrada para la placa {placa}, pero llegaste {int(minutos_tarde)} minutos tarde.")
                else:
                    print(f"Reserva activa encontrada para la placa {placa} dentro del horario permitido.")
                return True
            else:
                print(f"La placa {placa} no tiene una reserva activa en este momento.")
                return False
        else:
            print(f"La reserva para la placa {placa} no contiene las claves 'horaIngreso' o 'horaSalida'.")
            return False
    else:
        print(f"No se encontró reserva para la placa {placa} en la fecha de hoy.")
        return False


if __name__ == "__main__":
    # Capturar una imagen desde la webcam
    imagen = capturar_imagen_con_webcam()

    if imagen is not None:
        # Detectar la placa en la imagen capturada
        texto_placa = detectar_placa(imagen)
        
        if texto_placa:
            # Buscar la placa en Firebase
            if buscar_placa_en_firebase(texto_placa):
                print("Acceso permitido")
            else:
                print("Acceso denegado")
            
            # Guardar el texto de la placa en un archivo
            guardar_texto_en_archivo(texto_placa)

