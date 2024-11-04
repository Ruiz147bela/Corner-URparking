//
//  AppDelegate.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Inicializa Firebase
        FirebaseApp.configure()

        // Solicita permisos para notificaciones
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Permisos de notificaciones otorgados.")
            } else {
                print("Permisos de notificaciones denegados.")
            }
        }

        // Registra para notificaciones push
        application.registerForRemoteNotifications()

        // Asigna el delegate para Firebase Messaging
        Messaging.messaging().delegate = self

        return true
    }

    // Este método recibe el token FCM
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("Token FCM: \(fcmToken)")

        // Aquí podrías guardar el token en Firestore o enviarlo a tu backend
    }

    // Este método maneja las notificaciones recibidas cuando la app está en primer plano
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    // Este método maneja el token APNs
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
