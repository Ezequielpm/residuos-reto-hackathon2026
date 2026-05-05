import SwiftUI

struct DetallePuntoView: View {
    @Binding var solicitud: SolicitudRecoleccion
    let onReclamar: () -> Void

    private let precios: [String: Double] = [
        "Aluminio": 22.0, "Plástico PET": 8.5, "Cartón": 0.70,
        "Vidrio": 0.30, "Lata": 18.0
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Handle
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                // Nombre y dirección
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(solicitud.puntoAcopio.nombre)
                            .font(.title2.bold())
                        Spacer()
                        StatusBadge(estado: solicitud.estado)
                    }
                    Label(solicitud.puntoAcopio.direccion, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Desglose de materiales
                VStack(alignment: .leading, spacing: 8) {
                    Text("Materiales disponibles")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(solicitud.materialesPrincipales, id: \.self) { tipo in
                            let kg = solicitud.kgEstimados / Double(solicitud.materialesPrincipales.count)
                            let precio = tipo.valorMercado
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tipo.rawValue)
                                        .font(.subheadline.bold())
                                    Text("$\(String(format: "%.2f", precio))/kg")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(String(format: "%.1f", kg)) kg")
                                        .font(.subheadline)
                                    Text("≈ $\(String(format: "%.0f", kg * precio))")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color(hex: "#F9A825"))
                                }
                            }
                            .padding()
                            Divider().padding(.horizontal)
                        }

                        // Total
                        HStack {
                            Text("Total estimado")
                                .font(.headline)
                            Spacer()
                            Text("$\(String(format: "%.0f", solicitud.valorEstimado)) MXN")
                                .font(.title3.bold())
                                .foregroundStyle(Color(hex: "#F9A825"))
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.06), radius: 4)
                    .padding(.horizontal)
                }

                // Botones
                VStack(spacing: 10) {
                    if solicitud.estado == .disponible {
                        Button(action: onReclamar) {
                            Label("Reclamar recolección", systemImage: "hand.raised.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#F9A825"))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        Text("Esta recolección ya fue reclamada")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Link(destination: URL(string: "maps://?daddr=\(solicitud.puntoAcopio.latitud),\(solicitud.puntoAcopio.longitud)")!) {
                        Label("Cómo llegar", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
        }
    }
}

struct StatusBadge: View {
    let estado: EstadoRecoleccion

    private var color: Color {
        switch estado {
        case .disponible: return Color(hex: "#4CAF50")
        case .reclamada:  return Color(hex: "#F9A825")
        case .enRuta:     return Color(hex: "#1565C0")
        case .entregada:  return Color(.systemGray4)
        }
    }

    var body: some View {
        Text(estado.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    DetallePuntoView(
        solicitud: .constant(MockDataService.shared.solicitudesRecoleccion[0]),
        onReclamar: {}
    )
}
