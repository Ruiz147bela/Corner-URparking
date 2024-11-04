//  FirestoreManager.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import FirebaseFirestore
import FirebaseMessaging

class FirestoreManager {
    
    private let db = Firestore.firestore()
    private let reservasCollection = "reservas" // Esta constante debe estar disponible en toda la clase
    private let maxReservas = 30 // Número máximo de reservas permitido por franja horaria
    
    // Función para agregar solo la placa y reservar en Firestore
        func agregarReserva(placa: String, horaIngreso: String, horaSalida: String, fecha: String, completion: @escaping (Error?) -> Void) {
            
            // Llama a esta función para probar si las notificaciones locales funcionan
            enviarNotificacionLocal(titulo: "Prueba de Notificación", mensaje: "Esta es una notificación de prueba.")
 
            // Consulta para verificar las reservas en el mismo rango de tiempo
            let reservasQuery = db.collection(reservasCollection)
                .whereField("fecha", isEqualTo: fecha)
                .whereField("horaIngreso", isLessThanOrEqualTo: horaSalida)
                .whereField("horaSalida", isGreaterThanOrEqualTo: horaIngreso)
            
            reservasQuery.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error al verificar las reservas: \(error.localizedDescription)")
                    completion(error)
                    return
                }
                
                let reservasExistentes = snapshot?.documents.count ?? 0
                
                // Verificar si ya hay más de maxReservas en ese time slot
                if reservasExistentes >= self.maxReservas {
                    print("El parqueadero está lleno para el rango de tiempo solicitado.")
                    let error = NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "El parqueadero ya está lleno para el rango de \(horaIngreso) a \(horaSalida) en la fecha \(fecha). Intente otro horario."])
                    completion(error)
                } else {
                    // Si no está lleno, procede a guardar la reserva
                    let data: [String: Any] = [
                        "placa": placa,
                        "horaIngreso": horaIngreso,
                        "horaSalida": horaSalida,
                        "fecha": fecha
                    ]
                    
                    print("Datos a guardar en Firestore: \(data)")  // Depuración para verificar los datos
                    
                    self.db.collection(self.reservasCollection).addDocument(data: data) { error in
                        if let error = error {
                            print("Error al guardar la reserva en Firestore: \(error.localizedDescription)")
                        } else {
                            print("Reserva guardada exitosamente en Firestore.")
                            // Enviar notificación local después de guardar la reserva
                            self.enviarNotificacionLocal(titulo: "Reserva Confirmada", mensaje: "Tu reserva está confirmada para el \(fecha) desde \(horaIngreso) hasta \(horaSalida).")
                        }
                        completion(error)
                    }
                }
            }
        }
        
        // Función para enviar una notificación local
        func enviarNotificacionLocal(titulo: String, mensaje: String) {
            let content = UNMutableNotificationContent()
            content.title = titulo
            content.body = mensaje
            content.sound = .default

            // Disparar la notificación en 1 segundo para probar
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

            // Crear una solicitud con un identificador único
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            // Agregar la notificación al centro de notificaciones
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error al programar la notificación: \(error.localizedDescription)")
                } else {
                    print("Notificación local programada exitosamente.")
                }
            }
        }

    
    // Obtener todas las reservas y dividirlas en pasadas y futuras
    func obtenerHistorialReservas(completion: @escaping ([Reserva], [Reserva], Error?) -> Void) {
        let fechaActual = Date()
        
        db.collection(reservasCollection)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion([], [], error)
                    return
                }
                
                var reservasFuturas: [Reserva] = []
                var reservasPasadas: [Reserva] = []
                
                snapshot?.documents.forEach { document in
                    let data = document.data()
                    if let reserva = Reserva.from(data: data) {
                        // Convertir la fecha y hora de salida para comparar con la fecha actual
                        if let fechaSalida = self.fechaDesdeString(fecha: reserva.fecha, hora: reserva.horaSalida) {
                            if fechaSalida > fechaActual {
                                reservasFuturas.append(reserva)
                            } else {
                                reservasPasadas.append(reserva)
                            }
                        }
                    }
                }
                
                completion(reservasFuturas, reservasPasadas, nil)
            }
    }
    
    // Método para convertir la fecha y hora en un objeto Date
    private func fechaDesdeString(fecha: String, hora: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.date(from: "\(fecha) \(hora)")
    }
    
    // Modificar reserva (con eliminación de la reserva anterior y creación de una nueva)
    func modificarReserva(idReserva: String, nuevaHoraIngreso: String, nuevaHoraSalida: String, nuevaFecha: String, nuevaPlaca: String, completion: @escaping (Error?) -> Void) {
        print("Intentando modificar la reserva con ID: \(idReserva)")

        // Eliminar la reserva existente
        db.collection(reservasCollection).document(idReserva).delete { error in
            if let error = error {
                print("Error al eliminar la reserva existente: \(error.localizedDescription)")
                completion(error)
                return
            }

            print("Reserva eliminada correctamente.")

            // Crear una nueva reserva con los datos actualizados
            self.agregarReserva(placa: nuevaPlaca, horaIngreso: nuevaHoraIngreso, horaSalida: nuevaHoraSalida, fecha: nuevaFecha, completion: completion)
        }
    }

    // Cancelar reserva
    func cancelarReserva(idReserva: String, completion: @escaping (Error?) -> Void) {
        print("Intentando cancelar la reserva con ID: \(idReserva)")

        // Eliminar la reserva existente
        db.collection(reservasCollection).document(idReserva).delete { error in
            if let error = error {
                print("Error al cancelar la reserva: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Reserva cancelada exitosamente.")
                completion(nil)
            }
        }
    }

    // Obtener reservas en tiempo real
    func obtenerReservasEnTiempoReal(completion: @escaping ([Reserva]) -> Void) {
        db.collection(reservasCollection)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error al obtener las reservas: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var reservas: [Reserva] = []
                snapshot?.documents.forEach { document in
                    let data = document.data()
                    if let reserva = Reserva.from(data: data) {
                        reservas.append(reserva)
                    }
                }
                completion(reservas)
            }
    }

    // Obtener reservas en tiempo real para una fecha específica
    func obtenerReservasEnTiempoReal(fecha: String, completion: @escaping ([Reserva]) -> Void) {
        db.collection(reservasCollection)
            .whereField("fecha", isEqualTo: fecha)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error al obtener las reservas: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var reservas: [Reserva] = []
                snapshot?.documents.forEach { document in
                    let data = document.data()
                    if let reserva = Reserva.from(data: data) {
                        reservas.append(reserva)
                    }
                }
                completion(reservas)
            }
    }
}

