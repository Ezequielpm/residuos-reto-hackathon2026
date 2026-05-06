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
                        nivelNombre: nivelActual.nombre,
                        nivelIcono: nivelActual.icono,
                        progresoNivel: progresoNivel,
                        puntosParaSiguiente: puntosParaSiguiente,
                        onCambiarPerfil: onCambiarPerfil
                    )

                    VStack(spacing: 24) {
                        // Wallet — única fuente de puntos
                        WalletSection(puntos: totalPuntos)

                        // Recompensas
                        RecompensasWalletSection(cupones: cupones, puntosActuales: totalPuntos)

                        // Impacto — única fuente de kg/CO2/racha
                        ImpactoSection(kg: totalKg, co2: co2Evitado, racha: rachaActual)

                        if !kgPorMaterial.isEmpty {
                            MaterialesSection(materiales: kgPorMaterial)
                        }

                        HistorialCiudadanoSection(historial: historial)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 44)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Header (compacto: perfil + nivel, sin datos repetidos)

struct HeaderPerfilCiudadano: View {
    let nombreUsuario: String
    let nivelNombre: String
    let nivelIcono: String
    let progresoNivel: Double
    let puntosParaSiguiente: Int
    var onCambiarPerfil: (() -> Void)? = nil

    @State private var ringProgress: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#1B5E20"), Color(hex: "#2E7D32"), Color(hex: "#388E3C")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            Circle().fill(.white.opacity(0.05)).frame(width: 260).offset(x: 140, y: -50)
            Circle().fill(.white.opacity(0.04)).frame(width: 180).offset(x: -90, y: 30)

            VStack(spacing: 0) {
                // Top bar: nivel + salir
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
                .padding(.bottom, 18)

                // Avatar + nombre + progreso de nivel
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 4)
                            .frame(width: 72, height: 72)
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#69F0AE"), Color(hex: "#00E676")],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 72, height: 72)
                            .rotationEffect(.degrees(-90))
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 58, height: 58)
                        Text(String(nombreUsuario.prefix(1)).uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(nombreUsuario)
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        // Barra de progreso al siguiente nivel
                        VStack(alignment: .leading, spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.white.opacity(0.2)).frame(height: 5)
                                    Capsule()
                                        .fill(LinearGradient(
                                            colors: [Color(hex: "#69F0AE"), Color(hex: "#00E676")],
                                            startPoint: .leading, endPoint: .trailing
                                        ))
                                        .frame(width: geo.size.width * ringProgress, height: 5)
                                }
                            }
                            .frame(height: 5)

                            if puntosParaSiguiente > 0 {
                                Text("\(puntosParaSiguiente) pts para siguiente nivel")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.65))
                            } else {
                                Text("Nivel máximo alcanzado")
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: "#69F0AE"))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 24)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) { ringProgress = progresoNivel }
        }
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

// MARK: - Wallet Section (tarjeta hero de saldo)

struct WalletSection: View {
    let puntos: Int
    @State private var shimmer = false

    private var recompensasCerca: String {
        if puntos >= 2500 { return "9 recompensas disponibles" }
        if puntos >= 1200 { return "7 recompensas disponibles" }
        if puntos >= 500 { return "3 recompensas disponibles" }
        if puntos >= 150 { return "1 recompensa disponible" }
        return "Sigue reciclando para desbloquear"
    }

    var body: some View {
        VStack(spacing: 14) {
            SectionHeaderCiudadano(titulo: "Tu wallet", icono: "wallet.bifold.fill", color: Color(hex: "#2E7D32"))

            ZStack {
                // Fondo de tarjeta con gradiente
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#1B5E20"), Color(hex: "#2E7D32"), Color(hex: "#43A047")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                // Efecto shimmer sutil
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.08), .clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: shimmer ? 300 : -300)

                // Círculos decorativos
                Circle().fill(.white.opacity(0.06)).frame(width: 150).offset(x: 120, y: -40)
                Circle().fill(.white.opacity(0.04)).frame(width: 100).offset(x: -100, y: 30)

                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tus puntos")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(puntos)")
                                    .font(.system(size: 40, weight: .black))
                                    .foregroundStyle(.white)
                                Text("pts")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(0.3))
                            Text("Nexia")
                                .font(.caption2.bold())
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(2)
                        }
                    }

                    Spacer()

                    // Barra inferior
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(Color(hex: "#69F0AE"))
                            Text(recompensasCerca)
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
            }
            .frame(height: 175)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color(hex: "#1B5E20").opacity(0.35), radius: 16, y: 8)
            .padding(.horizontal, 20)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmer = true
                }
            }
        }
    }
}

// MARK: - Recompensas Wallet Section

struct RecompensasWalletSection: View {
    let cupones: [Cupon]
    let puntosActuales: Int

    @State private var categoriaSeleccionada: CuponCategoria? = nil

    private var cuponesFiltrados: [Cupon] {
        if let cat = categoriaSeleccionada {
            return cupones.filter { $0.categoria == cat }
        }
        return cupones
    }

    private var disponibles: [Cupon] {
        cuponesFiltrados.filter { puntosActuales >= $0.puntosRequeridos && !$0.canjeado }
    }
    private var proximamente: [Cupon] {
        cuponesFiltrados.filter { puntosActuales < $0.puntosRequeridos }
            .sorted { $0.puntosRequeridos < $1.puntosRequeridos }
    }

    var body: some View {
        VStack(spacing: 16) {
            SectionHeaderCiudadano(titulo: "Canjear recompensas", icono: "gift.fill", color: Color(hex: "#2E7D32"))

            // Filtros de categoría
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(titulo: "Todas", seleccionado: categoriaSeleccionada == nil) {
                        withAnimation(.spring(response: 0.3)) { categoriaSeleccionada = nil }
                    }
                    ForEach(CuponCategoria.allCases, id: \.self) { cat in
                        FilterChip(titulo: cat.rawValue, seleccionado: categoriaSeleccionada == cat) {
                            withAnimation(.spring(response: 0.3)) { categoriaSeleccionada = cat }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // Disponibles para canjear
            if !disponibles.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "#00E676")).frame(width: 8, height: 8)
                        Text("Disponibles ahora")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(disponibles) { cupon in
                                RecompensaCard(cupon: cupon, puntosActuales: puntosActuales)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            // Próximamente
            if !proximamente.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Circle().fill(Color(.systemGray4)).frame(width: 8, height: 8)
                        Text("Sigue reciclando para desbloquear")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(proximamente) { cupon in
                                RecompensaCard(cupon: cupon, puntosActuales: puntosActuales)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let titulo: String
    let seleccionado: Bool
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Text(titulo)
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(seleccionado ? Color(hex: "#2E7D32") : Color(.systemGray6))
                .foregroundStyle(seleccionado ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Recompensa Card (tipo wallet / ticket)

struct RecompensaCard: View {
    let cupon: Cupon
    let puntosActuales: Int
    @State private var aparecer = false

    private var disponible: Bool { puntosActuales >= cupon.puntosRequeridos }
    private var progreso: Double {
        guard !disponible else { return 1.0 }
        return Double(puntosActuales) / Double(cupon.puntosRequeridos)
    }
    private var faltan: Int { max(0, cupon.puntosRequeridos - puntosActuales) }
    private var marcaColor: Color { Color(hex: cupon.colorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header con marca y valor
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cupon.marca.uppercased())
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(marcaColor)
                        .tracking(1.2)
                    Text(cupon.valorTexto)
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(disponible ? .primary : .secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(marcaColor.opacity(disponible ? 0.15 : 0.08))
                        .frame(width: 44, height: 44)
                    Image(systemName: cupon.iconoSF)
                        .font(.system(size: 20))
                        .foregroundStyle(disponible ? marcaColor : Color(.systemGray3))
                }
            }
            .padding(.bottom, 10)

            // Título
            Text(cupon.titulo)
                .font(.subheadline.bold())
                .foregroundStyle(disponible ? .primary : .secondary)
                .lineLimit(1)

            Text(cupon.descripcion)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .padding(.top, 2)

            Spacer()

            // Línea punteada divisoria (efecto ticket)
            HStack(spacing: 4) {
                ForEach(0..<18, id: \.self) { _ in
                    Circle()
                        .fill(Color(.systemGray4).opacity(0.5))
                        .frame(width: 3, height: 3)
                }
            }
            .padding(.vertical, 8)

            // Footer: puntos + botón
            if disponible {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                        Text("\(cupon.puntosRequeridos) pts")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Canjear")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(marcaColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            } else {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray5)).frame(height: 4)
                            Capsule()
                                .fill(marcaColor.opacity(0.6))
                                .frame(width: geo.size.width * progreso, height: 4)
                        }
                    }
                    .frame(height: 4)

                    HStack {
                        Text("Faltan \(faltan) pts")
                            .font(.caption2.bold())
                            .foregroundStyle(marcaColor.opacity(0.7))
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(.systemGray4))
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 190, height: 210)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(disponible ? marcaColor.opacity(0.25) : Color(.systemGray5), lineWidth: 1.5)
        )
        .shadow(color: disponible ? marcaColor.opacity(0.15) : .black.opacity(0.04), radius: 10, y: 5)
        .scaleEffect(aparecer ? 1 : 0.92)
        .opacity(aparecer ? (disponible ? 1 : 0.75) : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double.random(in: 0.05...0.2))) {
                aparecer = true
            }
        }
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
