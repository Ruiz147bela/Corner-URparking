//
//  Ur_ParkingUITestsLaunchTests.swift
//  Ur ParkingUITests
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import XCTest

final class Ur_ParkingUITestsLaunchTests: XCTestCase {

    // Esta propiedad permite que las pruebas se ejecuten para cada configuración de UI del target.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    // Método de configuración antes de ejecutar las pruebas.
    override func setUpWithError() throws {
        // Continuar después de la falla se desactiva para detener la ejecución si algo sale mal.
        continueAfterFailure = false
    }

    // Prueba para verificar el lanzamiento de la aplicación y tomar una captura de pantalla.
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Inserta aquí los pasos que deseas realizar después de lanzar la app,
        // como iniciar sesión en una cuenta de prueba o navegar a alguna vista.
        
        // Tomar una captura de pantalla después del lanzamiento
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

