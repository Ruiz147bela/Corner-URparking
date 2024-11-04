const express = require("express");
const admin = require("firebase-admin");
const bodyParser = require("body-parser");

// Inicializar Firebase Admin SDK con el archivo de credenciales (asegúrate de tener el archivo en el lugar correcto)
const serviceAccount = require("/Users/isabela/Desktop/Corner-URparking/ur-parking-backend/ur-parking-68811-firebase-adminsdk-5bpqm-54cdd67f13.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();
app.use(bodyParser.json());

// Endpoint para enviar notificaciones push
app.post("/enviar-notificacion", async (req, res) => {
  const { fcmToken, title, body } = req.body;

  if (!fcmToken || !title || !body) {
    return res.status(400).send("Faltan campos en la solicitud");
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: fcmToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Notificación enviada exitosamente:", response);
    res.status(200).send("Notificación enviada");
  } catch (error) {
    console.error("Error al enviar la notificación:", error);
    res.status(500).send("Error al enviar la notificación");
  }
});

// Iniciar el servidor en el puerto 3000
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor escuchando en el puerto ${PORT}`);
});
