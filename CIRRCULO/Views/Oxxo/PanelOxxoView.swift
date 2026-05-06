import SwiftUI

struct PanelOxxoView: View {
    @EnvironmentObject var store: AppDataStore
    var onCambiarPerfil: (() -> Void)? = nil
    @State private var solicitudEnviada = false
    @State private var animado = false

    private var punto: PuntoAcopio { store.puntosAcopio[store.miOxxoIndex] }

    private var porcentajeTotal: Double { punto.porcentajeCapacidad }
    private var necesitaRecoleccion: Bool { porcentajeTotal > 0.6 }

    private var depositosHoy: [DepositoTicket] {
        store.historialDepositos.filter { $0.puntoAcopioId == punto.id }.prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header OXXO
                    OxxoHeader(punto: punto, depositosCount: depositosHoy.count, onCambiarPerfil: onCambiarPerfil)

                    VStack(spacing: 20) {
                        // Imagen de la tienda
                        if let imagenAsset = punto.imagenAsset {
                            Image(imagenAsset)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                                .padding(.horizontal, 20)
                        }

                        // Estado del contenedor de reciclaje
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(titulo: "Contenedor de reciclaje",
                                          icono: "arrow.3.trianglepath",
                                          color: Color(hex: "#D50000"))

                            VStack(spacing: 14) {
                                ForEach(Array(punto.materialDisponible.sorted(by: { $0.value > $1.value })), id: \.key) { material, kg in
                                    OxxoMaterialRow(
                                        material: material,
                                        kg: kg,
                                        capacidad: punto.capacidadTotal / Double(max(punto.materialDisponible.count, 1)),
                                        animado: animado
                                    )
                                }
                            }

                            // Barra total
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Capacidad total")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text("\(Int(porcentajeTotal * 100))%")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(porcentajeTotal > 0.7 ? Color(hex: "#D50000") : Color(hex: "#4CAF50"))
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(.systemGray6))
                                            .frame(height: 12)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                porcentajeTotal > 0.7
                                                    ? LinearGradient(colors: [Color(hex: "#FF5722"), Color(hex: "#D50000")], startPoint: .leading, endPoint: .trailing)
                                                    : LinearGradient(colors: [Color(hex: "#66BB6A"), Color(hex: "#4CAF50")], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .frame(width: animado ? geo.size.width * porcentajeTotal : 0, height: 12)
                                            .animation(.spring(response: 0.8).delay(0.2), value: animado)
                                    }
                                }
                                .frame(height: 12)
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                        }
                        .padding(.horizontal, 20)

                        // Botón solicitar recolección
                        Button {
                            store.solicitarRecoleccion(puntoAcopioId: punto.id)
                            withAnimation(.spring()) { solicitudEnviada = true }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: solicitudEnviada ? "checkmark.circle.fill" : "bicycle")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(solicitudEnviada ? "Recolector en camino" : "Solicitar recolector")
                                        .font(.headline)
                                    Text(solicitudEnviada ? "Un pepenador tomará tu solicitud pronto" : "Un pepenador pasará a recoger los materiales")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                if !solicitudEnviada {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .opacity(0.6)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                solicitudEnviada
                                    ? AnyShapeStyle(Color(hex: "#4CAF50"))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color(hex: "#FF5252"), Color(hex: "#D50000")],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: solicitudEnviada
                                    ? Color(hex: "#4CAF50").opacity(0.3)
                                    : Color(hex: "#D50000").opacity(0.35), radius: 8, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .disabled(solicitudEnviada)

                        // Promociones activas
                        if !punto.promociones.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(titulo: "Promociones activas",
                                              icono: "tag.fill",
                                              color: Color(hex: "#D50000"))

                                VStack(spacing: 8) {
                                    ForEach(punto.promociones, id: \.self) { promo in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "gift.fill")
                                                .font(.caption)
                                                .foregroundStyle(Color(hex: "#D50000"))
                                                .frame(width: 20)
                                            Text(promo)
                                                .font(.subheadline)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: "#FFF8E1"))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Depósitos recientes
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(titulo: "Depósitos recientes",
                                          icono: "clock.badge.checkmark.fill",
                                          color: Color(hex: "#D50000"))

                            VStack(spacing: 0) {
                                let depositos = Array(depositosHoy.prefix(5))
                                ForEach(Array(depositos.enumerated()), id: \.offset) { idx, ticket in
                                    OxxoDepositoRow(ticket: ticket)
                                    if idx < depositos.count - 1 {
                                        Divider().padding(.horizontal, 16)
                                    }
                                }
                                if depositos.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "tray")
                                            .font(.title)
                                            .foregroundStyle(.secondary)
                                        Text("Sin depósitos recientes")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(24)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        }
                        .padding(.horizontal, 20)

                        // Mensaje de impacto
                        HStack(spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .font(.title2)
                                .foregroundStyle(Color(hex: "#2E7D32"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Impacto de tu OXXO")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color(hex: "#1B5E20"))
                                let kgTotal = punto.materialDisponible.values.reduce(0, +)
                                Text("Has recolectado \(String(format: "%.1f", kgTotal)) kg de material reciclable este mes")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "#2E7D32"))
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "#E8F5E9"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 20)
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

struct OxxoHeader: View {
    let punto: PuntoAcopio
    var depositosCount: Int = 0
    var onCambiarPerfil: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#B71C1C"), Color(hex: "#D50000"), Color(hex: "#FF1744")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 130, y: -30)
            Circle().fill(.white.opacity(0.04)).frame(width: 140).offset(x: -70, y: 25)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mi Tienda OXXO")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(punto.nombre)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "storefront.fill")
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
                    PanelStat(valor: "\(depositosCount)", label: "depósitos")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    PanelStat(valor: "\(String(format: "%.0f", punto.capacidadTotal)) kg", label: "capacidad")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    PanelStat(valor: "\(Int(punto.porcentajeCapacidad * 100))%", label: "lleno")
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

// MARK: - Material Row

struct OxxoMaterialRow: View {
    let material: String
    let kg: Double
    let capacidad: Double
    let animado: Bool

    private var porcentaje: Double { min(kg / capacidad, 1.0) }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: iconoMaterial)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#D50000"))
                        .frame(width: 20)
                    Text(material)
                        .font(.subheadline.bold())
                }
                Spacer()
                Text("\(String(format: "%.1f", kg)) kg")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "#D50000"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#D50000").opacity(0.7))
                        .frame(width: animado ? geo.size.width * porcentaje : 0, height: 6)
                        .animation(.spring(response: 0.8).delay(0.1), value: animado)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private var iconoMaterial: String {
        switch material {
        case "Plástico PET": return "waterbottle"
        case "Aluminio":     return "cylinder"
        case "Cartón":       return "shippingbox"
        default:             return "arrow.3.trianglepath"
        }
    }
}

// MARK: - Deposito Row

struct OxxoDepositoRow: View {
    let ticket: DepositoTicket

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ticket.verificado ? Color(hex: "#FFEBEE") : Color(hex: "#FFF8E1"))
                    .frame(width: 42, height: 42)
                Image(systemName: ticket.verificado ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ticket.verificado ? Color(hex: "#D50000") : Color(hex: "#F9A825"))
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
                .foregroundStyle(Color(hex: "#D50000"))
        }
        .padding(16)
    }
}

#Preview {
    PanelOxxoView()
        .environmentObject(AppDataStore())
}
