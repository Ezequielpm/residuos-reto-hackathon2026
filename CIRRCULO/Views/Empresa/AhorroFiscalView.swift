import SwiftUI

struct AhorroFiscalView: View {
    @ObservedObject var vm: EmpresaViewModel
    @State private var nominaMensual: Double = 150_000
    @State private var nominaTexto = "150000"
    @State private var animado = false

    private var ahorroTotal: Double { nominaMensual * vm.porcentajeReduccion }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    AhorroFiscalHeader(
                        reduccion: vm.porcentajeReduccion,
                        ahorro: ahorroTotal,
                        animado: animado
                    )

                    VStack(spacing: 20) {
                        // Input nómina
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(titulo: "Nómina mensual", icono: "building.2.fill", color: Color(hex: "#1565C0"))

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("$")
                                        .font(.title2.bold())
                                        .foregroundStyle(.secondary)
                                    TextField("150000", text: $nominaTexto)
                                        .keyboardType(.decimalPad)
                                        .font(.title2.bold())
                                        .onChange(of: nominaTexto) { _, v in
                                            nominaMensual = Double(v) ?? 150_000
                                        }
                                    Text("MXN")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)

                                Text("Ingresa la nómina mensual total de tu empresa")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Cumplimiento
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(titulo: "Cumplimiento NADF-024", icono: "checkmark.shield.fill", color: Color(hex: "#1565C0"))
                                .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Nivel de clasificación")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.0f%%", vm.porcentajeClasificados * 100))
                                        .font(.title3.bold())
                                        .foregroundStyle(Color(hex: "#1565C0"))
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(.systemGray6))
                                            .frame(height: 10)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "#42A5F5"), Color(hex: "#1565C0")],
                                                startPoint: .leading, endPoint: .trailing
                                            ))
                                            .frame(width: animado ? geo.size.width * vm.porcentajeClasificados : 0, height: 10)
                                            .animation(.spring(response: 0.8).delay(0.3), value: animado)
                                    }
                                }
                                .frame(height: 10)

                                // Niveles de reducción
                                HStack(spacing: 8) {
                                    NivelBadge(porcentaje: "20%", label: "Básico", activo: vm.porcentajeReduccion >= 0.20, color: Color(hex: "#42A5F5"))
                                    NivelBadge(porcentaje: "30%", label: "Estándar", activo: vm.porcentajeReduccion >= 0.30, color: Color(hex: "#1E88E5"))
                                    NivelBadge(porcentaje: "40%", label: "Óptimo", activo: vm.porcentajeReduccion >= 0.40, color: Color(hex: "#1565C0"))
                                }
                            }
                            .padding(20)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                            .padding(.horizontal, 20)
                        }

                        // Ahorro destacado
                        VStack(spacing: 8) {
                            Text("Ahorro estimado mensual")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.0f", ahorroTotal))")
                                .font(.system(size: 44, weight: .black))
                                .foregroundStyle(Color(hex: "#2E7D32"))
                            Text("MXN al presentar reporte ante SEDEMA")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#E8F5E9"), Color(hex: "#F1F8E9")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#4CAF50").opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        // Pasos
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(titulo: "¿Cómo funciona?", icono: "info.circle.fill", color: Color(hex: "#1565C0"))
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(Array(pasos.enumerated()), id: \.offset) { idx, paso in
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "#E3F2FD"))
                                                .frame(width: 36, height: 36)
                                            Text("\(idx + 1)")
                                                .font(.headline)
                                                .foregroundStyle(Color(hex: "#1565C0"))
                                        }
                                        Text(paso)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                    .padding(16)

                                    if idx < pasos.count - 1 {
                                        Divider().padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                            .padding(.horizontal, 20)
                        }

                        // Exportar
                        Button { } label: {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("Exportar reporte PDF")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#42A5F5"), Color(hex: "#1565C0")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color(hex: "#1565C0").opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear {
                withAnimation { animado = true }
            }
        }
    }

    private let pasos = [
        "Registra y clasifica tus residuos con Nexia",
        "Exporta el reporte de cumplimiento NADF-024",
        "Preséntalo ante SEDEMA para obtener la reducción",
        "Aplica el ahorro en tu declaración mensual de nómina"
    ]
}

// MARK: - Header

struct AhorroFiscalHeader: View {
    let reduccion: Double
    let ahorro: Double
    let animado: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#0D47A1"), Color(hex: "#1565C0"), Color(hex: "#1976D2")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 140, y: -40)
            Circle().fill(.white.opacity(0.04)).frame(width: 150).offset(x: -80, y: 30)

            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ahorro Fiscal")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Beneficio NADF-024")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.3))
                }

                HStack(spacing: 0) {
                    MetricaTarjeta(
                        valor: String(format: "%.0f%%", reduccion * 100),
                        unidad: "reducción",
                        label: "Impuesto nómina",
                        icono: "percent"
                    )
                    MetricaTarjeta(
                        valor: "$\(String(format: "%.0f", ahorro))",
                        unidad: "MXN",
                        label: "Ahorro estimado",
                        icono: "banknote.fill"
                    )
                }
                .scaleEffect(animado ? 1 : 0.9)
                .animation(.spring(response: 0.5).delay(0.2), value: animado)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Helpers

struct NivelBadge: View {
    let porcentaje: String
    let label: String
    let activo: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(porcentaje)
                .font(.headline.bold())
                .foregroundStyle(activo ? .white : color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(activo ? .white.opacity(0.85) : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(activo ? color : color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
