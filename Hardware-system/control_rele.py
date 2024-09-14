import RPi.GPIO as GPIO
import time

# Configurar el pin GPIO del relé
RELAY_PIN = 27  # Pin GPIO 27 en la Raspberry Pi
GPIO.setmode(GPIO.BCM)
GPIO.setup(RELAY_PIN, GPIO.OUT)
GPIO.output(RELAY_PIN, GPIO.LOW)  # Asegura que el relé esté apagado inicialmente

# Función para activar el láser (abrir barrera)
def activate_laser():
    print("Activando el láser...")
    GPIO.output(RELAY_PIN, GPIO.HIGH)  # Activa el relé
    time.sleep(5)  # Mantén la barrera abierta por 5 segundos
    GPIO.output(RELAY_PIN, GPIO.LOW)   # Apaga el relé (cierra la barrera)
    print("Desactivando el láser.")

# Función principal de prueba
def main():
    try:
        while True:
            entrada = input("Presiona 'y' para activar el láser o 'q' para salir: ")
            if entrada == 'y':
                activate_laser()
            elif entrada == 'q':
                break
            else:
                print("Opción no válida. Presiona 'y' para activar el láser o 'q' para salir.")
            time.sleep(0.1)  # Añadir un pequeño retraso para evitar múltiples entradas rápidas
    finally:
        GPIO.cleanup()  # Limpia la configuración GPIO al finalizar

if __name__ == '__main__':
    main()
