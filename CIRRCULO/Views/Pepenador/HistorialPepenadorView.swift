import SwiftUI

struct HistorialPepenadorView: View {
    @EnvironmentObject var store: AppDataStore
    var onCambiarPerfil: (() -> Void)? = nil

    private var recolecciones: [RecoleccionHistorial] { store.misRecolecciones }
    private var totalMes: Double { recolecciones.reduce(0) { $0 + $1.ingresos } }
    private var totalKg: Double { recolecciones.reduce(0) { $0 + $1.kgTotales } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HistorialPepenadorHeader(totalMes: totalMes, viajes: recolecciones.count, totalKg: totalKg, onCambiarPerfil: onCambiarPerfil)

                    VStack(spacing: 0) {
                        // Lista
                        VStack(spacing: 1) {
                            ForEach(recolecciones) { r in
                                RecoleccionRow(recoleccion: r)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Header

struct HistorialPepenadorHeader: View {
    let totalMes: Double
    let viajes: Int
    let totalKg: Double
    var onCambiarPerfil: (() -> Void)? = nil
    @State private var animado = false

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#E65100"), Color(hex: "#F4511E"), Color(hex: "#FF7043")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.06)).frame(width: 220).offset(x: 130, y: -50)
            Circle().fill(.white.opacity(0.04)).frame(width: 160).offset(x: -80, y: 30)

            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mi Historial")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Mayo 2026")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bicycle.circle.fill")
                            .font(.system(size: 36))
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

                // Ingresos
                VStack(spacing: 4) {
                    Text("$\(String(format: "%.0f", totalMes))")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(.white)
                        .scaleEffect(animado ? 1 : 0.8)
                    Text("MXN del mes")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Stats
                HStack(spacing: 0) {
                    StatBadgePepenador(valor: "\(viajes)", label: "viajes")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    StatBadgePepenador(valor: "\(String(format: "%.0f", totalKg)) kg", label: "recolectados")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    StatBadgePepenador(valor: "$\(String(format: "%.0f", totalMes / max(Double(viajes), 1)))", label: "por viaje")
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animado = true
            }
        }
    }
}

struct StatBadgePepenador: View {
    let valor: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(valor).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data

struct RecoleccionHistorial: Identifiable {
    let id: UUID
    var pepenadorId: String = ""
    let puntoNombre: String
    let fecha: Date
    let kgTotales: Double
    let ingresos: Double
    let centroDestino: String
}

struct RecoleccionRow: View {
    let recoleccion: RecoleccionHistorial

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#FFF3E0"))
                    .frame(width: 48, height: 48)
                Image(systemName: "bicycle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#E65100"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(recoleccion.puntoNombre)
                    .font(.subheadline.bold())
                Text(recoleccion.fecha, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(String(format: "%.1f", recoleccion.kgTotales)) kg · \(recoleccion.centroDestino)",
                      systemImage: "shippingbox")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.0f", recoleccion.ingresos))")
                    .font(.headline.bold())
                    .foregroundStyle(Color(hex: "#E65100"))
                Text("MXN")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }
}

#Preview {
    HistorialPepenadorView()
        .environmentObject(AppDataStore())
}
