//
//  FranjaHoraria.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 7/09/24.
//

import Foundation

struct FranjaHoraria: Identifiable {
    var id = UUID()
    var horaInicio: String
    var horaFin: String
    var disponible: Bool
    var cuposDisponibles: Int  // Nueva propiedad para almacenar los cupos disponibles
}

