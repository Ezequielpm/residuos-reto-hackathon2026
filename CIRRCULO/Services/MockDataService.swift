import Foundation

// Datos mockeados realistas para el hackathon
final class MockDataService {

    static let shared = MockDataService()
    private init() {}

    // MARK: - Puntos de Acopio (5 en CDMX reales)

    lazy var puntosAcopio: [PuntoAcopio] = [
        PuntoAcopio(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
            nombre: "Ecocentro Coyoacán",
            direccion: "Av. Universidad 1855, Coyoacán, CDMX",
            latitud: 19.3467,
            longitud: -99.1605,
            qrCode: "CIRRCULO-PUNTO-A1000000-0000-0000-0000-000000000001",
            materialDisponible: ["Cartón": 12.0, "PET": 8.5, "Aluminio": 3.2],
            capacidadTotal: 100.0,
            activo: true
        ),
        PuntoAcopio(
            id: UUID(uuidString: "A2000000-0000-0000-0000-000000000002")!,
            nombre: "Punto Verde Roma Norte",
            direccion: "Orizaba 101, Roma Norte, CDMX",
            latitud: 19.4184,
            longitud: -99.1631,
            qrCode: "CIRRCULO-PUNTO-A2000000-0000-0000-0000-000000000002",
            materialDisponible: ["Vidrio": 25.0, "PET": 18.0],
            capacidadTotal: 80.0,
            activo: true
        ),
        PuntoAcopio(
            id: UUID(uuidString: "A3000000-0000-0000-0000-000000000003")!,
            nombre: "Reciclaje Condesa",
            direccion: "Tamaulipas 66, Condesa, CDMX",
            latitud: 19.4101,
            longitud: -99.1740,
            qrCode: "CIRRCULO-PUNTO-A3000000-0000-0000-0000-000000000003",
            materialDisponible: ["Aluminio": 5.0, "Cartón": 30.0],
            capacidadTotal: 60.0,
            activo: true
        ),
        PuntoAcopio(
            id: UUID(uuidString: "A4000000-0000-0000-0000-000000000004")!,
            nombre: "Acopio Tlalpan",
            direccion: "Insurgentes Sur 4111, Tlalpan, CDMX",
            latitud: 19.2906,
            longitud: -99.1626,
            qrCode: "CIRRCULO-PUNTO-A4000000-0000-0000-0000-000000000004",
            materialDisponible: ["Orgánico - comida": 40.0],
            capacidadTotal: 120.0,
            activo: true
        ),
        PuntoAcopio(
            id: UUID(uuidString: "A5000000-0000-0000-0000-000000000005")!,
            nombre: "EcoBox Polanco",
            direccion: "Av. Presidente Masaryk 360, Polanco, CDMX",
            latitud: 19.4322,
            longitud: -99.1955,
            qrCode: "CIRRCULO-PUNTO-A5000000-0000-0000-0000-000000000005",
            materialDisponible: ["PET": 5.0, "Aluminio": 1.5],
            capacidadTotal: 50.0,
            activo: true
        )
    ]

    // MARK: - Solicitudes de Recolección (Pepenador)

    lazy var solicitudesRecoleccion: [SolicitudRecoleccion] = [
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[0],
            kgEstimados: 23.7,
            valorEstimado: 267.0,
            materialesPrincipales: [.aluminio, .plasticoPET],
            timestampPublicacion: Date().addingTimeInterval(-3600),
            reclamadaPor: nil,
            estado: .disponible
        ),
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[1],
            kgEstimados: 43.5,
            valorEstimado: 48.0,
            materialesPrincipales: [.vidrio, .plasticoPET],
            timestampPublicacion: Date().addingTimeInterval(-7200),
            reclamadaPor: nil,
            estado: .disponible
        ),
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[2],
            kgEstimados: 35.0,
            valorEstimado: 134.5,
            materialesPrincipales: [.carton, .aluminio],
            timestampPublicacion: Date().addingTimeInterval(-1800),
            reclamadaPor: nil,
            estado: .disponible
        )
    ]

    // MARK: - Historial Ciudadano (últimos 30 días)

    lazy var historialDepositos: [DepositoTicket] = {
        let puntos = puntosAcopio
        return [
            makeTicket(dias: -1,  punto: puntos[0], materiales: [.plasticoPET: 0.5, .carton: 1.2], verificado: true),
            makeTicket(dias: -3,  punto: puntos[1], materiales: [.vidrio: 2.0],                    verificado: true),
            makeTicket(dias: -5,  punto: puntos[0], materiales: [.aluminio: 0.3, .plasticoPET: 0.8], verificado: true),
            makeTicket(dias: -8,  punto: puntos[2], materiales: [.carton: 3.5],                    verificado: true),
            makeTicket(dias: -12, punto: puntos[1], materiales: [.plasticoPET: 1.0, .tetraPak: 0.4], verificado: true),
            makeTicket(dias: -15, punto: puntos[3], materiales: [.organicoComida: 2.0],            verificado: true),
            makeTicket(dias: -20, punto: puntos[0], materiales: [.aluminio: 0.6],                  verificado: true),
            makeTicket(dias: -25, punto: puntos[4], materiales: [.carton: 2.0, .papel: 0.8],       verificado: true)
        ]
    }()

    // MARK: - Dashboard Empresa

    lazy var registroEmpresa: RegistroEmpresa = {
        let registros = generarRegistrosEmpresa()
        let kgTotal = registros.reduce(0) { $0 + $1.kg }
        let ahorro = calcularAhorroFiscal(kgTotal: kgTotal)
        return RegistroEmpresa(
            empresaId: "empresa-demo-01",
            residuosRegistrados: registros,
            kgTotalesMes: kgTotal,
            ahorroFiscalEstimado: ahorro
        )
    }()

    lazy var empleados: [Empleado] = [
        Empleado(id: UUID(), nombre: "Ana García",    escaneosMes: 24, kgRegistradosMes: 45.3),
        Empleado(id: UUID(), nombre: "Luis Ramírez",  escaneosMes: 18, kgRegistradosMes: 32.1),
        Empleado(id: UUID(), nombre: "María Torres",  escaneosMes: 31, kgRegistradosMes: 58.7),
        Empleado(id: UUID(), nombre: "Carlos López",  escaneosMes: 12, kgRegistradosMes: 19.5)
    ]

    lazy var centrosAcopio: [CentroAcopio] = [
        CentroAcopio(
            id: UUID(),
            nombre: "Centro de Acopio Sur CDMX",
            direccion: "Calzada de Tlalpan 2800, CDMX",
            latitud: 19.3200,
            longitud: -99.1350,
            preciosMaterial: [
                .aluminio: 22.0,
                .plasticoPET: 8.5,
                .plasticoHDPE: 7.0,
                .carton: 0.70,
                .papel: 0.50,
                .vidrio: 0.30,
                .lata: 18.0
            ]
        ),
        CentroAcopio(
            id: UUID(),
            nombre: "Acopio Oriente",
            direccion: "Av. Texcoco 800, Iztapalapa, CDMX",
            latitud: 19.3640,
            longitud: -99.0520,
            preciosMaterial: [
                .aluminio: 21.0,
                .plasticoPET: 8.0,
                .carton: 0.65,
                .vidrio: 0.25
            ]
        )
    ]

    lazy var cupones: [Cupon] = [
        Cupon(id: UUID(), titulo: "10% en Farmacia Guadalajara",
              descripcion: "Descuento en toda la tienda", puntosRequeridos: 500,
              iconoSF: "cross.case.fill", canjeado: false),
        Cupon(id: UUID(), titulo: "Café gratis",
              descripcion: "En cualquier sucursal participante", puntosRequeridos: 200,
              iconoSF: "cup.and.heat.waves.fill", canjeado: false),
        Cupon(id: UUID(), titulo: "Transporte gratis (1 viaje)",
              descripcion: "Válido en Cabify o Beat", puntosRequeridos: 800,
              iconoSF: "car.fill", canjeado: false),
        Cupon(id: UUID(), titulo: "$20 MXN en OXXO",
              descripcion: "Código de descuento en caja", puntosRequeridos: 2000,
              iconoSF: "storefront.fill", canjeado: false)
    ]

    // MARK: - Helpers privados

    private func makeTicket(dias: Int, punto: PuntoAcopio, materiales: [TipoResiduo: Double], verificado: Bool) -> DepositoTicket {
        var ticket = DepositoTicket(
            id: UUID(),
            ciudadanoId: "ciudadano-demo-01",
            puntoAcopioId: punto.id,
            materiales: materiales,
            fotoVerificacion: nil,
            timestamp: Calendar.current.date(byAdding: .day, value: dias, to: Date())!,
            puntosOtorgados: 0,
            verificado: verificado
        )
        ticket.puntosOtorgados = ticket.totalPuntos
        return ticket
    }

    private func generarRegistrosEmpresa() -> [RegistroResiduo] {
        let tipos: [TipoResiduo] = [.carton, .plasticoPET, .aluminio, .vidrio, .organicoComida, .noReciclable]
        var registros: [RegistroResiduo] = []
        let empleadoIds = ["emp-001", "emp-002", "emp-003", "emp-004"]
        for i in 0..<28 {
            let tipo = tipos[i % tipos.count]
            let kg = Double.random(in: 2.0...15.0)
            let fecha = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            registros.append(RegistroResiduo(
                id: UUID(),
                tipo: tipo,
                kg: kg,
                timestamp: fecha,
                empleadoId: empleadoIds[i % empleadoIds.count],
                destinoCentroAcopio: "Centro de Acopio Sur CDMX"
            ))
        }
        return registros
    }

    private func calcularAhorroFiscal(kgTotal: Double) -> Double {
        // Referencia: reducción de impuesto sobre nómina NADF-024
        let porcentaje: Double = kgTotal > 200 ? 0.40 : kgTotal > 100 ? 0.30 : 0.20
        let nominaMensualEjemplo = 150_000.0
        return nominaMensualEjemplo * porcentaje
    }
}
