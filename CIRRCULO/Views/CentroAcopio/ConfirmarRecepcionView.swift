import SwiftUI

struct ConfirmarRecepcionView: View {
    var onCambiarPerfil: (() -> Void)? = nil
    @State private var recepciones = recepcionesEjemplo
    @State private var confirmadas: Set<UUID> = []

    private var pendientes: [RecepcionPendiente] {
        recepciones.filter { !confirmadas.contains($0.id) }
    }
    private var yaConfirmadas: [RecepcionPendiente] {
        recepciones.filter { confirmadas.contains($0.id) }
    }

    private var totalHoy: Double {
        yaConfirmadas.reduce(0) { acc, r in
            acc + r.materiales.reduce(0) { $0 + $1.kg * (["Aluminio": 22.0, "Plástico PET": 8.5, "Cartón": 0.70, "Vidrio": 0.30][$1.tipo] ?? 1.0) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    RecepcionesHeader(
                        pendientesCount: pendientes.count,
                        confirmadasCount: yaConfirmadas.count,
                        totalHoy: totalHoy,
                        onCambiarPerfil: onCambiarPerfil
                    )

                    VStack(spacing: 20) {
                        // Pendientes
                        if !pendientes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(titulo: "Pendientes de confirmar",
                                              icono: "clock.badge.exclamationmark.fill",
                                              color: Color(hex: "#AD1457"))

                                VStack(spacing: 12) {
                                    ForEach(pendientes) { r in
                                        RecepcionCard(recepcion: r, confirmada: false) {
                                            withAnimation(.spring()) {
                                                _ = confirmadas.insert(r.id)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Confirmadas
                        if !yaConfirmadas.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(titulo: "Confirmadas hoy",
                                              icono: "checkmark.seal.fill",
                                              color: Color(hex: "#4CAF50"))

                                VStack(spacing: 12) {
                                    ForEach(yaConfirmadas) { r in
                                        RecepcionCard(recepcion: r, confirmada: true, onConfirmar: {})
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        if pendientes.isEmpty && yaConfirmadas.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("Sin recepciones pendientes")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Header

struct RecepcionesHeader: View {
    let pendientesCount: Int
    let confirmadasCount: Int
    let totalHoy: Double
    var onCambiarPerfil: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#880E4F"), Color(hex: "#AD1457"), Color(hex: "#C2185B")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 130, y: -30)
            Circle().fill(.white.opacity(0.04)).frame(width: 140).offset(x: -70, y: 25)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recepciones")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Centro de Acopio Sur")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "shippingbox.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.3))
                        if let onCambiarPerfil {
                            Button(action: onCambiarPerfil) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.2.circlepath").font(.caption2.bold())
                                    Text("Cambiar").font(.caption2.bold())
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

                HStack(spacing: 0) {
                    RecepcionStat(valor: "\(pendientesCount)", label: "pendientes")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    RecepcionStat(valor: "\(confirmadasCount)", label: "confirmadas")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    RecepcionStat(valor: "$\(String(format: "%.0f", totalHoy))", label: "recibido MXN")
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
    }
}

struct RecepcionStat: View {
    let valor: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(valor).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data

struct RecepcionPendiente: Identifiable {
    let id: UUID
    let pepenador: String
    let origen: String
    let materiales: [(tipo: String, kg: Double)]
    let timestamp: Date
}

struct RecepcionCard: View {
    let recepcion: RecepcionPendiente
    let confirmada: Bool
    let onConfirmar: () -> Void

    private let precios: [String: Double] = [
        "Aluminio": 22.0, "Plástico PET": 8.5,
        "Cartón": 0.70, "Vidrio": 0.30
    ]

    private var valorTotal: Double {
        recepcion.materiales.reduce(0) { $0 + $1.kg * (precios[$1.tipo] ?? 1.0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(confirmada ? Color(hex: "#E8F5E9") : Color(hex: "#FCE4EC"))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bicycle")
                        .font(.system(size: 18))
                        .foregroundStyle(confirmada ? Color(hex: "#4CAF50") : Color(hex: "#AD1457"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(recepcion.pepenador)
                        .font(.subheadline.bold())
                    Label(recepcion.origen, systemImage: "mappin.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(recepcion.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(String(format: "%.0f", valorTotal)) MXN")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "#AD1457"))
                }
            }

            // Materiales
            HStack(spacing: 8) {
                ForEach(recepcion.materiales, id: \.tipo) { m in
                    Text("\(m.tipo) \(String(format: "%.1f", m.kg))kg")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
            }

            // Acción
            if confirmada {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#4CAF50"))
                    Text("Recepción confirmada")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "#4CAF50"))
                }
            } else {
                Button(action: onConfirmar) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirmar recepción")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#EC407A"), Color(hex: "#AD1457")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

private let recepcionesEjemplo: [RecepcionPendiente] = [
    RecepcionPendiente(id: UUID(), pepenador: "Javier M.",  origen: "Ecocentro Coyoacán",      materiales: [("Aluminio", 3.2), ("Plástico PET", 8.5)], timestamp: Date().addingTimeInterval(-1800)),
    RecepcionPendiente(id: UUID(), pepenador: "Rosa G.",    origen: "Punto Verde Roma Norte",  materiales: [("Vidrio", 43.5), ("Cartón", 12.0)],       timestamp: Date().addingTimeInterval(-3600)),
    RecepcionPendiente(id: UUID(), pepenador: "Manuel T.",  origen: "Reciclaje Condesa",       materiales: [("Plástico PET", 18.2), ("Aluminio", 2.1)], timestamp: Date().addingTimeInterval(-5400))
]

#Preview {
    ConfirmarRecepcionView()
}
