//
//  FirestoreManager.swift
//  Ur Parking
//
//  Created by Isabela Ruiz Bustos on 2/09/24.
//

import FirebaseFirestore

class FirestoreManager {
    
    private let db = Firestore.firestore()
    private let reservasCollection = "reservas" // Esta constante debe estar disponible en toda la clase
    private let maxReservas = 30 // Número máximo de reservas permitido por franja horaria
    
    // Función para agregar solo la placa y reservar en Firestore
    func agregarReserva(placa: String, horaIngreso: String, horaSalida: String, fecha: String, completion: @escaping (Error?) -> Void) {
        
        // Consulta para verificar las reservas en el mismo rango de tiempo
        let reservasQuery = db.collection(reservasCollection) // No se necesita usar self aquí
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
                    }
                    completion(error)
                }
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
    
    // Modificar una reserva si aún no ha comenzado
    func modificarReserva(idReserva: String, nuevaHoraIngreso: String, nuevaHoraSalida: String, nuevaFecha: String, completion: @escaping (Error?) -> Void) {
        let fechaActual = Date()
        
        // Consultar la reserva actual por su ID
        db.collection(reservasCollection).document(idReserva).getDocument { (document, error) in
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = document?.data(),
                  let horaIngresoActual = data["horaIngreso"] as? String,
                  let fechaActualReserva = data["fecha"] as? String else {
                completion(NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Datos de la reserva no válidos"]))
                return
            }
            
            // Convertir la fecha y hora de la reserva a un objeto Date
            if let fechaHoraIngreso = self.fechaDesdeString(fecha: fechaActualReserva, hora: horaIngresoActual), fechaHoraIngreso > fechaActual {
                
                // Modificar la reserva
                self.db.collection(self.reservasCollection).document(idReserva).updateData([
                    "horaIngreso": nuevaHoraIngreso,
                    "horaSalida": nuevaHoraSalida,
                    "fecha": nuevaFecha
                ]) { error in
                    completion(error)
                }
            } else {
                // No se puede modificar porque el tiempo ya ha pasado o está en curso
                completion(NSError(domain: "", code: 2, userInfo: [NSLocalizedDescriptionKey: "No puedes modificar la reserva porque ya ha comenzado o está por comenzar."]))
            }
        }
    }
    
    // Cancelar una reserva si aún no ha comenzado
    func cancelarReserva(idReserva: String, completion: @escaping (Error?) -> Void) {
        let fechaActual = Date()
        
        // Consultar la reserva actual por su ID
        db.collection(reservasCollection).document(idReserva).getDocument { (document, error) in
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = document?.data(),
                  let horaIngresoActual = data["horaIngreso"] as? String,
                  let fechaActualReserva = data["fecha"] as? String else {
                completion(NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Datos de la reserva no válidos"]))
                return
            }
            
            // Convertir la fecha y hora de la reserva a un objeto Date
            if let fechaHoraIngreso = self.fechaDesdeString(fecha: fechaActualReserva, hora: horaIngresoActual), fechaHoraIngreso > fechaActual {
                
                // Eliminar la reserva
                self.db.collection(self.reservasCollection).document(idReserva).delete() { error in
                    completion(error)
                }
            } else {
                // No se puede cancelar porque el tiempo ya ha pasado o está en curso
                completion(NSError(domain: "", code: 2, userInfo: [NSLocalizedDescriptionKey: "No puedes cancelar la reserva porque ya ha comenzado o está por comenzar."]))
            }
        }
        
        
    }
    
    // Obtener todas las reservas futuras
        func obtenerReservasFuturas(completion: @escaping ([Reserva], Error?) -> Void) {
            let fechaActual = Date()
            
            db.collection(reservasCollection)
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        completion([], error)
                        return
                    }
                    
                    var reservasFuturas: [Reserva] = []
                    
                    snapshot?.documents.forEach { document in
                        let data = document.data()
                        if let reserva = Reserva.from(data: data),
                           let fechaIngreso = self.fechaDesdeString(fecha: reserva.fecha, hora: reserva.horaIngreso),
                           fechaIngreso > fechaActual {
                            reservasFuturas.append(reserva)
                        }
                    }
                    
                    completion(reservasFuturas, nil)
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
