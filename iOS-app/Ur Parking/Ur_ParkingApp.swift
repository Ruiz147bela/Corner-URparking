//
//  Ur_ParkingApp.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import SwiftUI
import Firebase

@main
struct Ur_ParkingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            InicioView()
        }
    }
}











