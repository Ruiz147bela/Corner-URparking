//
//  ConfirmacionView.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import SwiftUI

struct ConfirmacionView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Reserva Confirmada")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.6, green: 0.008, blue: 0.102))
            
            Text("Tu reserva ha sido confirmada exitosamente.")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Button("OK") {
                presentationMode.wrappedValue.dismiss() // Cierra la vista cuando se presiona OK
            }
            .padding()
            .frame(width: 150)
            .background(Color(red: 0.6, green: 0.008, blue: 0.102))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

struct ConfirmacionView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmacionView()
    }
}

