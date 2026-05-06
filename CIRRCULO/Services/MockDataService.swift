import Foundation

final class MockDataService {

    static let shared = MockDataService()
    private init() {}

    // MARK: - Puntos de Acopio (8 en CDMX reales)

    lazy var puntosAcopio: [PuntoAcopio] = [
        PuntoAcopio(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
            nombre: "Ecocentro Coyoacán",
            direccion: "Av. Universidad 1855, Coyoacán, CDMX",
            latitud: 19.3467,
            longitud: -99.1605,
            qrCode: "NEXIA-PUNTO-A1000000-0000-0000-0000-000000000001",
            materialDisponible: ["Cartón": 12.0, "Plástico PET": 8.5, "Aluminio": 3.2],
            capacidadTotal: 100.0,
            activo: true
        ),
        PuntoAcopio(
            id: UUID(uuidString: "A2000000-0000-0000-0000-000000000002")!,
            nombre: "Punto Verde Roma Norte",
            direccion: "Orizaba 101, Roma Norte, CDMX",
            latitud: 19.4184,
            longitud: -99.1631,
            qrCode: "NEXIA-PUNTO-A2000000-0000-0000-0000-000000000002",
            materialDisponible: ["Vidrio": 25.0, "Plástico PET": 18.0],
            capacidadTotal: 80.0,
            activo: true
        ),
        PuntoAcopio(
            id: UUID(uuidString: "A3000000-0000-0000-0000-000000000003")!,
            nombre: "Reciclaje Condesa",
            direccion: "Tamaulipas 66, Condesa, CDMX",
            latitud: 19.4101,
            longitud: -99.1740,
            qrCode: "NEXIA-PUNTO-A3000000-0000-0000-0000-000000000003",
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
            qrCode: "NEXIA-PUNTO-A4000000-0000-0000-0000-000000000004",
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
            qrCode: "NEXIA-PUNTO-A5000000-0000-0000-0000-000000000005",
            materialDisponible: ["Plástico PET": 5.0, "Aluminio": 1.5],
            capacidadTotal: 50.0,
            activo: true
        ),
        PuntoAcopio(
            id: UUID(uuidString: "A6000000-0000-0000-0000-000000000006")!,
            nombre: "Reciclaje Doctores",
            direccion: "Dr. Río de la Loza 45, Doctores, CDMX",
            latitud: 19.4205,
            longitud: -99.1460,
            qrCode: "NEXIA-PUNTO-A6000000-0000-0000-0000-000000000006",
            materialDisponible: ["Cartón": 42.0, "Papel": 18.0],
            capacidadTotal: 90.0,
            activo: true
        ),
        PuntoAcopio(
            id: UUID(uuidString: "A7000000-0000-0000-0000-000000000007")!,
            nombre: "Punto Verde Del Valle",
            direccion: "Insurgentes Sur 638, Del Valle, CDMX",
            latitud: 19.3891,
            longitud: -99.1718,
            qrCode: "NEXIA-PUNTO-A7000000-0000-0000-0000-000000000007",
            materialDisponible: ["Aluminio": 9.5, "Plástico PET": 14.0],
            capacidadTotal: 70.0,
            activo: true
        ),
        PuntoAcopio(
            id: UUID(uuidString: "A8000000-0000-0000-0000-000000000008")!,
            nombre: "EcoPunto Xochimilco",
            direccion: "Av. División del Norte 2994, Xochimilco, CDMX",
            latitud: 19.2965,
            longitud: -99.1040,
            qrCode: "NEXIA-PUNTO-A8000000-0000-0000-0000-000000000008",
            materialDisponible: ["Orgánico - comida": 65.0],
            capacidadTotal: 150.0,
            activo: true
        )
    ]

    // MARK: - Solicitudes de Recolección

    lazy var solicitudesRecoleccion: [SolicitudRecoleccion] = [
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[0],
            kgEstimados: 23.7,
            valorEstimado: 265.0,
            materialesPrincipales: [.aluminio, .plasticoPET],
            timestampPublicacion: Date().addingTimeInterval(-3600),
            reclamadaPor: nil,
            estado: .disponible
        ),
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[1],
            kgEstimados: 43.5,
            valorEstimado: 191.0,
            materialesPrincipales: [.vidrio, .plasticoPET],
            timestampPublicacion: Date().addingTimeInterval(-7200),
            reclamadaPor: nil,
            estado: .disponible
        ),
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[2],
            kgEstimados: 35.0,
            valorEstimado: 397.0,
            materialesPrincipales: [.carton, .aluminio],
            timestampPublicacion: Date().addingTimeInterval(-1800),
            reclamadaPor: nil,
            estado: .disponible
        ),
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[4],
            kgEstimados: 8.5,
            valorEstimado: 187.0,
            materialesPrincipales: [.aluminio],
            timestampPublicacion: Date().addingTimeInterval(-900),
            reclamadaPor: nil,
            estado: .disponible
        ),
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[6],
            kgEstimados: 19.2,
            valorEstimado: 149.0,
            materialesPrincipales: [.plasticoPET, .plasticoHDPE],
            timestampPublicacion: Date().addingTimeInterval(-5400),
            reclamadaPor: nil,
            estado: .disponible
        ),
        // Reclamada por Beto
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[5],
            kgEstimados: 60.0,
            valorEstimado: 42.0,
            materialesPrincipales: [.carton, .papel],
            timestampPublicacion: Date().addingTimeInterval(-10800),
            reclamadaPor: Usuario.idBeto.uuidString,
            estado: .reclamada
        ),
        // Reclamada por Rosa
        SolicitudRecoleccion(
            id: UUID(),
            puntoAcopio: puntosAcopio[3],
            kgEstimados: 40.0,
            valorEstimado: 55.0,
            materialesPrincipales: [.organicoComida],
            timestampPublicacion: Date().addingTimeInterval(-14400),
            reclamadaPor: Usuario.idRosa.uuidString,
            estado: .reclamada
        )
    ]

    // MARK: - Historial Depósitos (distribuidos entre María y Jorge)

    lazy var historialDepositos: [DepositoTicket] = {
        let puntos = puntosAcopio
        let maria = Usuario.idMaria.uuidString
        let jorge = Usuario.idJorge.uuidString
        return [
            // María: 7 depósitos (racha de 7 días)
            makeTicket(dias: -1,  punto: puntos[0], materiales: [.plasticoPET: 0.5, .carton: 1.2],  ciudadanoId: maria),
            makeTicket(dias: -2,  punto: puntos[1], materiales: [.aluminio: 0.2],                    ciudadanoId: maria),
            makeTicket(dias: -3,  punto: puntos[1], materiales: [.vidrio: 2.0],                      ciudadanoId: maria),
            makeTicket(dias: -4,  punto: puntos[2], materiales: [.carton: 1.5, .papel: 0.5],         ciudadanoId: maria),
            makeTicket(dias: -5,  punto: puntos[0], materiales: [.aluminio: 0.3, .plasticoPET: 0.8], ciudadanoId: maria),
            makeTicket(dias: -6,  punto: puntos[3], materiales: [.organicoComida: 1.5],              ciudadanoId: maria),
            makeTicket(dias: -7,  punto: puntos[4], materiales: [.plasticoPET: 0.6, .tetraPak: 0.3], ciudadanoId: maria),
            // Jorge: 4 depósitos
            makeTicket(dias: -1,  punto: puntos[2], materiales: [.carton: 2.0, .papel: 0.8],         ciudadanoId: jorge),
            makeTicket(dias: -3,  punto: puntos[0], materiales: [.aluminio: 0.6],                    ciudadanoId: jorge),
            makeTicket(dias: -8,  punto: puntos[4], materiales: [.plasticoPET: 1.0, .tetraPak: 0.4], ciudadanoId: jorge),
            makeTicket(dias: -15, punto: puntos[3], materiales: [.organicoComida: 2.0],              ciudadanoId: jorge),
        ]
    }()

    // MARK: - Dashboard Empresa (EcoTech)

    lazy var registroEmpresa: RegistroEmpresa = {
        let registros = generarRegistrosEmpresa()
        let kgTotal = registros.reduce(0) { $0 + $1.kg }
        let ahorro = calcularAhorroFiscal(kgTotal: kgTotal)
        return RegistroEmpresa(
            empresaId: Usuario.idEcoTech.uuidString,
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
            id: UUID(uuidString: "C1000000-0000-0000-0000-000000000001")!,
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
            id: UUID(uuidString: "C2000000-0000-0000-0000-000000000002")!,
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

    // MARK: - Cupones

    lazy var cupones: [Cupon] = [
        // Accesibles (pocos puntos)
        Cupon(id: UUID(), titulo: "Café gratis",
              descripcion: "Un café americano o cappuccino en cualquier OXXO.",
              puntosRequeridos: 150,
              iconoSF: "cup.and.heat.waves.fill", canjeado: false,
              marca: "OXXO", colorHex: "#D50000", valorTexto: "Gratis",
              categoria: .producto),
        Cupon(id: UUID(), titulo: "10% en despensa",
              descripcion: "Descuento en tu próxima compra de despensa.",
              puntosRequeridos: 300,
              iconoSF: "cart.fill", canjeado: false,
              marca: "Bodega Aurrera", colorHex: "#FFD600", valorTexto: "10%",
              categoria: .descuento),
        Cupon(id: UUID(), titulo: "$30 de saldo",
              descripcion: "Recarga de saldo para cualquier compañía.",
              puntosRequeridos: 500,
              iconoSF: "iphone.gen3", canjeado: false,
              marca: "OXXO", colorHex: "#D50000", valorTexto: "$30",
              categoria: .producto),
        // Intermedios
        Cupon(id: UUID(), titulo: "15% en línea",
              descripcion: "Descuento en tu siguiente pedido online.",
              puntosRequeridos: 700,
              iconoSF: "bag.fill", canjeado: false,
              marca: "Walmart", colorHex: "#0071CE", valorTexto: "15%",
              categoria: .descuento),
        Cupon(id: UUID(), titulo: "Planta un árbol",
              descripcion: "Donamos en tu nombre a ReForesta México.",
              puntosRequeridos: 800,
              iconoSF: "tree.fill", canjeado: false,
              marca: "ReForesta MX", colorHex: "#2E7D32", valorTexto: "1 árbol",
              categoria: .donacion),
        Cupon(id: UUID(), titulo: "Viaje gratis",
              descripcion: "Un viaje en tu próximo trayecto en CDMX.",
              puntosRequeridos: 1000,
              iconoSF: "car.fill", canjeado: false,
              marca: "DiDi", colorHex: "#FF6F00", valorTexto: "Gratis",
              categoria: .experiencia),
        // Premium
        Cupon(id: UUID(), titulo: "Apoya a un pepenador",
              descripcion: "Dona el valor de tus puntos al recolector de tu zona.",
              puntosRequeridos: 1200,
              iconoSF: "hands.and.sparkles.fill", canjeado: false,
              marca: "Nexia", colorHex: "#1B5E20", valorTexto: "Donación",
              categoria: .donacion),
        Cupon(id: UUID(), titulo: "$100 en monedero",
              descripcion: "Saldo en monedero electrónico para despensa.",
              puntosRequeridos: 2000,
              iconoSF: "creditcard.fill", canjeado: false,
              marca: "Walmart", colorHex: "#0071CE", valorTexto: "$100",
              categoria: .producto),
        Cupon(id: UUID(), titulo: "$50 en efectivo",
              descripcion: "Retira en cualquier OXXO con tu código QR.",
              puntosRequeridos: 2500,
              iconoSF: "banknote.fill", canjeado: false,
              marca: "OXXO", colorHex: "#D50000", valorTexto: "$50",
              categoria: .producto)
    ]

    // MARK: - Helpers privados

    private func makeTicket(dias: Int, punto: PuntoAcopio, materiales: [TipoResiduo: Double], ciudadanoId: String) -> DepositoTicket {
        var ticket = DepositoTicket(
            id: UUID(),
            ciudadanoId: ciudadanoId,
            puntoAcopioId: punto.id,
            materiales: materiales,
            fotoVerificacion: nil,
            timestamp: Calendar.current.date(byAdding: .day, value: dias, to: Date())!,
            puntosOtorgados: 0,
            verificado: true
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
        let porcentaje: Double = kgTotal > 200 ? 0.40 : kgTotal > 100 ? 0.30 : 0.20
        let nominaMensualEjemplo = 150_000.0
        return nominaMensualEjemplo * porcentaje
    }
}
