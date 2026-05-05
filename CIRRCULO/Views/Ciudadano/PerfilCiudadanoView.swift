import SwiftUI

struct PerfilCiudadanoView: View {
    @State private var historial = MockDataService.shared.historialDepositos
    @State private var cupones = MockDataService.shared.cupones

    private var totalPuntos: Int {
        historial.reduce(0) { $0 + $1.puntosOtorgados }
    }

    private var totalKg: Double {
        historial.flatMap { $0.materiales.values }.reduce(0, +)
    }

    private var rachaDias: Int { 7 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Card de puntos
                    PuntosCard(puntos: totalPuntos, kg: totalKg, racha: rachaDias)

                    // Cupones
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cupones disponibles")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(cupones) { cupon in
                                    CuponCard(cupon: cupon, puntosActuales: totalPuntos)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Historial
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Últimos depósitos")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(historial.sorted(by: { $0.timestamp > $1.timestamp })) { ticket in
                                TicketRow(ticket: ticket)
                                Divider().padding(.horizontal)
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.06), radius: 6)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PuntosCard: View {
    let puntos: Int
    let kg: Double
    let racha: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(puntos)")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                    Text("puntos acumulados")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color(hex: "#4CAF50"))
            }

            Divider()

            HStack {
                StatItem(valor: "\(String(format: "%.1f", kg)) kg", label: "reciclados")
                Divider().frame(height: 36)
                StatItem(valor: "\(String(format: "%.1f", kg * 2.5)) kg", label: "CO₂ evitados")
                Divider().frame(height: 36)
                StatItem(valor: "\(racha) días", label: "racha activa")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let valor: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(valor)
                .font(.headline)
                .foregroundStyle(Color(hex: "#388E3C"))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CuponCard: View {
    let cupon: Cupon
    let puntosActuales: Int

    private var disponible: Bool { puntosActuales >= cupon.puntosRequeridos }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: cupon.iconoSF)
                .font(.title2)
                .foregroundStyle(disponible ? Color(hex: "#388E3C") : Color(.systemGray3))

            Text(cupon.titulo)
                .font(.subheadline.bold())
                .lineLimit(2)
            Text(cupon.descripcion)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(cupon.puntosRequeridos) pts")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(disponible ? Color(hex: "#E8F5E9") : Color(.systemGray6))
                .foregroundStyle(disponible ? Color(hex: "#388E3C") : .secondary)
                .clipShape(Capsule())
        }
        .padding()
        .frame(width: 160, height: 160)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4)
        .opacity(disponible ? 1.0 : 0.6)
    }
}

struct TicketRow: View {
    let ticket: DepositoTicket

    private var punto: PuntoAcopio? {
        MockDataService.shared.puntosAcopio.first { $0.id == ticket.puntoAcopioId }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ticket.verificado ? "checkmark.circle.fill" : "clock.fill")
                .foregroundStyle(ticket.verificado ? Color(hex: "#4CAF50") : Color(hex: "#F9A825"))
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(punto?.nombre ?? "Punto de acopio")
                    .font(.subheadline.bold())
                Text(ticket.timestamp, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(ticket.puntosOtorgados) pts")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "#388E3C"))
                Text("\(String(format: "%.1f", ticket.materiales.values.reduce(0, +))) kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    PerfilCiudadanoView()
}
