import SwiftUI
import Charts

struct DashboardEmpresaView: View {
    @ObservedObject var vm: EmpresaViewModel
    var onCambiarPerfil: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header degradado azul
                    HeaderEmpresa(vm: vm, onCambiarPerfil: onCambiarPerfil)

                    VStack(spacing: 20) {
                        // Gráfica de barras
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(titulo: "Kg por semana", icono: "chart.bar.fill", color: Color(hex: "#1565C0"))

                            if vm.datosSemana.isEmpty {
                                Text("Sin datos esta semana")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: 140)
                            } else {
                                Chart(vm.datosSemana, id: \.semana) { dato in
                                    BarMark(
                                        x: .value("Semana", dato.semana),
                                        y: .value("kg", dato.kg)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "#42A5F5"), Color(hex: "#1565C0")],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                                .frame(height: 160)
                                .chartXAxis {
                                    AxisMarks { _ in
                                        AxisValueLabel().font(.caption)
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { _ in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                            .foregroundStyle(Color(.systemGray5))
                                        AxisValueLabel().font(.caption2)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                        .padding(.horizontal, 20)

                        // Top materiales
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(titulo: "Por tipo de residuo", icono: "list.bullet.clipboard.fill", color: Color(hex: "#1565C0"))

                            VStack(spacing: 10) {
                                ForEach(vm.kgPorTipo, id: \.tipo) { dato in
                                    MaterialBarRow(
                                        tipo: dato.tipo,
                                        kg: dato.kg,
                                        maximo: vm.kgPorTipo.first?.kg ?? 1
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                        .padding(.horizontal, 20)

                        // Cadena de custodia
                        HStack(spacing: 14) {
                            CustodiaCard(
                                valor: "\(vm.registro.residuosRegistrados.filter { $0.destinoCentroAcopio != nil }.count)",
                                label: "Con destino\ndocumentado",
                                icono: "checkmark.shield.fill",
                                color: Color(hex: "#2E7D32")
                            )
                            CustodiaCard(
                                valor: String(format: "%.0f%%", vm.porcentajeClasificados * 100),
                                label: "Cumplimiento\nNADF-024",
                                icono: "star.fill",
                                color: Color(hex: "#F9A825")
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Header empresa

struct HeaderEmpresa: View {
    @ObservedObject var vm: EmpresaViewModel
    var onCambiarPerfil: (() -> Void)? = nil

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
                        Text("WALMART")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Mayo 2026")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.3))
                        if let onCambiarPerfil {
                            Button(action: onCambiarPerfil) {
                                HStack(spacing: 4) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right").font(.caption2.bold())
                                    Text("Salir").font(.caption2.bold())
                                }
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Métricas en grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricaTarjeta(
                        valor: String(format: "%.1f", vm.registro.kgTotalesMes),
                        unidad: "kg",
                        label: "Residuos este mes",
                        icono: "scalemass.fill"
                    )
                    MetricaTarjeta(
                        valor: "\(vm.registro.residuosRegistrados.count)",
                        unidad: "reg.",
                        label: "Registros documentados",
                        icono: "doc.text.fill"
                    )
                    MetricaTarjeta(
                        valor: "$\(String(format: "%.0f", vm.registro.ahorroFiscalEstimado))",
                        unidad: "MXN",
                        label: "Ahorro fiscal estimado",
                        icono: "dollarsign.circle.fill"
                    )
                    MetricaTarjeta(
                        valor: String(format: "%.0f", vm.porcentajeReduccion * 100),
                        unidad: "%",
                        label: "Reducción de nómina",
                        icono: "percent"
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 24)
        }
    }
}

struct MetricaTarjeta: View {
    let valor: String
    let unidad: String
    let label: String
    let icono: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(valor).font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                    Text(unidad).font(.caption).foregroundStyle(.white.opacity(0.65))
                }
                Text(label).font(.caption2).foregroundStyle(.white.opacity(0.6)).lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Material Bar Row

struct MaterialBarRow: View {
    let tipo: String
    let kg: Double
    let maximo: Double
    @State private var animado = false

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(tipo).font(.subheadline)
                Spacer()
                Text(String(format: "%.1f kg", kg))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "#1565C0"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#42A5F5"), Color(hex: "#1565C0")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: animado ? geo.size.width * (kg / maximo) : 0, height: 6)
                        .animation(.spring(response: 0.7).delay(0.1), value: animado)
                }
            }
            .frame(height: 6)
        }
        .onAppear { animado = true }
    }
}

// MARK: - Custodia Card

struct CustodiaCard: View {
    let valor: String
    let label: String
    let icono: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icono)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(valor).font(.title2.bold()).foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

struct MetricCard: View {
    let titulo: String
    let valor: String
    let icono: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icono).font(.title2).foregroundStyle(color)
            Text(valor).font(.title3.bold())
            Text(titulo).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4)
    }
}
