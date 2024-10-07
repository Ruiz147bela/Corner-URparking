//  CancelarReservasView.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 7/09/24.
//

import SwiftUI

struct CancelarReservasView: View {
    @State private var reservasFuturas: [Reserva] = []
    @State private var reservaSeleccionada: Reserva? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""  // Título para mostrar en la alerta
    
    let firestoreManager = FirestoreManager()

    var body: some View {
        ZStack {
            
            // Fondo de pantalla completo
            Color(red: 255/255, green: 249/255, blue: 236/255).ignoresSafeArea()  // Fondo que cubre toda la pantalla

            VStack {
                // Título en bloque redondeado
                Text("Cancelar Reserva")
                    .font(.largeTitle)
                    .padding()
                    .frame(maxWidth: .infinity) // Ocupa todo el ancho
                    .background(Color(red: 0.6, green: 0.008, blue: 0.102)) // Color de fondo del bloque
                    .foregroundColor(.white) // Color del texto
                    .cornerRadius(20) // Esquinas redondeadas
                    .padding(.horizontal) // Espacio a los lados
                
                // Lista de reservas futuras activas
                List(reservasFuturas) { reserva in
                    HStack {
                        Text("Placa: \(reserva.placa) - \(reserva.fecha) \(reserva.horaIngreso) - \(reserva.horaSalida)")
                        Spacer()
                        Button("Seleccionar") {
                            reservaSeleccionada = reserva
                        }
                    }
                }
                
                if let reserva = reservaSeleccionada {
                    VStack {
                        Text("Reserva seleccionada:")
                        Text("Placa: \(reserva.placa) - \(reserva.fecha) \(reserva.horaIngreso) - \(reserva.horaSalida)")
                            .padding()
                        
                        Button(action: {
                            cancelarReserva()
                        }) {
                            Text("Cancelar Reserva")
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            cargarReservasFuturas()
        }
    }
    
    // Cargar reservas futuras activas
    private func cargarReservasFuturas() {
        let fechaActual = Date()
        
        firestoreManager.obtenerReservasEnTiempoReal { reservas in
            // Filtrar solo las reservas activas (que no han terminado)
            self.reservasFuturas = reservas.filter { reserva in
                if let fechaHoraSalida = self.fechaDesdeString(fecha: reserva.fecha, hora: reserva.horaSalida) {
                    return fechaHoraSalida > fechaActual // Mostrar solo reservas activas
                }
                return false
            }
        }
    }
    
    // Método para convertir la fecha y hora en un objeto Date
    private func fechaDesdeString(fecha: String, hora: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.date(from: "\(fecha) \(hora)")
    }

    
    // Cancelar la reserva seleccionada
    private func cancelarReserva() {
        guard let reserva = reservaSeleccionada else {
            return
        }

        firestoreManager.cancelarReserva(idReserva: reserva.id.uuidString) { error in
            if let error = error {
                alertTitle = "Error"
                alertMessage = "Error al cancelar la reserva: \(error.localizedDescription)"
            } else {
                alertTitle = "Cancelación Exitosa"
                alertMessage = "La reserva ha sido cancelada exitosamente."
                
                // Actualizar la lista de reservas después de la cancelación
                cargarReservasFuturas()
            }
            showAlert = true
        }
    }


}

struct CancelarReservasView_Previews: PreviewProvider {
    static var previews: some View {
        CancelarReservasView()
    }
}

