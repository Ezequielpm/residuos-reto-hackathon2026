import SwiftUI
import Charts

struct DashboardEmpresaView: View {
    @State private var registro = MockDataService.shared.registroEmpresa

    private var datosSemana: [(semana: String, kg: Double)] {
        let calendar = Calendar.current
        var resultado: [String: Double] = [:]
        for reg in registro.residuosRegistrados {
            let semana = calendar.component(.weekOfMonth, from: reg.timestamp)
            let key = "S\(semana)"
            resultado[key, default: 0] += reg.kg
        }
        return resultado.sorted(by: { $0.key < $1.key }).map { (semana: $0.key, kg: $0.value) }
    }

    private var kgPorTipo: [(tipo: String, kg: Double)] {
        var resultado: [String: Double] = [:]
        for reg in registro.residuosRegistrados {
            resultado[reg.tipo.rawValue, default: 0] += reg.kg
        }
        return resultado.sorted(by: { $0.value > $1.value }).prefix(5).map { (tipo: $0.key, kg: $0.value) }
    }

    private var porcentajeClasificados: Double {
        let total = registro.residuosRegistrados.count
        guard total > 0 else { return 0 }
        let correctos = registro.residuosRegistrados.filter { $0.tipo != .noReciclable }.count
        return Double(correctos) / Double(total) * 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Métricas principales
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(titulo: "Kg este mes",
                                   valor: String(format: "%.1f kg", registro.kgTotalesMes),
                                   icono: "scalemass.fill", color: Color(hex: "#1565C0"))

                        MetricCard(titulo: "Registros",
                                   valor: "\(registro.residuosRegistrados.count)",
                                   icono: "doc.text.fill", color: Color(hex: "#1565C0"))

                        MetricCard(titulo: "Ahorro fiscal",
                                   valor: "$\(String(format: "%.0f", registro.ahorroFiscalEstimado))",
                                   icono: "dollarsign.circle.fill", color: Color(hex: "#2E7D32"))

                        MetricCard(titulo: "Cumplimiento NADF",
                                   valor: String(format: "%.0f%%", porcentajeClasificados),
                                   icono: "checkmark.shield.fill", color: Color(hex: "#2E7D32"))
                    }
                    .padding(.horizontal)

                    // Gráfica de barras por semana
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kg registrados por semana")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(datosSemana, id: \.semana) { dato in
                            BarMark(
                                x: .value("Semana", dato.semana),
                                y: .value("kg", dato.kg)
                            )
                            .foregroundStyle(Color(hex: "#1565C0"))
                            .cornerRadius(4)
                        }
                        .frame(height: 180)
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.06), radius: 4)
                        .padding(.horizontal)
                    }

                    // Top materiales
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Por tipo de residuo")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(kgPorTipo, id: \.tipo) { dato in
                                HStack {
                                    Text(dato.tipo)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(String(format: "%.1f kg", dato.kg))
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color(hex: "#1565C0"))
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                Divider().padding(.horizontal)
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.06), radius: 4)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard Empresa")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MetricCard: View {
    let titulo: String
    let valor: String
    let icono: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icono)
                .font(.title2)
                .foregroundStyle(color)

            Text(valor)
                .font(.title3.bold())

            Text(titulo)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4)
    }
}

#Preview {
    DashboardEmpresaView()
}
