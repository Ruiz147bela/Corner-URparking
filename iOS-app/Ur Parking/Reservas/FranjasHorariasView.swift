//  FranjasHorariasView.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 7/09/24.
//

import SwiftUI

struct FranjasHorariasView: View {
    @State private var franjas: [FranjaHoraria] = []
    @State private var reservas: [Reserva] = []
    @State private var fechaSeleccionada = obtenerFechaActual()
    
    let firestoreManager = FirestoreManager()
    let maxReservas = 30 // Límite de reservas por franja horaria

    var body: some View {
        VStack(spacing: 20) {
            // Bloque redondeado para el título
            Text("Franjas Horarias Disponibles")
                .font(.title2) // Ajustar tamaño de la fuente
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity) // Asegura que ocupe todo el ancho
                .background(Color(red: 0.6, green: 0.008, blue: 0.102))
                .foregroundColor(.white)
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.top, 20) // Añadir más espacio en la parte superior

            // Lista de franjas horarias
            List(franjas) { franja in
                HStack {
                    Text("\(franja.horaInicio) - \(franja.horaFin)")
                    Spacer()
                    if franja.disponible {
                        Text("Cupos disponibles: \(franja.cuposDisponibles)")
                            .foregroundColor(.green)
                    } else {
                        Text("Ocupado")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 8) // Añadir espacio entre las filas
            }
        }
        .background(Color(red: 255/255, green: 249/255, blue: 236/255).edgesIgnoringSafeArea(.all)) // Color de fondo consistente
        .onAppear {
            // Obtener reservas en tiempo real para la fecha seleccionada
            firestoreManager.obtenerReservasEnTiempoReal(fecha: fechaSeleccionada) { reservas in
                self.reservas = reservas
                self.actualizarFranjasHorarias()
            }
        }
    }
    
    // Método para actualizar las franjas horarias según las reservas
    private func actualizarFranjasHorarias() {
        let horas = [
            ("05:00", "06:00"),
            ("06:00", "07:00"),
            ("07:00", "08:00"),
            ("08:00", "09:00"),
            ("09:00", "10:00"),
            ("10:00", "11:00"),
            ("11:00", "12:00"),
            ("12:00", "13:00"),
            ("13:00", "14:00"),
            ("14:00", "15:00"),
            ("15:00", "16:00"),
            ("16:00", "17:00"),
            ("17:00", "18:00"),
            ("18:00", "19:00"),
            ("19:00", "10:00"),
            ("20:00", "21:00")
        ]
        
        franjas = horas.map { (inicio, fin) in
            // Contar cuántas reservas hay para la franja horaria actual
            let reservasEnFranja = reservas.filter { reserva in
                // Verificar si la reserva está dentro del intervalo de la franja
                return (reserva.horaIngreso <= fin && reserva.horaSalida >= inicio)
            }
            
            // Si el número de reservas en la franja es mayor o igual al máximo permitido (30), se marca como ocupada
            let ocupada = reservasEnFranja.count >= maxReservas
            let cuposDisponibles = maxReservas - reservasEnFranja.count
            
            return FranjaHoraria(horaInicio: inicio, horaFin: fin, disponible: !ocupada, cuposDisponibles: cuposDisponibles)
        }
    }
    
    static func obtenerFechaActual() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct FranjasHorariasView_Previews: PreviewProvider {
    static var previews: some View {
        FranjasHorariasView()
    }
}

