import SwiftUI
import Combine

/// Estado compartido entre DashboardEmpresaView y ScannerEmpresaView.
/// Al escanear un objeto en el escáner corporativo, el dashboard se actualiza en tiempo real.
@MainActor
final class EmpresaViewModel: ObservableObject {

    @Published var registro: RegistroEmpresa
    @Published var empleados: [Empleado]

    init() {
        self.registro = MockDataService.shared.registroEmpresa
        self.empleados = MockDataService.shared.empleados
    }

    // MARK: - Registrar escaneo desde ScannerEmpresaView

    func registrarEscaneo(tipo: TipoResiduo, kg: Double = 0.5, empleadoId: String = "emp-demo-01") {
        let nuevo = RegistroResiduo(
            id: UUID(),
            tipo: tipo,
            kg: kg,
            timestamp: Date(),
            empleadoId: empleadoId,
            destinoCentroAcopio: "Centro de Acopio Sur CDMX"
        )
        registro.residuosRegistrados.append(nuevo)
        registro.kgTotalesMes += kg
        registro.ahorroFiscalEstimado = calcularAhorro(kgTotal: registro.kgTotalesMes)

        // Actualizar escaneos del empleado
        if let idx = empleados.firstIndex(where: { $0.id.uuidString.hasPrefix(empleadoId) }) {
            empleados[idx].escaneosMes += 1
            empleados[idx].kgRegistradosMes += kg
        }
    }

    // MARK: - Métricas calculadas

    var kgPorTipo: [(tipo: String, kg: Double)] {
        var mapa: [String: Double] = [:]
        for r in registro.residuosRegistrados {
            mapa[r.tipo.rawValue, default: 0] += r.kg
        }
        return mapa.sorted { $0.value > $1.value }.prefix(5).map { (tipo: $0.key, kg: $0.value) }
    }

    var datosSemana: [(semana: String, kg: Double)] {
        let calendar = Calendar.current
        var mapa: [String: Double] = [:]
        for r in registro.residuosRegistrados {
            let s = calendar.component(.weekOfMonth, from: r.timestamp)
            mapa["S\(s)", default: 0] += r.kg
        }
        return mapa.sorted { $0.key < $1.key }.map { (semana: $0.key, kg: $0.value) }
    }

    var porcentajeClasificados: Double {
        let total = registro.residuosRegistrados.count
        guard total > 0 else { return 0 }
        let correctos = registro.residuosRegistrados.filter { $0.tipo != .noReciclable }.count
        return Double(correctos) / Double(total)
    }

    var porcentajeReduccion: Double {
        if porcentajeClasificados >= 0.90 { return 0.40 }
        if porcentajeClasificados >= 0.75 { return 0.30 }
        return 0.20
    }

    // MARK: - Helpers privados

    private func calcularAhorro(kgTotal: Double) -> Double {
        let porcentaje: Double = kgTotal > 200 ? 0.40 : kgTotal > 100 ? 0.30 : 0.20
        return 150_000.0 * porcentaje
    }
}
