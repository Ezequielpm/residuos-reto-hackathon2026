import SwiftUI

struct PanelContenedoresView: View {
    @EnvironmentObject var store: AppDataStore
    var onCambiarPerfil: (() -> Void)? = nil
    @State private var solicitudEnviada = false
    @State private var animado = false

    private var punto: PuntoAcopio { store.puntosAcopio[store.miPuntoAcopioIndex] }

    /// Calcula porcentaje por contenedor sumando los materiales que corresponden
    private var porcentajeVerde: Double {
        let organicos = ["Orgánico - comida", "Orgánico - poda"]
        let kgOrganicos = punto.materialDisponible.filter { organicos.contains($0.key) }.values.reduce(0, +)
        return min(kgOrganicos / (punto.capacidadTotal * 0.33), 1.0)
    }

    private var porcentajeGris: Double {
        let organicos = ["Orgánico - comida", "Orgánico - poda"]
        let noReciclables = ["No reciclable", "Electrónico", "Textil"]
        let kgReciclables = punto.materialDisponible
            .filter { !organicos.contains($0.key) && !noReciclables.contains($0.key) }
            .values.reduce(0, +)
        return min(kgReciclables / (punto.capacidadTotal * 0.5), 1.0)
    }

    private var porcentajeNaranja: Double {
        let noReciclables = ["No reciclable", "Electrónico", "Textil"]
        let kgNoReciclables = punto.materialDisponible.filter { noReciclables.contains($0.key) }.values.reduce(0, +)
        return min(kgNoReciclables / (punto.capacidadTotal * 0.17), 1.0)
    }

    private var necesitaRecoleccion: Bool { porcentajeGris > 0.7 || porcentajeVerde > 0.7 }
    private var depositosHoy: [DepositoTicket] {
        store.historialDepositos.filter { $0.puntoAcopioId == punto.id }.prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    PanelContenedoresHeader(punto: punto, depositosCount: depositosHoy.count, onCambiarPerfil: onCambiarPerfil)

                    VStack(spacing: 20) {
                        // Contenedores
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(titulo: "Estado de contenedores",
                                          icono: "trash.fill",
                                          color: Color(hex: "#6A1B9A"))

                            VStack(spacing: 14) {
                                ContenedorCard(
                                    nombre: "Verde — Orgánicos",
                                    porcentaje: porcentajeVerde,
                                    color: Color(hex: "#4CAF50"),
                                    dias: "Mar, Jue, Sáb",
                                    animado: animado
                                )
                                ContenedorCard(
                                    nombre: "Gris — Reciclables",
                                    porcentaje: porcentajeGris,
                                    color: Color(hex: "#607D8B"),
                                    dias: "Lun, Mié, Vie, Dom",
                                    animado: animado
                                )
                                ContenedorCard(
                                    nombre: "Naranja — No reciclables",
                                    porcentaje: porcentajeNaranja,
                                    color: Color(hex: "#FF5722"),
                                    dias: "Lun, Mié, Vie, Dom",
                                    animado: animado
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // Alerta recolección
                        if necesitaRecoleccion {
                            Button {
                                store.solicitarRecoleccion(puntoAcopioId: punto.id)
                                withAnimation(.spring()) { solicitudEnviada = true }
                            } label: {
                                HStack {
                                    Image(systemName: solicitudEnviada ? "checkmark.circle.fill" : "bell.badge.fill")
                                    Text(solicitudEnviada ? "Solicitud enviada" : "Solicitar recolección")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    solicitudEnviada
                                        ? AnyShapeStyle(Color(hex: "#4CAF50"))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [Color(hex: "#AB47BC"), Color(hex: "#6A1B9A")],
                                            startPoint: .leading, endPoint: .trailing
                                        ))
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: solicitudEnviada
                                        ? Color(hex: "#4CAF50").opacity(0.3)
                                        : Color(hex: "#6A1B9A").opacity(0.35), radius: 8, y: 4)
                            }
                            .padding(.horizontal, 20)
                            .disabled(solicitudEnviada)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Depósitos de hoy
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(titulo: "Depósitos de hoy",
                                          icono: "clock.badge.checkmark.fill",
                                          color: Color(hex: "#6A1B9A"))

                            VStack(spacing: 0) {
                                let depositos = Array(depositosHoy.prefix(5))
                                ForEach(Array(depositos.enumerated()), id: \.offset) { idx, ticket in
                                    DepositoHoyRow(ticket: ticket)
                                    if idx < depositos.count - 1 {
                                        Divider().padding(.horizontal, 16)
                                    }
                                }
                                if depositos.isEmpty {
                                    Text("Sin depósitos hoy")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(20)
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .onAppear {
                withAnimation { animado = true }
            }
        }
    }
}

// MARK: - Header

struct PanelContenedoresHeader: View {
    let punto: PuntoAcopio
    var depositosCount: Int = 0
    var onCambiarPerfil: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#4A148C"), Color(hex: "#6A1B9A"), Color(hex: "#7B1FA2")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 130, y: -30)
            Circle().fill(.white.opacity(0.04)).frame(width: 140).offset(x: -70, y: 25)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Panel de Acopio")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(punto.nombre)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
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

                HStack(spacing: 0) {
                    PanelStat(valor: "3", label: "contenedores")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    PanelStat(valor: "\(depositosCount)", label: "depósitos hoy")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    PanelStat(valor: "\(String(format: "%.0f", punto.capacidadTotal)) kg", label: "capacidad")
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

struct PanelStat: View {
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

// MARK: - Contenedor Card

struct ContenedorCard: View {
    let nombre: String
    let porcentaje: Double
    let color: Color
    let dias: String
    let animado: Bool

    private var alerta: Bool { porcentaje > 0.7 }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Circle().fill(color).frame(width: 12, height: 12)
                    Text(nombre).font(.subheadline.bold())
                }
                Spacer()
                Text(String(format: "%.0f%%", porcentaje * 100))
                    .font(.headline.bold())
                    .foregroundStyle(alerta ? Color(hex: "#FF5722") : color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background((alerta ? Color(hex: "#FF5722") : color).opacity(0.12))
                    .clipShape(Capsule())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(alerta
                              ? LinearGradient(colors: [Color(hex: "#FF5722"), Color(hex: "#D32F2F")],
                                               startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [color.opacity(0.7), color],
                                               startPoint: .leading, endPoint: .trailing))
                        .frame(width: animado ? geo.size.width * porcentaje : 0, height: 10)
                        .animation(.spring(response: 0.8).delay(0.2), value: animado)
                }
            }
            .frame(height: 10)

            HStack {
                Label(dias, systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if alerta {
                    Label("Lleno — solicitar recolección", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(Color(hex: "#FF5722"))
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Depósito Row

struct DepositoHoyRow: View {
    let ticket: DepositoTicket

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ticket.verificado ? Color(hex: "#E8F5E9") : Color(hex: "#FFF8E1"))
                    .frame(width: 42, height: 42)
                Image(systemName: ticket.verificado ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ticket.verificado ? Color(hex: "#4CAF50") : Color(hex: "#F9A825"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Ciudadano verificado")
                    .font(.subheadline.bold())
                Text(ticket.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(String(format: "%.1f", ticket.materiales.values.reduce(0, +))) kg")
                .font(.subheadline.bold())
                .foregroundStyle(Color(hex: "#6A1B9A"))
        }
        .padding(16)
    }
}

#Preview {
    PanelContenedoresView()
        .environmentObject(AppDataStore())
}
