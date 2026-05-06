import SwiftUI

struct PerfilCiudadanoView: View {
    @EnvironmentObject var store: AppDataStore
    var onCambiarPerfil: (() -> Void)? = nil

    private var historial: [DepositoTicket] { store.misDepositos }
    private var cupones: [Cupon] { store.cupones }

    private var totalPuntos: Int { store.totalPuntosCiudadano }
    private var totalKg: Double { store.totalKgCiudadano }
    private var co2Evitado: Double { totalKg * 2.5 }

    private var rachaActual: Int {
        let cal = Calendar.current
        let depositDays = Set(historial.map { cal.startOfDay(for: $0.timestamp) })
        guard let mostRecent = depositDays.max() else { return 0 }
        var racha = 0
        var checkDate = mostRecent
        while depositDays.contains(checkDate) {
            racha += 1
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return racha
    }

    private var kgPorMaterial: [(TipoResiduo, Double)] {
        var dict: [TipoResiduo: Double] = [:]
        for ticket in historial {
            for (tipo, kg) in ticket.materiales {
                dict[tipo, default: 0] += kg
            }
        }
        return dict.sorted { $0.value > $1.value }
    }

    private let niveles: [(nombre: String, icono: String, minPts: Int)] = [
        ("Reciclador Inicial", "leaf.fill", 0),
        ("Reciclador Activo", "person.badge.checkmark.fill", 500),
        ("Eco Guardián", "shield.fill", 1500),
        ("Héroe Circular", "star.fill", 3000)
    ]

    private var nivelIndex: Int {
        niveles.lastIndex(where: { totalPuntos >= $0.minPts }) ?? 0
    }
    private var nivelActual: (nombre: String, icono: String, minPts: Int) { niveles[nivelIndex] }
    private var siguienteNivel: (nombre: String, icono: String, minPts: Int)? {
        nivelIndex < niveles.count - 1 ? niveles[nivelIndex + 1] : nil
    }
    private var progresoNivel: Double {
        let base = nivelActual.minPts
        let tope = siguienteNivel?.minPts ?? (base + 500)
        return min(1.0, Double(totalPuntos - base) / Double(tope - base))
    }
    private var puntosParaSiguiente: Int {
        guard let siguiente = siguienteNivel else { return 0 }
        return max(0, siguiente.minPts - totalPuntos)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HeaderPerfilCiudadano(
                        nombreUsuario: store.currentUserName,
                        puntos: totalPuntos,
                        kg: totalKg,
                        co2: co2Evitado,
                        racha: rachaActual,
                        nivelNombre: nivelActual.nombre,
                        nivelIcono: nivelActual.icono,
                        progresoNivel: progresoNivel,
                        puntosParaSiguiente: puntosParaSiguiente,
                        onCambiarPerfil: onCambiarPerfil
                    )

                    VStack(spacing: 28) {
                        ImpactoSection(kg: totalKg, co2: co2Evitado, racha: rachaActual)

                        if !kgPorMaterial.isEmpty {
                            MaterialesSection(materiales: kgPorMaterial)
                        }

                        CuponesSection(cupones: cupones, puntosActuales: totalPuntos, puntosParaSiguiente: puntosParaSiguiente)

                        HistorialCiudadanoSection(historial: historial)
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 44)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Header

struct HeaderPerfilCiudadano: View {
    let nombreUsuario: String
    let puntos: Int
    let kg: Double
    let co2: Double
    let racha: Int
    let nivelNombre: String
    let nivelIcono: String
    let progresoNivel: Double
    let puntosParaSiguiente: Int
    var onCambiarPerfil: (() -> Void)? = nil

    @State private var animado = false
    @State private var puntosDouble: Double = 0
    @State private var ringProgress: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#1B5E20"), Color(hex: "#2E7D32"), Color(hex: "#388E3C")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            Circle().fill(.white.opacity(0.05)).frame(width: 260).offset(x: 140, y: -50)
            Circle().fill(.white.opacity(0.04)).frame(width: 180).offset(x: -90, y: 30)
            Circle().fill(.white.opacity(0.03)).frame(width: 120).offset(x: 60, y: -100)

            VStack(spacing: 0) {
                // Top bar: nivel + cambiar perfil
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: nivelIcono)
                            .font(.caption2.bold())
                        Text(nivelNombre)
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())

                    Spacer()

                    if let onCambiarPerfil {
                        Button(action: onCambiarPerfil) {
                            HStack(spacing: 5) {
                                Image(systemName: "rectangle.portrait.and.arrow.right").font(.caption.bold())
                                Text("Salir").font(.caption.bold())
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.bottom, 22)

                // Avatar con anillo de progreso
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.15), lineWidth: 5)
                        .frame(width: 88, height: 88)
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#69F0AE"), Color(hex: "#00E676")],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Text(String(nombreUsuario.prefix(1)).uppercased())
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 8)

                Text(nombreUsuario)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.bottom, 12)

                // Puntos animados
                VStack(spacing: 2) {
                    Text("\(Int(puntosDouble))")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .scaleEffect(animado ? 1 : 0.7)
                    Text("puntos acumulados")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.bottom, 14)

                // Barra de progreso al siguiente nivel
                VStack(spacing: 5) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.2)).frame(height: 6)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#69F0AE"), Color(hex: "#00E676")],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * ringProgress, height: 6)
                        }
                    }
                    .frame(height: 6)
                    HStack {
                        Text(nivelNombre)
                            .font(.caption2).foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        if puntosParaSiguiente > 0 {
                            Text("Faltan \(puntosParaSiguiente) pts")
                                .font(.caption2.bold()).foregroundStyle(.white.opacity(0.75))
                        } else {
                            Text("Nivel máximo").font(.caption2.bold()).foregroundStyle(.white.opacity(0.75))
                        }
                    }
                }
                .padding(.bottom, 18)

                // Stats row
                HStack(spacing: 0) {
                    StatBadgeCiudadano(valor: String(format: "%.1f kg", kg), label: "reciclados")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    StatBadgeCiudadano(valor: String(format: "%.1f kg", co2), label: "CO₂ evitados")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    StatBadgeCiudadano(
                        valor: "\(racha) día\(racha == 1 ? "" : "s")",
                        label: racha >= 7 ? "racha 🔥🔥" : "racha 🔥"
                    )
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) { animado = true }
            withAnimation(.easeOut(duration: 1.4).delay(0.4)) { puntosDouble = Double(puntos) }
            withAnimation(.easeOut(duration: 1.2).delay(0.6)) { ringProgress = progresoNivel }
        }
    }
}

struct StatBadgeCiudadano: View {
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

// MARK: - Sección Impacto

struct ImpactoSection: View {
    let kg: Double
    let co2: Double
    let racha: Int

    private var botellasEquivalentes: Int { Int(kg / 0.025) }

    var body: some View {
        VStack(spacing: 14) {
            SectionHeaderCiudadano(titulo: "Tu impacto real", icono: "leaf.fill", color: Color(hex: "#2E7D32"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ImpactoCard(
                    valor: String(format: "%.1f", co2), unidad: "kg",
                    label: "CO₂ evitados",
                    icono: "smoke.fill", color: Color(hex: "#2E7D32")
                )
                ImpactoCard(
                    valor: String(format: "%.1f", kg), unidad: "kg",
                    label: "material reciclado",
                    icono: "arrow.3.trianglepath", color: Color(hex: "#1565C0")
                )
                ImpactoCard(
                    valor: "\(botellasEquivalentes)", unidad: "",
                    label: "botellas equivalentes",
                    icono: "waterbottle.fill", color: Color(hex: "#00838F")
                )
                ImpactoCard(
                    valor: "\(racha)", unidad: racha == 1 ? "día" : "días",
                    label: "racha activa",
                    icono: "flame.fill", color: Color(hex: "#E65100")
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ImpactoCard: View {
    let valor: String
    let unidad: String
    let label: String
    let icono: String
    let color: Color
    @State private var visible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icono)
                    .font(.system(size: 19))
                    .foregroundStyle(color)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(valor)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.primary)
                if !unidad.isEmpty {
                    Text(unidad)
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        .scaleEffect(visible ? 1 : 0.92)
        .opacity(visible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double.random(in: 0.05...0.25))) {
                visible = true
            }
        }
    }
}

// MARK: - Sección Materiales

struct MaterialesSection: View {
    let materiales: [(TipoResiduo, Double)]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeaderCiudadano(titulo: "Por material este mes", icono: "chart.bar.fill", color: Color(hex: "#2E7D32"))

            VStack(spacing: 0) {
                let top = Array(materiales.prefix(5))
                let maxKg = top.first?.1 ?? 1.0
                ForEach(Array(top.enumerated()), id: \.1.0) { idx, entry in
                    MaterialFilaRow(tipo: entry.0, kg: entry.1, maxKg: maxKg)
                    if idx < top.count - 1 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
            .padding(.horizontal, 20)
        }
    }
}

struct MaterialFilaRow: View {
    let tipo: TipoResiduo
    let kg: Double
    let maxKg: Double
    @State private var progreso: Double = 0

    private var colorContenedor: Color {
        switch tipo.contenedor {
        case .verde:   return Color(hex: "#4CAF50")
        case .gris:    return Color(hex: "#607D8B")
        case .naranja: return Color(hex: "#FF5722")
        }
    }

    private var iconoSF: String {
        switch tipo {
        case .plasticoPET:    return "waterbottle.fill"
        case .plasticoHDPE:   return "shippingbox.fill"
        case .carton:         return "doc.fill"
        case .papel:          return "doc.plaintext.fill"
        case .vidrio:         return "wineglass.fill"
        case .aluminio:       return "cylinder.fill"
        case .lata:           return "cylinder.fill"
        case .organicoComida: return "leaf.fill"
        case .organicoPoda:   return "tree.fill"
        case .electronico:    return "bolt.fill"
        case .textil:         return "tshirt.fill"
        case .noReciclable:   return "trash.fill"
        case .tetraPak:       return "cube.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(colorContenedor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: iconoSF)
                    .font(.system(size: 15))
                    .foregroundStyle(colorContenedor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(tipo.rawValue)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "%.1f kg", kg))
                        .font(.caption.bold())
                        .foregroundStyle(colorContenedor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5)).frame(height: 5)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [colorContenedor.opacity(0.6), colorContenedor],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * progreso, height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.15)) {
                progreso = min(1.0, kg / maxKg)
            }
        }
    }
}

// MARK: - Sección Cupones

struct CuponesSection: View {
    let cupones: [Cupon]
    let puntosActuales: Int
    let puntosParaSiguiente: Int

    private var siguienteCupon: Cupon? {
        cupones.filter { !$0.canjeado && $0.puntosRequeridos > puntosActuales }
            .min(by: { $0.puntosRequeridos < $1.puntosRequeridos })
    }

    var body: some View {
        VStack(spacing: 14) {
            SectionHeaderCiudadano(titulo: "Tus recompensas", icono: "ticket.fill", color: Color(hex: "#2E7D32"))

            if let siguiente = siguienteCupon {
                ProximaRecompensaBanner(cupon: siguiente, puntosActuales: puntosActuales)
                    .padding(.horizontal, 20)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(cupones) { cupon in
                        CuponCardV2(cupon: cupon, puntosActuales: puntosActuales)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct ProximaRecompensaBanner: View {
    let cupon: Cupon
    let puntosActuales: Int
    @State private var barraAnimada: Double = 0

    private var progreso: Double { min(1.0, Double(puntosActuales) / Double(cupon.puntosRequeridos)) }
    private var faltan: Int { max(0, cupon.puntosRequeridos - puntosActuales) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 46, height: 46)
                Image(systemName: cupon.iconoSF)
                    .font(.title3)
                    .foregroundStyle(Color(hex: "#2E7D32"))
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Próxima: \(cupon.titulo)")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    Text("Faltan \(faltan) pts")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "#2E7D32"))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5)).frame(height: 6)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(hex: "#81C784"), Color(hex: "#2E7D32")],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * barraAnimada, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                barraAnimada = progreso
            }
        }
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
                    .frame(width: 42, height: 42)
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
                    .lineLimit(2)
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
        .frame(width: 172, height: 178)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(disponible ? 0.08 : 0.04), radius: 8, y: 3)
        .opacity(disponible ? 1 : 0.65)
    }
}

// MARK: - Historial

struct HistorialCiudadanoSection: View {
    let historial: [DepositoTicket]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeaderCiudadano(titulo: "Depósitos recientes", icono: "clock.arrow.circlepath", color: Color(hex: "#2E7D32"))

            VStack(spacing: 1) {
                ForEach(historial.sorted(by: { $0.timestamp > $1.timestamp })) { ticket in
                    TicketRowMejorado(ticket: ticket)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            .padding(.horizontal, 20)
        }
    }
}

struct TicketRowMejorado: View {
    let ticket: DepositoTicket
    @EnvironmentObject var store: AppDataStore
    private var punto: PuntoAcopio? {
        store.puntosAcopio.first { $0.id == ticket.puntoAcopioId }
    }
    private var kgTotal: Double { ticket.materiales.values.reduce(0, +) }
    private var materialesPrincipales: [TipoResiduo] {
        ticket.materiales.sorted { $0.value > $1.value }.prefix(2).map { $0.key }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ticket.verificado ? Color(hex: "#E8F5E9") : Color(hex: "#FFF8E1"))
                    .frame(width: 42, height: 42)
                Image(systemName: ticket.verificado ? "checkmark.seal.fill" : "clock.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(ticket.verificado ? Color(hex: "#2E7D32") : Color(hex: "#F9A825"))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(punto?.nombre ?? "Punto de acopio")
                    .font(.subheadline.bold())
                    .lineLimit(1)

                HStack(spacing: 5) {
                    ForEach(materialesPrincipales, id: \.self) { tipo in
                        Text(tipo.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(colorContenedor(tipo).opacity(0.12))
                            .foregroundStyle(colorContenedor(tipo))
                            .clipShape(Capsule())
                    }
                    Text(ticket.timestamp, format: .dateTime.day().month())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(ticket.puntosOtorgados)")
                    .font(.headline.bold())
                    .foregroundStyle(Color(hex: "#2E7D32"))
                Text("pts")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f kg", kgTotal))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }

    private func colorContenedor(_ tipo: TipoResiduo) -> Color {
        switch tipo.contenedor {
        case .verde:   return Color(hex: "#4CAF50")
        case .gris:    return Color(hex: "#607D8B")
        case .naranja: return Color(hex: "#FF5722")
        }
    }
}

// MARK: - Shared helpers (used across multiple views)

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

typealias SectionHeaderCiudadano = SectionHeader

#Preview { PerfilCiudadanoView().environmentObject(AppDataStore()) }
