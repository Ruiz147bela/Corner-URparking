//
//  FirestoreManager.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import FirebaseFirestore

class FirestoreManager {
    private let db = Firestore.firestore()
    private let reservasCollection = "reservas"
    
    // Función para agregar solo la placa y reservar en Firestore
    func agregarReserva(placa: String, horaIngreso: String, horaSalida: String, fecha: String, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "placa": placa,
            "horaIngreso": horaIngreso,
            "horaSalida": horaSalida,
            "fecha": fecha
        ]
        
        print("Datos a guardar en Firestore: \(data)")  // Depuración para verificar los datos
        
        db.collection(reservasCollection).addDocument(data: data) { error in
            if let error = error {
                print("Error al guardar la reserva en Firestore: \(error.localizedDescription)")
            } else {
                print("Reserva guardada exitosamente en Firestore.")
            }
            completion(error)
        }
    }
}

