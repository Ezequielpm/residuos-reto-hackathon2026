import Foundation
import CoreLocation

// MARK: - Tipos de residuo

enum TipoResiduo: String, CaseIterable, Codable {
    case plasticoPET   = "Plástico PET"
    case plasticoHDPE  = "Plástico HDPE"
    case carton        = "Cartón"
    case papel         = "Papel"
    case vidrio        = "Vidrio"
    case aluminio      = "Aluminio"
    case lata          = "Lata"
    case organicoComida  = "Orgánico - comida"
    case organicoPoda    = "Orgánico - poda"
    case noReciclable  = "No reciclable"
    case tetraPak      = "Tetra Pak"

    var puntosPorKg: Int {
        switch self {
        case .aluminio:                    return 50
        case .plasticoPET, .plasticoHDPE:  return 20
        case .lata, .tetraPak:             return 15
        case .organicoComida, .organicoPoda: return 15
        case .carton, .papel:              return 10
        case .vidrio:                      return 5
        case .noReciclable:                return 0
        }
    }

    var valorMercado: Double {
        switch self {
        case .aluminio:                    return 22.0
        case .plasticoPET:                 return 8.5
        case .plasticoHDPE:                return 7.0
        case .carton:                      return 0.70
        case .papel:                       return 0.50
        case .vidrio:                      return 0.30
        case .lata:                        return 18.0
        case .tetraPak:                    return 2.0
        case .organicoComida, .organicoPoda: return 1.0
        case .noReciclable:                return 0.0
        }
    }

    var contenedor: ContenedorNADF {
        switch self {
        case .organicoComida, .organicoPoda:
            return .verde
        case .noReciclable:
            return .naranja
        default:
            return .gris
        }
    }
}

// MARK: - Contenedor NADF-024

enum ContenedorNADF: String, Codable {
    case verde   = "Verde"
    case gris    = "Gris"
    case naranja = "Naranja"

    var diasRecoleccion: [Int] {
        switch self {
        case .verde:           return [3, 5, 7]  // Martes, Jueves, Sábado
        case .gris, .naranja:  return [2, 4, 6, 1] // Lunes, Miércoles, Viernes, Domingo
        }
    }

    var colorHex: String {
        switch self {
        case .verde:   return "#4CAF50"
        case .gris:    return "#607D8B"
        case .naranja: return "#FF5722"
        }
    }
}

// MARK: - Resultado de clasificación

struct ResultadoClasificacion {
    let tipo: TipoResiduo
    let contenedor: ContenedorNADF
    let confianza: Float
    let proximaRecoleccion: String
    let instrucciones: String
    let valorMercado: Double

    var esAmbiguo: Bool { confianza < 0.70 }
}

// MARK: - Punto de Acopio

struct PuntoAcopio: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let direccion: String
    let latitud: Double
    let longitud: Double
    let qrCode: String
    var materialDisponible: [String: Double]
    var capacidadTotal: Double
    var activo: Bool

    var coordenadas: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitud, longitude: longitud)
    }

    var porcentajeCapacidad: Double {
        let total = materialDisponible.values.reduce(0, +)
        return min(total / capacidadTotal, 1.0)
    }
}

// MARK: - Ticket de depósito

struct DepositoTicket: Identifiable {
    let id: UUID
    let ciudadanoId: String
    var puntoAcopioId: UUID?
    var materiales: [TipoResiduo: Double]
    var fotoVerificacion: Data?
    let timestamp: Date
    var puntosOtorgados: Int
    var verificado: Bool

    var totalPuntos: Int {
        materiales.reduce(0) { acc, entry in
            acc + Int(entry.value * Double(entry.key.puntosPorKg))
        }
    }
}

// MARK: - Solicitud de recolección (Pepenador)

struct SolicitudRecoleccion: Identifiable {
    let id: UUID
    let puntoAcopio: PuntoAcopio
    let kgEstimados: Double
    let valorEstimado: Double
    let materialesPrincipales: [TipoResiduo]
    let timestampPublicacion: Date
    var reclamadaPor: String?
    var estado: EstadoRecoleccion
}

enum EstadoRecoleccion: String, Codable {
    case disponible  = "Disponible"
    case reclamada   = "Reclamada"
    case enRuta      = "En ruta"
    case entregada   = "Entregada"
}

// MARK: - Empresa

struct RegistroEmpresa {
    let empresaId: String
    var residuosRegistrados: [RegistroResiduo]
    var kgTotalesMes: Double
    var ahorroFiscalEstimado: Double
}

struct RegistroResiduo: Identifiable {
    let id: UUID
    let tipo: TipoResiduo
    let kg: Double
    let timestamp: Date
    let empleadoId: String
    let destinoCentroAcopio: String?
}

struct Empleado: Identifiable {
    let id: UUID
    let nombre: String
    var escaneosMes: Int
    var kgRegistradosMes: Double
}

// MARK: - Centro de Acopio

struct CentroAcopio: Identifiable {
    let id: UUID
    let nombre: String
    let direccion: String
    let latitud: Double
    let longitud: Double
    var preciosMaterial: [TipoResiduo: Double]
}

// MARK: - Cupón ciudadano

struct Cupon: Identifiable {
    let id: UUID
    let titulo: String
    let descripcion: String
    let puntosRequeridos: Int
    let iconoSF: String
    var canjeado: Bool
}
