import SwiftUI

struct AhorroFiscalView: View {
    @ObservedObject var vm: EmpresaViewModel
    @State private var nominaMensual: Double = 150_000
    @State private var nominaTexto = "150000"

    private var ahorroTotal: Double {
        nominaMensual * vm.porcentajeReduccion
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Input nómina
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nómina mensual de la empresa")
                            .font(.headline)

                        HStack {
                            Text("$").foregroundStyle(.secondary)
                            TextField("150000", text: $nominaTexto)
                                .keyboardType(.decimalPad)
                                .font(.title3)
                                .onChange(of: nominaTexto) { _, v in
                                    nominaMensual = Double(v) ?? 150_000
                                }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("MXN al mes")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Resultados
                    VStack(spacing: 16) {
                        // Cumplimiento
                        VStack(spacing: 8) {
                            HStack {
                                Text("Cumplimiento NADF-024")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(String(format: "%.0f%%", vm.porcentajeClasificados * 100))
                                    .font(.title3.bold())
                                    .foregroundStyle(Color(hex: "#1565C0"))
                            }
                            ProgressView(value: vm.porcentajeClasificados)
                                .tint(Color(hex: "#1565C0"))
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.06), radius: 4)

                        // Reducción
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reducción de impuesto sobre nómina")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Text(String(format: "%.0f%%", vm.porcentajeReduccion * 100))
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundStyle(Color(hex: "#1565C0"))
                            }
                            Spacer()
                            Image(systemName: "percent")
                                .font(.system(size: 44))
                                .foregroundStyle(Color(hex: "#1565C0").opacity(0.25))
                        }
                        .padding()
                        .background(Color(hex: "#E3F2FD"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Ahorro
                        VStack(spacing: 8) {
                            Text("Ahorro estimado mensual")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("$\(String(format: "%.0f", ahorroTotal)) MXN")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(Color(hex: "#2E7D32"))
                            Text("al presentar reporte ante SEDEMA")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(hex: "#E8F5E9"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    // Pasos
                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Cómo funciona?")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            BeneficioRow(icono: "1.circle.fill", texto: "Registra y clasifica tus residuos con CIRRCULO")
                            BeneficioRow(icono: "2.circle.fill", texto: "Exporta el reporte de cumplimiento NADF-024")
                            BeneficioRow(icono: "3.circle.fill", texto: "Preséntalo ante SEDEMA para obtener la reducción")
                            BeneficioRow(icono: "4.circle.fill", texto: "Aplica el ahorro en tu declaración mensual de nómina")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.06), radius: 4)
                    .padding(.horizontal)

                    // Exportar
                    Button { } label: {
                        Label("Exportar reporte PDF", systemImage: "arrow.down.doc.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#1565C0"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ahorro Fiscal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct BeneficioRow: View {
    let icono: String
    let texto: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icono)
                .foregroundStyle(Color(hex: "#1565C0"))
            Text(texto)
                .font(.subheadline)
        }
    }
}
