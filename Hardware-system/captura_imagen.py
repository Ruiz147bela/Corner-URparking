import subprocess

def capture_image():
    # Definir el nombre del archivo de salida
    output_file = 'vehicle_plate.jpg'

    # Ejecutar el comando de libcamera para capturar la imagen
    command = f'libcamera-still -o {output_file}'

    try:
        # Ejecutar el comando
        subprocess.run(command, shell=True, check=True)
        print(f"Imagen capturada y guardada como '{output_file}'")
    except subprocess.CalledProcessError as e:
        print(f"Error al capturar la imagen: {e}")

# Llamada a la función para capturar la imagen
capture_image()
