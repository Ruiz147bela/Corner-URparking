import RPi.GPIO as GPIO
import time

# Configurar el pin GPIO del relé
RELAY_PIN = 27  # Pin 13 en la Raspberry Pi
GPIO.setmode(GPIO.BCM)
GPIO.setup(RELAY_PIN, GPIO.OUT)

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
    finally:
        GPIO.cleanup()  # Limpia la configuración GPIO al finalizar

if __name__ == '__main__':
    main()
