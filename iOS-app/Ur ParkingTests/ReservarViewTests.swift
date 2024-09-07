//
//  ReservarManagerTests.swift
//  Ur ParkingTests
//
//  Created by Isabela Ruiz Bustos on 7/09/24.
//

import XCTest
@testable import Ur_Parking

final class ReservarFirestoreManagerTests: XCTestCase {

    var firestoreManager: FirestoreManager!

    override func setUpWithError() throws {
        // Inicializar el FirestoreManager antes de cada prueba
        firestoreManager = FirestoreManager()
    }

    override func tearDownWithError() throws {
        // Limpiar referencias después de cada prueba
        firestoreManager = nil
    }

    // Prueba para verificar que se puede agregar una reserva cuando el parqueadero no está lleno
    func testAgregarReservaExito() throws {
        // Datos de prueba
        let placa = "ABC123"
        let horaIngreso = "08:00"
        let horaSalida = "10:00"
        let fecha = "2024-09-07"
        
        let exp = expectation(description: "Esperando la creación exitosa de la reserva")
        
        firestoreManager.agregarReserva(placa: placa, horaIngreso: horaIngreso, horaSalida: horaSalida, fecha: fecha) { error in
            if let error = error {
                XCTFail("Error al agregar la reserva: \(error.localizedDescription)")
            } else {
                XCTAssertNil(error, "La reserva debería haberse agregado exitosamente sin errores.")
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 15.0)
    }

    // Prueba para verificar que se muestra error cuando el parqueadero está lleno
    func testAgregarReservaParqueaderoLleno() throws {
        // Datos de prueba que coinciden con un parqueadero lleno (franja horaria con 30 reservas)
        let placa = "XYZ987"
        let horaIngreso = "08:00"
        let horaSalida = "10:00"
        let fecha = "2024-09-07"
        
        let exp = expectation(description: "Esperando error de parqueadero lleno")

        // Aquí puedes simular que ya hay 30 reservas en Firestore para la franja horaria

        firestoreManager.agregarReserva(placa: placa, horaIngreso: horaIngreso, horaSalida: horaSalida, fecha: fecha) { error in
            if let error = error {
                XCTAssertEqual(error.localizedDescription, "El parqueadero está lleno para el rango de tiempo solicitado.", "Debería mostrar un error indicando que el parqueadero está lleno.")
                exp.fulfill()
            } else {
                XCTFail("La reserva no debería haber sido exitosa, ya que el parqueadero está lleno.")
            }
        }
        
        wait(for: [exp], timeout: 15.0)
    }

    // Prueba para verificar que se rechaza una reserva con horas inválidas
    func testAgregarReservaHorasInvalidas() throws {
        // Datos de prueba con hora de ingreso después de la hora de salida
        let placa = "DEF456"
        let horaIngreso = "12:00"
        let horaSalida = "10:00"
        let fecha = "2024-09-07"
        
        let exp = expectation(description: "Esperando error de horas inválidas")
        
        // Aquí puedes agregar lógica adicional para validar las horas antes de intentar guardar la reserva
        
        firestoreManager.agregarReserva(placa: placa, horaIngreso: horaIngreso, horaSalida: horaSalida, fecha: fecha) { error in
            if let error = error {
                XCTAssertEqual(error.localizedDescription, "La hora de ingreso no puede ser posterior a la hora de salida.", "Debe mostrar un error indicando que las horas son inválidas.")
                exp.fulfill()
            } else {
                XCTFail("La reserva no debería haberse agregado con horas inválidas.")
            }
        }
        
        wait(for: [exp], timeout: 15.0)
    }
}

