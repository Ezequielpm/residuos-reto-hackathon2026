import SwiftUI

enum PerfilUsuario: String, CaseIterable {
    case ciudadano    = "Ciudadano"
    case pepenador    = "Recolector"
    case empresa      = "Empresa"
    case puntoAcopio  = "Punto de Acopio"
    case centroAcopio = "Centro de Acopio"

    var icono: String {
        switch self {
        case .ciudadano:    return "leaf.circle.fill"
        case .pepenador:    return "bicycle.circle.fill"
        case .empresa:      return "building.2.circle.fill"
        case .puntoAcopio:  return "mappin.circle.fill"
        case .centroAcopio: return "shippingbox.circle.fill"
        }
    }

    var colorPrimario: Color {
        switch self {
        case .ciudadano:    return Color(hex: "#2E7D32")
        case .pepenador:    return Color(hex: "#E65100")
        case .empresa:      return Color(hex: "#1565C0")
        case .puntoAcopio:  return Color(hex: "#6A1B9A")
        case .centroAcopio: return Color(hex: "#AD1457")
        }
    }

    var colorSecundario: Color {
        switch self {
        case .ciudadano:    return Color(hex: "#66BB6A")
        case .pepenador:    return Color(hex: "#FFA726")
        case .empresa:      return Color(hex: "#42A5F5")
        case .puntoAcopio:  return Color(hex: "#AB47BC")
        case .centroAcopio: return Color(hex: "#EC407A")
        }
    }

    var descripcion: String {
        switch self {
        case .ciudadano:    return "Clasifica residuos y gana puntos"
        case .pepenador:    return "Recolecta y genera ingresos"
        case .empresa:      return "Gestiona residuos y ahorra impuestos"
        case .puntoAcopio:  return "Administra tu punto de acopio"
        case .centroAcopio: return "Gestiona recepciones y precios"
        }
    }
}

struct ProfileSelectorView: View {
    @State private var perfilSeleccionado: PerfilUsuario?
    @State private var aparecieron = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo degradado
                LinearGradient(
                    colors: [Color(hex: "#1B5E20"), Color(hex: "#2E7D32"), Color(hex: "#388E3C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Círculos decorativos
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -180)
                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: 200, height: 200)
                    .offset(x: 150, y: -60)
                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: 250, height: 250)
                    .offset(x: 120, y: 300)

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.3.trianglepath")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(aparecieron ? 1 : 0)
                            .scaleEffect(aparecieron ? 1 : 0.6)

                        Text("CIRRCULO")
                            .font(.system(size: 34, weight: .black))
                            .tracking(3)
                            .foregroundStyle(.white)

                        Text("Economía Circular en México")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.top, 56)
                    .padding(.bottom, 40)

                    // Tarjetas de perfil
                    VStack(spacing: 12) {
                        Text("¿Cómo participas hoy?")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)

                        ForEach(Array(PerfilUsuario.allCases.enumerated()), id: \.element) { index, perfil in
                            PerfilCard(perfil: perfil) {
                                perfilSeleccionado = perfil
                            }
                            .opacity(aparecieron ? 1 : 0)
                            .offset(y: aparecieron ? 0 : 30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.75)
                                    .delay(Double(index) * 0.07 + 0.2),
                                value: aparecieron
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Text("Swift Changemakers Hackathon 2026 · Enactus México")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.bottom, 16)
                }
            }
            .navigationDestination(item: $perfilSeleccionado) { perfil in
                destinoVista(para: perfil)
            }
        }
        .onAppear {
            withAnimation { aparecieron = true }
        }
    }

    @ViewBuilder
    private func destinoVista(para perfil: PerfilUsuario) -> some View {
        switch perfil {
        case .ciudadano:    CiudadanoTabView()
        case .pepenador:    PepenadorTabView()
        case .empresa:      EmpresaTabView()
        case .puntoAcopio:  PuntoAcopioTabView()
        case .centroAcopio: CentroAcopioTabView()
        }
    }
}

struct PerfilCard: View {
    let perfil: PerfilUsuario
    let action: () -> Void
    @State private var presionado = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Ícono con gradiente
                ZStack {
                    LinearGradient(
                        colors: [perfil.colorSecundario, perfil.colorPrimario],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(width: 52, height: 52)

                    Image(systemName: perfil.icono)
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(perfil.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1B2A1B"))
                    Text(perfil.descripcion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
            .scaleEffect(presionado ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { p in
            withAnimation(.easeInOut(duration: 0.12)) { presionado = p }
        }, perform: {})
    }
}

// MARK: - Tab Views

struct CiudadanoTabView: View {
    var body: some View {
        TabView {
            ScannerView()
                .tabItem { Label("Escanear", systemImage: "camera.viewfinder") }
            AsistenteView()
                .tabItem { Label("Asistente", systemImage: "sparkles") }
            DepositView()
                .tabItem { Label("Depositar", systemImage: "qrcode.viewfinder") }
            MapaAcopioView()
                .tabItem { Label("Mapa", systemImage: "map.fill") }
            PerfilCiudadanoView()
                .tabItem { Label("Perfil", systemImage: "person.circle.fill") }
        }
        .tint(Color(hex: "#2E7D32"))
        .navigationBarHidden(true)
    }
}

struct PepenadorTabView: View {
    var body: some View {
        TabView {
            MapaRutasView()
                .tabItem { Label("Mapa", systemImage: "map.fill") }
            EntregaView()
                .tabItem { Label("Entregar", systemImage: "checkmark.circle.fill") }
            HistorialPepenadorView()
                .tabItem { Label("Historial", systemImage: "list.bullet.rectangle") }
        }
        .tint(Color(hex: "#E65100"))
        .navigationBarHidden(true)
    }
}

struct EmpresaTabView: View {
    @StateObject private var vm = EmpresaViewModel()

    var body: some View {
        TabView {
            DashboardEmpresaView(vm: vm)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
            ScannerEmpresaView(vm: vm)
                .tabItem { Label("Escanear", systemImage: "camera.viewfinder") }
            AhorroFiscalView(vm: vm)
                .tabItem { Label("Ahorro Fiscal", systemImage: "dollarsign.circle.fill") }
            ResumenLegalView(vm: vm)
                .tabItem { Label("Legal", systemImage: "doc.text.fill") }
            EquipoView(vm: vm)
                .tabItem { Label("Equipo", systemImage: "person.2.fill") }
        }
        .tint(Color(hex: "#1565C0"))
        .navigationBarHidden(true)
    }
}

struct PuntoAcopioTabView: View {
    var body: some View {
        TabView {
            PanelContenedoresView()
                .tabItem { Label("Panel", systemImage: "trash.fill") }
            QREstaticoView()
                .tabItem { Label("Mi QR", systemImage: "qrcode") }
        }
        .tint(Color(hex: "#6A1B9A"))
        .navigationBarHidden(true)
    }
}

struct CentroAcopioTabView: View {
    var body: some View {
        TabView {
            ConfirmarRecepcionView()
                .tabItem { Label("Recepciones", systemImage: "shippingbox.fill") }
            PreciosMaterialView()
                .tabItem { Label("Precios", systemImage: "tag.fill") }
        }
        .tint(Color(hex: "#AD1457"))
        .navigationBarHidden(true)
    }
}

// MARK: - Color helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview { ProfileSelectorView() }
