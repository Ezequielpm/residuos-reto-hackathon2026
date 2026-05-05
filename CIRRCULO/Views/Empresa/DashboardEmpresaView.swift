import SwiftUI
import Charts

struct DashboardEmpresaView: View {
    @ObservedObject var vm: EmpresaViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Métricas principales
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(
                            titulo: "Kg este mes",
                            valor: String(format: "%.1f kg", vm.registro.kgTotalesMes),
                            icono: "scalemass.fill",
                            color: Color(hex: "#1565C0")
                        )
                        MetricCard(
                            titulo: "Registros",
                            valor: "\(vm.registro.residuosRegistrados.count)",
                            icono: "doc.text.fill",
                            color: Color(hex: "#1565C0")
                        )
                        MetricCard(
                            titulo: "Ahorro fiscal",
                            valor: "$\(String(format: "%.0f", vm.registro.ahorroFiscalEstimado))",
                            icono: "dollarsign.circle.fill",
                            color: Color(hex: "#2E7D32")
                        )
                        MetricCard(
                            titulo: "Cumplimiento NADF",
                            valor: String(format: "%.0f%%", vm.porcentajeClasificados * 100),
                            icono: "checkmark.shield.fill",
                            color: Color(hex: "#2E7D32")
                        )
                    }
                    .padding(.horizontal)

                    // Gráfica por semana
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kg registrados por semana")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(vm.datosSemana, id: \.semana) { dato in
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
                            ForEach(vm.kgPorTipo, id: \.tipo) { dato in
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
