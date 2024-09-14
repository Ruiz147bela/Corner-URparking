//
//  ModificarReservasView.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 7/09/24.
//

import SwiftUI

struct ModificarReservasView: View {
    @State private var reservasFuturas: [Reserva] = []
    @State private var horaIngreso = ""
    @State private var horaSalida = ""
    @State private var fecha = ""
    @State private var reservaSeleccionada: Reserva? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let firestoreManager = FirestoreManager()

    var body: some View {
        ZStack {
            
            // Fondo de pantalla completo
            Color(red: 255/255, green: 249/255, blue: 236/255).ignoresSafeArea()  // Fondo que cubre toda la pantalla

            VStack {
                // Título en bloque redondeado
                Text("Modificar Reserva")
                    .font(.largeTitle)
                    .padding()
                    .frame(maxWidth: .infinity) // Ocupa todo el ancho
                    .background(Color(red: 0.6, green: 0.008, blue: 0.102)) // Color de fondo del bloque
                    .foregroundColor(.white) // Color del texto
                    .cornerRadius(20) // Esquinas redondeadas
                    .padding(.horizontal) // Espacio a los lados
                
                // Lista de reservas futuras
                List(reservasFuturas) { reserva in
                    HStack {
                        Text("Placa: \(reserva.placa) - \(reserva.fecha) \(reserva.horaIngreso) - \(reserva.horaSalida)")
                        Spacer()
                        Button("Seleccionar") {
                            reservaSeleccionada = reserva
                            horaIngreso = reserva.horaIngreso
                            horaSalida = reserva.horaSalida
                            fecha = reserva.fecha
                        }
                    }
                }
                
                if let reserva = reservaSeleccionada {
                    VStack {
                        TextField("Hora de Ingreso", text: $horaIngreso)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        TextField("Hora de Salida", text: $horaSalida)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        TextField("Fecha", text: $fecha)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button(action: {
                            modificarReserva()
                        }) {
                            Text("Guardar Cambios")
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
    
    // Cargar reservas futuras
    private func cargarReservasFuturas() {
        firestoreManager.obtenerReservasFuturas { reservas, error in
            if let error = error {
                print("Error al cargar reservas futuras: \(error.localizedDescription)")
                return
            }
            self.reservasFuturas = reservas
        }
    }
    
    // Modificar la reserva seleccionada
    private func modificarReserva() {
        guard let reserva = reservaSeleccionada else {
            return
        }

        firestoreManager.modificarReserva(idReserva: reserva.id.uuidString, nuevaHoraIngreso: horaIngreso, nuevaHoraSalida: horaSalida, nuevaFecha: fecha) { error in
            if let error = error {
                alertMessage = "Error al modificar la reserva: \(error.localizedDescription)"
                showAlert = true
            } else {
                print("Reserva modificada exitosamente")
            }
        }
    }
}

struct ModificarReservasView_Previews: PreviewProvider {
    static var previews: some View {
        ModificarReservasView()
    }
}