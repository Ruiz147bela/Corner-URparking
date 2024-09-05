//
//  InicioView.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import SwiftUI

struct InicioView: View {
    var body: some View {
        NavigationView { // Añadir NavigationView para habilitar la navegación
            ZStack {
                Color(red: 255/255, green: 249/255, blue: 236/255)
                    .edgesIgnoringSafeArea(.all) // Asegura que el color de fondo cubra toda el área de la pantalla
                
                VStack {
                    Spacer() // Empuja los elementos hacia la parte inferior de la pantalla
                    
                    Image("Logo(1024 x 1024 px)")
                        .resizable()
                        .frame(width: 400, height: 400)
                        .scaledToFit()
                        .padding(.bottom, 40) // Añade espacio debajo de la imagen

                    NavigationLink(destination: ReservarView()) { // Navega a ReservaView
                        Text("Reservar")
                            .padding()
                            .frame(width: 200)
                            .background(Color(red: 0.6, green: 0.008, blue: 0.102))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Spacer() // Empuja los elementos hacia la parte superior de la pantalla
                }
            }
        }
    }
}

struct InicioView_Previews: PreviewProvider {
    static var previews: some View {
        InicioView()
    }
}

