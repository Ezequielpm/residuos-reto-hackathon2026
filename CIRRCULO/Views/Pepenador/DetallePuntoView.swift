import SwiftUI

struct DetallePuntoView: View {
    @Binding var solicitud: SolicitudRecoleccion
    let onReclamar: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header naranja
                DetallePuntoHeader(solicitud: solicitud)

                VStack(spacing: 16) {
                    // Materiales
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(titulo: "Materiales disponibles",
                                      icono: "shippingbox.fill",
                                      color: Color(hex: "#E65100"))
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(solicitud.materialesPrincipales, id: \.self) { tipo in
                                let kg = solicitud.kgEstimados / Double(solicitud.materialesPrincipales.count)
                                MaterialDetalleRow(tipo: tipo, kg: kg)
                                if tipo != solicitud.materialesPrincipales.last {
                                    Divider().padding(.horizontal, 16)
                                }
                            }

                            Divider()

                            // Total
                            HStack {
                                Label("Total estimado", systemImage: "dollarsign.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(Color(hex: "#E65100"))
                                Spacer()
                                Text("$\(String(format: "%.0f", solicitud.valorEstimado)) MXN")
                                    .font(.title3.bold())
                                    .foregroundStyle(Color(hex: "#E65100"))
                            }
                            .padding(16)
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
                        .padding(.horizontal, 20)
                    }

                    // Botones
                    VStack(spacing: 10) {
                        if solicitud.estado == .disponible {
                            Button(action: onReclamar) {
                                HStack {
                                    Image(systemName: "hand.raised.fill")
                                    Text("Reclamar recolección")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#FFA726"), Color(hex: "#E65100")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: Color(hex: "#E65100").opacity(0.35), radius: 8, y: 4)
                            }
                        } else {
                            HStack {
                                Image(systemName: "lock.circle.fill")
                                Text("Esta recolección ya fue reclamada")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Link(destination: URL(string: "maps://?daddr=\(solicitud.puntoAcopio.latitud),\(solicitud.puntoAcopio.longitud)")!) {
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                Text("Cómo llegar")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .padding(.top, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Header

struct DetallePuntoHeader: View {
    let solicitud: SolicitudRecoleccion

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#BF360C"), Color(hex: "#E65100"), Color(hex: "#F4511E")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 130, y: -20)
            Circle().fill(.white.opacity(0.04)).frame(width: 140).offset(x: -70, y: 30)

            VStack(spacing: 16) {
                // Drag indicator
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 36, height: 4)

                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(.white.opacity(0.15)).frame(width: 52, height: 52)
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(solicitud.puntoAcopio.nombre)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Label(solicitud.puntoAcopio.direccion, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    StatusBadge(estado: solicitud.estado)
                }

                // Resumen
                HStack(spacing: 0) {
                    MiniStat(valor: "\(String(format: "%.0f", solicitud.kgEstimados)) kg", label: "disponibles")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    MiniStat(valor: "$\(String(format: "%.0f", solicitud.valorEstimado))", label: "estimado MXN")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    MiniStat(valor: "\(solicitud.materialesPrincipales.count)", label: "materiales")
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
            .padding(.bottom, 24)
        }
    }
}

struct MiniStat: View {
    let valor: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(valor).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Material Row

struct MaterialDetalleRow: View {
    let tipo: TipoResiduo
    let kg: Double

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#FFF3E0"))
                    .frame(width: 42, height: 42)
                Image(systemName: "shippingbox")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "#E65100"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tipo.rawValue)
                    .font(.subheadline.bold())
                Text("$\(String(format: "%.2f", tipo.valorMercado))/kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", kg)) kg")
                    .font(.subheadline)
                Text("≈ $\(String(format: "%.0f", kg * tipo.valorMercado))")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "#E65100"))
            }
        }
        .padding(16)
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
            .background(color.opacity(0.2))
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
