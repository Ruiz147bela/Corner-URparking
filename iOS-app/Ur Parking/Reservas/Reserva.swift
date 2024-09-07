//
//  Reserva.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 7/09/24.
//

import Foundation

struct Reserva: Identifiable {
    let id = UUID() // Generar un identificador único
    let placa: String
    let horaIngreso: String
    let horaSalida: String
    let fecha: String
    
    // Método para crear una Reserva a partir de un diccionario de Firestore
    static func from(data: [String: Any]) -> Reserva? {
        guard let placa = data["placa"] as? String,
              let horaIngreso = data["horaIngreso"] as? String,
              let horaSalida = data["horaSalida"] as? String,
              let fecha = data["fecha"] as? String else {
            return nil
        }
        return Reserva(placa: placa, horaIngreso: horaIngreso, horaSalida: horaSalida, fecha: fecha)
    }
}

