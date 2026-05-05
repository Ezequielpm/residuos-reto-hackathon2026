import SwiftUI

struct ConfirmarRecepcionView: View {
    @State private var recepciones = recepcionesEjemplo
    @State private var confirmadas: Set<UUID> = []

    private var pendientes: [RecepcionPendiente] {
        recepciones.filter { !confirmadas.contains($0.id) }
    }

    private var yaConfirmadas: [RecepcionPendiente] {
        recepciones.filter { confirmadas.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Pendientes de confirmar") {
                    ForEach(pendientes) { r in
                        RecepcionRow(recepcion: r, confirmada: false) {
                            withAnimation {
                                _ = confirmadas.insert(r.id)
                            }
                        }
                    }
                }

                if !confirmadas.isEmpty {
                    Section("Confirmadas hoy") {
                        ForEach(yaConfirmadas) { r in
                            RecepcionRow(recepcion: r, confirmada: true, onConfirmar: {})
                        }
                    }
                }
            }
            .navigationTitle("Recepciones")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RecepcionPendiente: Identifiable {
    let id: UUID
    let pepenador: String
    let origen: String
    let materiales: [(tipo: String, kg: Double)]
    let timestamp: Date
}

struct RecepcionRow: View {
    let recepcion: RecepcionPendiente
    let confirmada: Bool
    let onConfirmar: () -> Void

    private var valorTotal: Double {
        recepcion.materiales.reduce(0) { acc, m in
            let precios: [String: Double] = [
                "Aluminio": 22.0, "Plástico PET": 8.5,
                "Cartón": 0.70, "Vidrio": 0.30
            ]
            return acc + m.kg * (precios[m.tipo] ?? 1.0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(recepcion.pepenador, systemImage: "bicycle")
                    .font(.subheadline.bold())
                Spacer()
                Text(recepcion.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Origen: \(recepcion.origen)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(recepcion.materiales, id: \.tipo) { m in
                        Text("\(m.tipo): \(String(format: "%.1f", m.kg)) kg")
                            .font(.caption)
                    }
                }
                Spacer()
                Text("$\(String(format: "%.0f", valorTotal)) MXN")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "#BF360C"))
            }

            if !confirmada {
                Button(action: onConfirmar) {
                    Text("Confirmar recepción")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#BF360C"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Label("Confirmada", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "#4CAF50"))
            }
        }
        .padding(.vertical, 4)
    }
}

private let recepcionesEjemplo: [RecepcionPendiente] = [
    RecepcionPendiente(
        id: UUID(),
        pepenador: "Javier M.",
        origen: "Ecocentro Coyoacán",
        materiales: [("Aluminio", 3.2), ("Plástico PET", 8.5)],
        timestamp: Date().addingTimeInterval(-1800)
    ),
    RecepcionPendiente(
        id: UUID(),
        pepenador: "Rosa G.",
        origen: "Punto Verde Roma Norte",
        materiales: [("Vidrio", 43.5), ("Cartón", 12.0)],
        timestamp: Date().addingTimeInterval(-3600)
    ),
    RecepcionPendiente(
        id: UUID(),
        pepenador: "Manuel T.",
        origen: "Reciclaje Condesa",
        materiales: [("Plástico PET", 18.2), ("Aluminio", 2.1)],
        timestamp: Date().addingTimeInterval(-5400)
    )
]

#Preview {
    ConfirmarRecepcionView()
}
