//
//  AppDelegate.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import UIKit
import Firebase
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Inicializa Firebase
        FirebaseApp.configure()

        // Solicita permisos para notificaciones locales
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permiso para notificaciones locales otorgado.")
            } else {
                print("Permiso para notificaciones locales denegado.")
            }
        }

        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Muestra la notificación cuando la aplicación está en primer plano
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}


