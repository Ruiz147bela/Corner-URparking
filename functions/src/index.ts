import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Inicializar Firebase Admin SDK
admin.initializeApp();

// Función que escucha la creación de una reserva y envía una notificación
export const notificacionReservaConfirmada = functions.firestore
  .document("reservas/{reservaId}")
  .onCreate(async (snapshot) => {
    const data = snapshot.data();

    // Obtén el token FCM del dispositivo del usuario
    const fcmToken = data?.fcmToken; // Asegúrate de que este token
    // esté guardado en Firestore

    if (!fcmToken) {
      console.error("No FCM token provided");
      return;
    }

    // Crea el mensaje de notificación
    const message = {
      notification: {
        title: "Reserva Confirmada",
        body: `Tu reserva ha sido confirmada para el ${data?.fecha} desde` +
              ` ${data?.horaIngreso} hasta ${data?.horaSalida}.`,
      },
      token: fcmToken,
    };

    // Envía la notificación al dispositivo del usuario
    try {
      const response = await admin.messaging().send(message);
      console.log("Notificación enviada exitosamente:", response);
    } catch (error) {
      console.error("Error al enviar la notificación:", error);
    }
  });
