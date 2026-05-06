import SwiftUI
import Combine

/// Estado compartido entre los 5 perfiles de la app.
/// Cada acción en un perfil se refleja en los demás en tiempo real.
@MainActor
final class AppDataStore: ObservableObject {

    // MARK: - Datos compartidos

    @Published var puntosAcopio: [PuntoAcopio]
    @Published var solicitudes: [SolicitudRecoleccion]
    @Published var historialDepositos: [DepositoTicket]
    @Published var historialPepenador: [RecoleccionHistorial]
    @Published var recepcionesPendientes: [RecepcionPendiente]
    @Published var centrosAcopio: [CentroAcopio]
    @Published var cupones: [Cupon]

    // Alerta tipo Uber para pepenadores
    @Published var solicitudNuevaParaPepenador: SolicitudRecoleccion?

    // Sesión activa del ciudadano (ticket que acumula escaneos)
    @Published var ticketActual: [TipoResiduo: Double] = [:]

    // MARK: - Init

    init() {
        let mock = MockDataService.shared
        self.puntosAcopio = mock.puntosAcopio + mock.oxxos
        self.solicitudes = mock.solicitudesRecoleccion
        self.historialDepositos = mock.historialDepositos
        self.centrosAcopio = mock.centrosAcopio
        self.cupones = mock.cupones
        self.historialPepenador = Self.historialPepenadorInicial
        self.recepcionesPendientes = Self.recepcionesIniciales
    }

    // MARK: - Usuario activo

    var currentUserId: String {
        AuthManager.shared.usuarioActual?.id.uuidString ?? "anonimo"
    }

    var currentUserName: String {
        AuthManager.shared.usuarioActual?.nombre ?? "Usuario"
    }

    // MARK: - Mapping usuario → punto/centro asignado

    /// Qué punto de acopio opera cada usuario (para Punto de Acopio)
    static let puntoAsignado: [UUID: UUID] = [
        Usuario.idLaura:  UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!, // Ecocentro Coyoacán
        Usuario.idCarmen: UUID(uuidString: "A2000000-0000-0000-0000-000000000002")!, // Punto Verde Roma Norte
    ]

    /// Qué centro de acopio opera cada usuario (para Centro de Acopio)
    static let centroAsignado: [UUID: UUID] = [
        Usuario.idRicardo: UUID(uuidString: "C1000000-0000-0000-0000-000000000001")!, // Centro Sur
        Usuario.idElena:   UUID(uuidString: "C2000000-0000-0000-0000-000000000002")!, // Acopio Oriente
    ]

    /// Qué OXXO opera cada usuario
    static let oxxoAsignado: [UUID: UUID] = [
        Usuario.idOxxoManager:  UUID(uuidString: "B1000000-0000-0000-0000-000000000001")!, // OXXO Roma Norte
        Usuario.idOxxoManager2: UUID(uuidString: "B2000000-0000-0000-0000-000000000002")!, // OXXO Condesa
    ]

    /// Retorna el punto asignado al operador actual
    var miPuntoAcopio: PuntoAcopio? {
        guard let userId = AuthManager.shared.usuarioActual?.id,
              let puntoId = Self.puntoAsignado[userId] else { return puntosAcopio.first }
        return puntosAcopio.first { $0.id == puntoId }
    }

    var miPuntoAcopioIndex: Int {
        guard let userId = AuthManager.shared.usuarioActual?.id,
              let puntoId = Self.puntoAsignado[userId] else { return 0 }
        return puntosAcopio.firstIndex { $0.id == puntoId } ?? 0
    }

    /// Retorna el centro asignado al operador actual
    var miCentroAcopio: CentroAcopio? {
        guard let userId = AuthManager.shared.usuarioActual?.id,
              let centroId = Self.centroAsignado[userId] else { return centrosAcopio.first }
        return centrosAcopio.first { $0.id == centroId }
    }

    var miCentroAcopioIndex: Int {
        guard let userId = AuthManager.shared.usuarioActual?.id,
              let centroId = Self.centroAsignado[userId] else { return 0 }
        return centrosAcopio.firstIndex { $0.id == centroId } ?? 0
    }

    /// Retorna el OXXO asignado al operador actual
    var miOxxo: PuntoAcopio? {
        guard let userId = AuthManager.shared.usuarioActual?.id,
              let oxxoId = Self.oxxoAsignado[userId] else {
            return puntosAcopio.first { $0.esOxxo }
        }
        return puntosAcopio.first { $0.id == oxxoId }
    }

    var miOxxoIndex: Int {
        guard let userId = AuthManager.shared.usuarioActual?.id,
              let oxxoId = Self.oxxoAsignado[userId] else {
            return puntosAcopio.firstIndex { $0.esOxxo } ?? 0
        }
        return puntosAcopio.firstIndex { $0.id == oxxoId } ?? 0
    }

    // MARK: - Datos filtrados por usuario

    var misDepositos: [DepositoTicket] {
        historialDepositos.filter { $0.ciudadanoId == currentUserId }
    }

    var misRecolecciones: [RecoleccionHistorial] {
        historialPepenador.filter { $0.pepenadorId == currentUserId }
    }

    var misSolicitudesReclamadas: [SolicitudRecoleccion] {
        solicitudes.filter { $0.reclamadaPor == currentUserId }
    }

    /// Depósitos recibidos en mi punto de acopio
    var depositosEnMiPunto: [DepositoTicket] {
        guard let punto = miPuntoAcopio else { return [] }
        return historialDepositos.filter { $0.puntoAcopioId == punto.id }
    }

    // MARK: - Métricas ciudadano (filtradas)

    var totalPuntosCiudadano: Int {
        misDepositos.reduce(0) { $0 + $1.puntosOtorgados }
    }

    var totalKgCiudadano: Double {
        misDepositos.flatMap { $0.materiales.values }.reduce(0, +)
    }

    var ticketPuntosEstimados: Int {
        ticketActual.reduce(0) { $0 + Int($1.value * Double($1.key.puntosPorKg)) }
    }

    // MARK: - Acciones Ciudadano

    func agregarAlTicket(tipo: TipoResiduo, kg: Double = 0.5) {
        ticketActual[tipo, default: 0] += kg
    }

    func depositarEnPunto(puntoAcopioId: UUID) {
        guard !ticketActual.isEmpty else { return }

        var ticket = DepositoTicket(
            id: UUID(),
            ciudadanoId: currentUserId,
            puntoAcopioId: puntoAcopioId,
            materiales: ticketActual,
            fotoVerificacion: nil,
            timestamp: Date(),
            puntosOtorgados: 0,
            verificado: true
        )
        ticket.puntosOtorgados = ticket.totalPuntos
        historialDepositos.insert(ticket, at: 0)

        if let idx = puntosAcopio.firstIndex(where: { $0.id == puntoAcopioId }) {
            for (tipo, kg) in ticketActual {
                puntosAcopio[idx].materialDisponible[tipo.rawValue, default: 0] += kg
            }
        }

        ticketActual = [:]
    }

    // MARK: - Acciones Punto de Acopio

    func solicitarRecoleccion(puntoAcopioId: UUID) {
        guard let punto = puntosAcopio.first(where: { $0.id == puntoAcopioId }) else { return }
        let totalKg = punto.materialDisponible.values.reduce(0, +)

        let materiales: [TipoResiduo] = punto.materialDisponible.compactMap { key, _ in
            TipoResiduo.allCases.first { $0.rawValue == key }
        }

        let solicitud = SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: punto,
            kgEstimados: totalKg,
            valorEstimado: calcularValorMaterial(punto.materialDisponible),
            materialesPrincipales: Array(materiales.prefix(3)),
            timestampPublicacion: Date(),
            reclamadaPor: nil,
            estado: .disponible
        )
        solicitudes.insert(solicitud, at: 0)
        solicitudNuevaParaPepenador = solicitud
    }

    // MARK: - Acciones Pepenador

    func reclamarSolicitud(_ id: UUID) {
        if let idx = solicitudes.firstIndex(where: { $0.id == id }) {
            solicitudes[idx].estado = .reclamada
            solicitudes[idx].reclamadaPor = currentUserId
        }
    }

    func marcarEnRuta(_ id: UUID) {
        if let idx = solicitudes.firstIndex(where: { $0.id == id }) {
            solicitudes[idx].estado = .enRuta
        }
    }

    func confirmarEntrega(materiales: [TipoResiduo: Double], centroId: UUID, puntoOrigenNombre: String) {
        let centro = centrosAcopio.first { $0.id == centroId }
        let centroNombre = centro?.nombre ?? "Centro de Acopio"

        let ingresos = materiales.reduce(0.0) { acc, entry in
            let precio = centro?.preciosMaterial[entry.key] ?? entry.key.valorMercado
            return acc + entry.value * precio
        }
        let kgTotal = materiales.values.reduce(0, +)

        let historial = RecoleccionHistorial(
            id: UUID(),
            pepenadorId: currentUserId,
            puntoNombre: puntoOrigenNombre,
            fecha: Date(),
            kgTotales: kgTotal,
            ingresos: ingresos,
            centroDestino: centroNombre
        )
        historialPepenador.insert(historial, at: 0)

        let materialStrings = materiales.map { (tipo: $0.key.rawValue, kg: $0.value) }
        let recepcion = RecepcionPendiente(
            id: UUID(),
            pepenador: currentUserName,
            origen: puntoOrigenNombre,
            materiales: materialStrings,
            timestamp: Date()
        )
        recepcionesPendientes.insert(recepcion, at: 0)

        if let punto = puntosAcopio.first(where: { $0.nombre == puntoOrigenNombre }),
           let idx = puntosAcopio.firstIndex(where: { $0.id == punto.id }) {
            for (tipo, kg) in materiales {
                puntosAcopio[idx].materialDisponible[tipo.rawValue, default: 0] -= kg
                if puntosAcopio[idx].materialDisponible[tipo.rawValue, default: 0] <= 0 {
                    puntosAcopio[idx].materialDisponible.removeValue(forKey: tipo.rawValue)
                }
            }
        }
    }

    // MARK: - Acciones Centro de Acopio

    @Published var recepcionesConfirmadas: Set<UUID> = []

    func confirmarRecepcion(_ id: UUID) {
        recepcionesConfirmadas.insert(id)
    }

    // MARK: - Helpers

    private func calcularValorMaterial(_ materiales: [String: Double]) -> Double {
        materiales.reduce(0.0) { acc, entry in
            let tipo = TipoResiduo.allCases.first { $0.rawValue == entry.key }
            return acc + entry.value * (tipo?.valorMercado ?? 1.0)
        }
    }

    // MARK: - Datos iniciales de ejemplo (con IDs de usuarios demo)

    private static let beto = Usuario.idBeto.uuidString
    private static let rosa = Usuario.idRosa.uuidString

    private static let historialPepenadorInicial: [RecoleccionHistorial] = [
        // Beto: 3 recolecciones
        RecoleccionHistorial(id: UUID(), pepenadorId: beto, puntoNombre: "Ecocentro Coyoacán",    fecha: Date().addingTimeInterval(-86400),   kgTotales: 23.7, ingresos: 267.0, centroDestino: "Centro de Acopio Sur CDMX"),
        RecoleccionHistorial(id: UUID(), pepenadorId: beto, puntoNombre: "Reciclaje Condesa",     fecha: Date().addingTimeInterval(-345600),  kgTotales: 35.0, ingresos: 134.5, centroDestino: "Acopio Oriente"),
        RecoleccionHistorial(id: UUID(), pepenadorId: beto, puntoNombre: "EcoBox Polanco",        fecha: Date().addingTimeInterval(-864000),  kgTotales: 12.8, ingresos: 220.0, centroDestino: "Centro de Acopio Sur CDMX"),
        // Rosa: 2 recolecciones
        RecoleccionHistorial(id: UUID(), pepenadorId: rosa, puntoNombre: "Punto Verde Roma Norte", fecha: Date().addingTimeInterval(-172800),  kgTotales: 43.5, ingresos: 48.0,  centroDestino: "Centro de Acopio Sur CDMX"),
        RecoleccionHistorial(id: UUID(), pepenadorId: rosa, puntoNombre: "Acopio Tlalpan",        fecha: Date().addingTimeInterval(-604800),  kgTotales: 18.2, ingresos: 95.0,  centroDestino: "Acopio Oriente"),
    ]

    private static let recepcionesIniciales: [RecepcionPendiente] = [
        RecepcionPendiente(id: UUID(), pepenador: "Beto Sánchez",  origen: "Ecocentro Coyoacán",     materiales: [("Aluminio", 3.2), ("Plástico PET", 8.5)], timestamp: Date().addingTimeInterval(-1800)),
        RecepcionPendiente(id: UUID(), pepenador: "Rosa García",   origen: "Punto Verde Roma Norte", materiales: [("Vidrio", 43.5), ("Cartón", 12.0)],       timestamp: Date().addingTimeInterval(-3600)),
        RecepcionPendiente(id: UUID(), pepenador: "Beto Sánchez",  origen: "Reciclaje Condesa",      materiales: [("Plástico PET", 18.2), ("Aluminio", 2.1)], timestamp: Date().addingTimeInterval(-5400))
    ]
}
