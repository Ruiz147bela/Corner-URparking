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

## Dependencias

- Firebase para manejo de datos en tiempo real y notificaciones.
- OpenCV para reconocimiento de imágenes.

## Bitácora 
https://www.canva.com/design/DAGP680Mk6Q/nUHhgog_YMWPIQTe2zmGiQ/view?utm_content=DAGP680Mk6Q&utm_campaign=designshare&utm_medium=link&utm_source=editor
