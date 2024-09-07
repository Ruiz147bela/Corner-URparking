//
//  Ur_ParkingUITests.swift
//  Ur ParkingUITests
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import XCTest

final class Ur_ParkingUITests: XCTestCase {

    override func setUpWithError() throws {
        // Configuración inicial antes de que cada prueba se ejecute.
        // Es recomendable detener la ejecución si ocurre una falla.
        continueAfterFailure = false

        // Configura el estado inicial necesario para las pruebas antes de que se ejecuten.
        // Por ejemplo, establecer la orientación del dispositivo.
    }

    override func tearDownWithError() throws {
        // Método que se ejecuta después de cada prueba. Puedes usar esto para limpieza.
    }

    // Prueba básica de la UI, por ejemplo, interactuar con elementos.
    func testExample() throws {
        // Lanza la aplicación.
        let app = XCUIApplication()
        app.launch()

        // Verifica que un botón de "Reservar" exista en la pantalla principal.
        let reservarButton = app.buttons["RESERVAR"]
        XCTAssertTrue(reservarButton.exists, "El botón de reservar debería estar presente en la pantalla principal")

        // Toca el botón de "Reservar" y verifica la navegación.
        reservarButton.tap()

        // Verifica que hemos navegado a la vista de reserva.
        let placaLabel = app.staticTexts["NO. PLACA"]
        XCTAssertTrue(placaLabel.exists, "Deberíamos estar en la vista de inscripción de la placa.")
    }

    // Prueba de rendimiento del lanzamiento de la aplicación.
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // Esta prueba mide cuánto tiempo toma lanzar la aplicación.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    // Prueba de que se puede agregar una reserva.
    func testAddReservation() throws {
        // Lanza la aplicación.
        let app = XCUIApplication()
        app.launch()

        // Toca el botón de "Reservar".
        let reservarButton = app.buttons["RESERVAR"]
        XCTAssertTrue(reservarButton.exists, "El botón de reservar debería estar presente en la pantalla principal")
        reservarButton.tap()

        // Ingresar la placa.
        let placa1Field = app.textFields.element(boundBy: 0)
        let placa2Field = app.textFields.element(boundBy: 1)
        let placa3Field = app.textFields.element(boundBy: 2)
        let placa4Field = app.textFields.element(boundBy: 3)
        let placa5Field = app.textFields.element(boundBy: 4)
        let placa6Field = app.textFields.element(boundBy: 5)

        placa1Field.tap()
        placa1Field.typeText("A")

        placa2Field.tap()
        placa2Field.typeText("B")

        placa3Field.tap()
        placa3Field.typeText("C")

        placa4Field.tap()
        placa4Field.typeText("1")

        placa5Field.tap()
        placa5Field.typeText("2")

        placa6Field.tap()
        placa6Field.typeText("3")

        // Ingresar hora de ingreso y salida.
        let horaIngresoField = app.textFields["horaIngreso"]
        XCTAssertTrue(horaIngresoField.exists, "Campo de hora de ingreso debe existir")
        horaIngresoField.tap()
        horaIngresoField.typeText("10:00")

        let horaSalidaField = app.textFields["horaSalida"]
        XCTAssertTrue(horaSalidaField.exists, "Campo de hora de salida debe existir")
        horaSalidaField.tap()
        horaSalidaField.typeText("12:00")

        // Confirmar reserva
        let confirmarButton = app.buttons["Confirmar"]
        XCTAssertTrue(confirmarButton.exists, "El botón de confirmar debería estar presente")
        confirmarButton.tap()

        // Verifica si aparece un mensaje de confirmación
        let successAlert = app.alerts["Reserva confirmada"]
        XCTAssertTrue(successAlert.exists, "Debería aparecer un mensaje de confirmación de reserva")
    }
}

