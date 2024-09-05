# Proyecto UR Parking

Este repositorio contiene el código de la aplicación iOS y el sistema de hardware para gestionar las reservas y el control de acceso al parqueadero mediante reconocimiento de placas.

## Estructura del proyecto

- `ios-app/`: Contiene el código fuente de la aplicación iOS desarrollada en Swift con Xcode.
- `hardware-system/`: Contiene el código fuente del sistema de hardware que corre en un Raspberry Pi utilizando OpenCV y Firebase.

## Instrucciones para la App iOS

1. Ve a la carpeta `ios-app`.
2. Abre el archivo `App.xcworkspace` en Xcode.
3. Ejecuta `pod install` para instalar las dependencias de Firebase.
4. Configura Firebase según el archivo `GoogleService-Info.plist`.

## Instrucciones para el Sistema de Hardware

1. Ve a la carpeta `hardware-system`.
2. Asegúrate de tener instalado Python 3 y OpenCV.
3. Ejecuta `python3 camera_control.py` para inicializar el sistema de reconocimiento de placas.
4. Configura las credenciales de Firebase en el script `firebase_interaction.py`.

## Dependencias

- Firebase para manejo de datos en tiempo real y notificaciones.
- OpenCV para reconocimiento de imágenes.
