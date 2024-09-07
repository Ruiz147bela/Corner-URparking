//
//  ReservarView.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import SwiftUI
import FirebaseFirestore

// Extensión para permitir ocultar el teclado
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Definición del TimeTextField
struct TimeTextField: View {
    @Binding var text: String
    var range: ClosedRange<Int> // Rango permitido para la entrada (0-23 para horas, 0-59 para minutos)

    var body: some View {
        TextField("", text: $text)
            .frame(width: 60, height: 60)
            .multilineTextAlignment(.center)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(5)
            .font(.system(size: 24))
            .keyboardType(.numberPad)
            .onChange(of: text) { oldValue, newValue in
                // Asegura que el valor sea un número dentro del rango especificado
                if let intValue = Int(newValue), !range.contains(intValue) {
                    text = ""
                } else if newValue.count > 2 {
                    text = String(newValue.prefix(2))
                }
            }
    }
}

struct PlacaTextField: View {
    @Binding var text: String
    var isLetter: Bool

    var body: some View {
        TextField("", text: $text)
            .frame(width: 50, height: 50)
            .multilineTextAlignment(.center)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(5)
            .keyboardType(isLetter ? .default : .numberPad)
            .font(.system(size: 24))
            .onChange(of: text) { oldValue, newValue in
                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }
                if isLetter {
                    if !text.isEmpty && !text.last!.isLetter {
                        text = ""
                    }
                } else {
                    if !text.isEmpty && !text.last!.isNumber {
                        text = ""
                    }
                }
            }
    }
}

struct ReservarView: View {
    private let firestoreManager = FirestoreManager()
    
        @State var placa1 = ""
        @State var placa2 = ""
        @State var placa3 = ""
        @State var placa4 = ""
        @State var placa5 = ""
        @State var placa6 = ""
        
        @State var horaIngreso1 = ""
        @State var horaIngreso2 = ""
        @State var horaSalida1 = ""
        @State var horaSalida2 = ""
        
        @State var showAlert = false
        @State var alertMessage = ""
        
        @State var showConfirmation = false


    var body: some View {
        ZStack {
            Color(red: 255/255, green: 249/255, blue: 236/255)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            
            VStack(spacing: 20) {
                
                Image("Logo(1024 x 1024 px)")
                    .resizable()
                    .frame(width: 180, height: 180)
                    .scaledToFit()
                    .padding(.bottom, 0)
                
                Text("NO. PLACA")
                    .padding()
                    .frame(width: 250)
                    .background(Color(red: 0.6, green: 0.008, blue: 0.102))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                HStack(spacing: 10) {
                    PlacaTextField(text: $placa1, isLetter: true)
                    PlacaTextField(text: $placa2, isLetter: true)
                    PlacaTextField(text: $placa3, isLetter: true)
                    PlacaTextField(text: $placa4, isLetter: false)
                    PlacaTextField(text: $placa5, isLetter: false)
                    PlacaTextField(text: $placa6, isLetter: false)
                }
                
                Text("HORA INGRESO")
                    .padding()
                    .frame(width: 250)
                    .background(Color(red: 0.6, green: 0.008, blue: 0.102))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                HStack(spacing: 10) {
                    TimeTextField(text: $horaIngreso1, range: 0...23)
                    Text(":").font(.system(size: 24))
                    TimeTextField(text: $horaIngreso2, range: 0...59)
                }
                
                Text("HORA SALIDA")
                    .padding()
                    .frame(width: 250)
                    .background(Color(red: 0.6, green: 0.008, blue: 0.102))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                HStack(spacing: 10) {
                    TimeTextField(text: $horaSalida1, range: 0...23)
                    Text(":").font(.system(size: 24))
                    TimeTextField(text: $horaSalida2, range: 0...59)
                }
                
                Spacer()
                
                Button(action: {
                    let placaCompleta = "\(placa1)\(placa2)\(placa3)\(placa4)\(placa5)\(placa6)"
                    
                    // Verificación de que la placa esté completa
                    guard placaCompleta.count == 6 else {
                        alertMessage = "La placa debe tener 6 caracteres."
                        showAlert = true
                        return
                    }
                    
                    if validarHoras() {
                        let horaIngreso = "\(horaIngreso1):\(horaIngreso2)"
                        let horaSalida = "\(horaSalida1):\(horaSalida2)"
                        let fecha = obtenerFechaActual()
                        
                        firestoreManager.agregarReserva(placa: placaCompleta, horaIngreso: horaIngreso, horaSalida: horaSalida, fecha: fecha) { errorMessage in
                            if let errorMessage = errorMessage {
                                print("Error al guardar la reserva: \(errorMessage)")
                                alertMessage = "Hubo un error al guardar la reserva. Inténtalo de nuevo."
                                showAlert = true
                            } else {
                                print("Reserva guardada exitosamente")
                                showConfirmation = true
                            }
                        }
                    } else {
                        alertMessage = "Por favor, asegúrate de que las horas sean correctas."
                        showAlert = true
                    }
                }) {
                    Text("RESERVAR")
                        .padding()
                        .frame(width: 250)
                        .background(Color(red: 0.6, green: 0.008, blue: 0.102))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                .sheet(isPresented: $showConfirmation) {
                    ConfirmacionView()
                }

            }
            .padding()
        }
    }
    
    func validarHoras() -> Bool {
        guard let horaIngreso = Int(horaIngreso1), let minIngreso = Int(horaIngreso2),
              let horaSalida = Int(horaSalida1), let minSalida = Int(horaSalida2) else {
            alertMessage = "Por favor, ingresa una hora válida."
            return false
        }
        
        if horaIngreso > horaSalida || (horaIngreso == horaSalida && minIngreso >= minSalida) {
            alertMessage = "La hora de salida debe ser posterior a la hora de ingreso."
            return false
        }
        
        return true
    }
    
    func obtenerFechaActual() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct ReservarView_Previews: PreviewProvider {
    static var previews: some View {
        ReservarView()
    }
}
