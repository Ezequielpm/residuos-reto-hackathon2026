import SwiftUI

struct HistorialPepenadorView: View {
    @State private var recolecciones = historialEjemplo

    private var totalMes: Double {
        recolecciones.reduce(0) { $0 + $1.ingresos }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total del mes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.0f", totalMes)) MXN")
                                .font(.title.bold())
                                .foregroundStyle(Color(hex: "#F9A825"))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Viajes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(recolecciones.count)")
                                .font(.title.bold())
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Recolecciones completadas") {
                    ForEach(recolecciones) { r in
                        RecoleccionRow(recoleccion: r)
                    }
                }
            }
            .navigationTitle("Mi Historial")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RecoleccionHistorial: Identifiable {
    let id: UUID
    let puntoNombre: String
    let fecha: Date
    let kgTotales: Double
    let ingresos: Double
    let centroDestino: String
}

struct RecoleccionRow: View {
    let recoleccion: RecoleccionHistorial

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FFF8E1"))
                    .frame(width: 44, height: 44)
                Image(systemName: "bicycle")
                    .foregroundStyle(Color(hex: "#F9A825"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(recoleccion.puntoNombre)
                    .font(.subheadline.bold())
                Text(recoleccion.fecha, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(String(format: "%.1f", recoleccion.kgTotales)) kg · \(recoleccion.centroDestino)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("$\(String(format: "%.0f", recoleccion.ingresos))")
                .font(.headline)
                .foregroundStyle(Color(hex: "#F9A825"))
        }
        .padding(.vertical, 4)
    }
}

private let historialEjemplo: [RecoleccionHistorial] = [
    RecoleccionHistorial(id: UUID(), puntoNombre: "Ecocentro Coyoacán",    fecha: Date().addingTimeInterval(-86400),   kgTotales: 23.7, ingresos: 267.0, centroDestino: "Centro Sur"),
    RecoleccionHistorial(id: UUID(), puntoNombre: "Punto Verde Roma Norte", fecha: Date().addingTimeInterval(-172800),  kgTotales: 43.5, ingresos: 48.0,  centroDestino: "Centro Sur"),
    RecoleccionHistorial(id: UUID(), puntoNombre: "Reciclaje Condesa",     fecha: Date().addingTimeInterval(-345600),  kgTotales: 35.0, ingresos: 134.5, centroDestino: "Acopio Oriente"),
    RecoleccionHistorial(id: UUID(), puntoNombre: "Acopio Tlalpan",        fecha: Date().addingTimeInterval(-604800),  kgTotales: 18.2, ingresos: 95.0,  centroDestino: "Centro Sur"),
    RecoleccionHistorial(id: UUID(), puntoNombre: "EcoBox Polanco",        fecha: Date().addingTimeInterval(-864000),  kgTotales: 12.8, ingresos: 220.0, centroDestino: "Centro Sur")
]

#Preview {
    HistorialPepenadorView()
}
