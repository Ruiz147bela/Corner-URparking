//
//  HistorialReservasView.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 7/09/24.
//

import SwiftUI

struct HistorialReservasView: View {
    @State private var reservasFuturas: [Reserva] = []
    @State private var reservasPasadas: [Reserva] = []
    @State private var errorMessage: String?
    let firestoreManager = FirestoreManager()
    
    var body: some View {
        ZStack {
            // Fondo de pantalla completo
            Color(red: 255/255, green: 249/255, blue: 236/255).ignoresSafeArea()  // Fondo que cubre toda la pantalla
            
            VStack(spacing: 20) {  // Espacio entre las secciones
                // Bloque para Próximas Reservas
                VStack {
                    Text("Reservas")
                        .font(.headline)
                        .foregroundColor(Color(red: 255/255, green: 249/255, blue: 236/255)) // Color de texto
                    List(reservasFuturas) { reserva in
                        Text("Placa: \(reserva.placa) - \(reserva.fecha) \(reserva.horaIngreso)-\(reserva.horaSalida)")
                    }
                    .listStyle(PlainListStyle())  // Estilo de la lista
                }
                .padding()
                .background(Color(red: 0.6, green: 0.008, blue: 0.102))  // Color específico para el bloque
                .cornerRadius(20)  // Esquinas redondeadas
                
                // Bloque para Reservas Pasadas
                VStack {
                    Text("Reservas Pasadas")
                        .font(.headline)
                        .foregroundColor(Color(red: 255/255, green: 249/255, blue: 236/255)) // Color de texto
                    List(reservasPasadas) { reserva in
                        Text("Placa: \(reserva.placa) - \(reserva.fecha) \(reserva.horaIngreso)-\(reserva.horaSalida)")
                    }
                    .listStyle(PlainListStyle())  // Estilo de la lista
                }
                .padding()
                .background(Color(red: 0.6, green: 0.008, blue: 0.102))  // Color específico para el bloque
                .cornerRadius(20)  // Esquinas redondeadas
            }
            .padding()  // Espacio alrededor de las secciones para que no toquen los bordes
        }
        .onAppear {
            cargarReservas()
        }
    }
    
    // Método para cargar reservas
    private func cargarReservas() {
        firestoreManager.obtenerHistorialReservas { (futuras, pasadas, error) in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.reservasFuturas = futuras
                self.reservasPasadas = pasadas
            }
        }
}


struct HistorialReservasView_Previews: PreviewProvider {
    static var previews: some View {
        HistorialReservasView()
    }
}

