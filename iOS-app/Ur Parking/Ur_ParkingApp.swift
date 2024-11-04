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
    
    init() {
        // Configurar Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            InicioView() // Vista inicial de la aplicación
        }
    }
}











