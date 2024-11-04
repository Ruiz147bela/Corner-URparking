//
//  NotificacionLocales.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 8/10/24.
//

import UserNotifications

func programarNotificacionReserva() {
    let content = UNMutableNotificationContent()
    content.title = "Reserva Confirmada"
    content.body = "Tu reserva ha sido confirmada. Nos vemos pronto."
    content.sound = .default

    // Configurar la notificación para que se dispare en 5 segundos
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

    // Crear la solicitud de notificación
    let request = UNNotificationRequest(identifier: "reservaConfirmada", content: content, trigger: trigger)

    // Agregar la notificación al centro de notificaciones
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error al programar la notificación: \(error.localizedDescription)")
        } else {
            print("Notificación programada exitosamente.")
        }
    }
}
