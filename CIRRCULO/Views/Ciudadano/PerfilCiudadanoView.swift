import SwiftUI

struct PerfilCiudadanoView: View {
    var onCambiarPerfil: (() -> Void)? = nil
    @State private var historial = MockDataService.shared.historialDepositos
    @State private var cupones = MockDataService.shared.cupones

    private var totalPuntos: Int { historial.reduce(0) { $0 + $1.puntosOtorgados } }
    private var totalKg: Double { historial.flatMap { $0.materiales.values }.reduce(0, +) }
    private var co2Evitado: Double { totalKg * 2.5 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header con gradiente
                    HeaderPerfil(puntos: totalPuntos, kg: totalKg, co2: co2Evitado, onCambiarPerfil: onCambiarPerfil)

                    VStack(spacing: 20) {
                        // Cupones
                        SectionHeader(titulo: "Tus cupones", icono: "ticket.fill", color: Color(hex: "#2E7D32"))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(cupones) { cupon in
                                    CuponCardV2(cupon: cupon, puntosActuales: totalPuntos)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Historial
                        SectionHeader(titulo: "Historial de depósitos", icono: "clock.arrow.circlepath", color: Color(hex: "#2E7D32"))
                            .padding(.horizontal, 20)

                        VStack(spacing: 1) {
                            ForEach(historial.sorted(by: { $0.timestamp > $1.timestamp })) { ticket in
                                TicketRowV2(ticket: ticket)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
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

// MARK: - Header

struct HeaderPerfil: View {
    let puntos: Int
    let kg: Double
    let co2: Double
    var onCambiarPerfil: (() -> Void)? = nil
    @State private var animado = false

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#1B5E20"), Color(hex: "#2E7D32")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // Círculos decorativos
            Circle().fill(.white.opacity(0.06)).frame(width: 220).offset(x: 130, y: -60)
            Circle().fill(.white.opacity(0.04)).frame(width: 160).offset(x: -80, y: 20)

            VStack(spacing: 20) {
                // Botón cambiar perfil
                HStack {
                    Spacer()
                    if let onCambiarPerfil {
                        Button(action: onCambiarPerfil) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.2.circlepath")
                                    .font(.caption.bold())
                                Text("Cambiar perfil")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }

                // Avatar
                ZStack {
                    Circle().fill(.white.opacity(0.15)).frame(width: 72, height: 72)
                    Image(systemName: "person.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                }

                // Puntos
                VStack(spacing: 4) {
                    Text("\(puntos)")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(.white)
                        .scaleEffect(animado ? 1 : 0.7)
                    Text("puntos acumulados")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Stats row
                HStack(spacing: 0) {
                    StatBadge(valor: String(format: "%.1f kg", kg), label: "reciclados")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    StatBadge(valor: String(format: "%.1f kg", co2), label: "CO₂ evitados")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    StatBadge(valor: "7 días", label: "racha activa 🔥")
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animado = true
            }
        }
    }
}

struct StatBadge: View {
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

// MARK: - Section Header

struct SectionHeader: View {
    let titulo: String
    let icono: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icono).font(.subheadline).foregroundStyle(color)
            Text(titulo).font(.headline)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Cupón Card V2

struct CuponCardV2: View {
    let cupon: Cupon
    let puntosActuales: Int
    private var disponible: Bool { puntosActuales >= cupon.puntosRequeridos }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(disponible ? Color(hex: "#E8F5E9") : Color(.systemGray6))
                    .frame(width: 40, height: 40)
                Image(systemName: cupon.iconoSF)
                    .font(.title3)
                    .foregroundStyle(disponible ? Color(hex: "#2E7D32") : Color(.systemGray3))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(cupon.titulo)
                    .font(.subheadline.bold())
                    .foregroundStyle(disponible ? .primary : .secondary)
                    .lineLimit(2)
                Text(cupon.descripcion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(disponible ? Color(hex: "#F9A825") : Color(.systemGray4))
                Text("\(cupon.puntosRequeridos) pts")
                    .font(.caption.bold())
                    .foregroundStyle(disponible ? Color(hex: "#2E7D32") : .secondary)
                Spacer()
                if disponible {
                    Text("Canjear")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#2E7D32"))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .frame(width: 168, height: 170)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(disponible ? 0.08 : 0.04), radius: 8, y: 3)
        .opacity(disponible ? 1 : 0.65)
    }
}

// MARK: - Ticket Row V2

struct TicketRowV2: View {
    let ticket: DepositoTicket
    private var punto: PuntoAcopio? {
        MockDataService.shared.puntosAcopio.first { $0.id == ticket.puntoAcopioId }
    }
    private var kgTotal: Double { ticket.materiales.values.reduce(0, +) }
    private var colorContenedor: Color {
        let tipo = ticket.materiales.keys.first ?? .noReciclable
        switch tipo.contenedor {
        case .verde: return Color(hex: "#4CAF50")
        case .gris: return Color(hex: "#607D8B")
        case .naranja: return Color(hex: "#FF5722")
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Indicador de color
            RoundedRectangle(cornerRadius: 3)
                .fill(ticket.verificado ? Color(hex: "#4CAF50") : Color(hex: "#F9A825"))
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(punto?.nombre ?? "Punto de acopio")
                    .font(.subheadline.bold())
                Text(ticket.timestamp, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("+\(ticket.puntosOtorgados) pts")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "#2E7D32"))
                Text(String(format: "%.1f kg", kgTotal))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }
}

#Preview { PerfilCiudadanoView() }
