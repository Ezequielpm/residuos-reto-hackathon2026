import SwiftUI

struct PanelContenedoresView: View {
    @State private var punto = MockDataService.shared.puntosAcopio[0]
    @State private var solicitudEnviada = false

    private var porcentajeVerde: Double { 0.45 }
    private var porcentajeGris: Double {
        let total = punto.materialDisponible.values.reduce(0, +)
        return min(total / punto.capacidadTotal, 1.0)
    }
    private var porcentajeNaranja: Double { 0.22 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Barras de contenedores
                    VStack(spacing: 16) {
                        ContenedorBar(
                            nombre: "Verde (Orgánicos)",
                            porcentaje: porcentajeVerde,
                            color: Color(hex: "#4CAF50"),
                            dias: "Mar, Jue, Sáb"
                        )
                        ContenedorBar(
                            nombre: "Gris (Reciclables)",
                            porcentaje: porcentajeGris,
                            color: Color(hex: "#607D8B"),
                            dias: "Lun, Mié, Vie, Dom"
                        )
                        ContenedorBar(
                            nombre: "Naranja (No reciclables)",
                            porcentaje: porcentajeNaranja,
                            color: Color(hex: "#FF5722"),
                            dias: "Lun, Mié, Vie, Dom"
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.06), radius: 6)
                    .padding(.horizontal)

                    // Solicitar recolección
                    if porcentajeGris > 0.7 || porcentajeVerde > 0.7 {
                        Button {
                            withAnimation { solicitudEnviada = true }
                        } label: {
                            if solicitudEnviada {
                                Label("Solicitud enviada", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "#4CAF50"))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Label("Solicitar recolección", systemImage: "bell.badge.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "#FF5722"))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Depósitos de hoy
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Depósitos de hoy")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(MockDataService.shared.historialDepositos.prefix(3)) { ticket in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "#4CAF50"))
                                VStack(alignment: .leading) {
                                    Text("Ciudadano anónimo")
                                        .font(.subheadline.bold())
                                    Text(ticket.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(String(format: "%.1f", ticket.materiales.values.reduce(0, +))) kg")
                                    .font(.subheadline.bold())
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Panel de Contenedores")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContenedorBar: View {
    let nombre: String
    let porcentaje: Double
    let color: Color
    let dias: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(nombre)
                    .font(.subheadline.bold())
                Spacer()
                Text(String(format: "%.0f%%", porcentaje * 100))
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
            }
            ProgressView(value: porcentaje)
                .tint(color)
            Text("Recolección: \(dias)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PanelContenedoresView()
}
