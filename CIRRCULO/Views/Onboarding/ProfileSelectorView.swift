import SwiftUI
import UIKit
import AVFoundation
import AVKit

// MARK: - Perfil de usuario

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
        case .empresa:      return "building.2.fill"
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

// MARK: - Looping Video Player

struct LoopingVideoPlayer: UIViewRepresentable {
    let videoData: Data

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(videoData: videoData)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private class PlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var player: AVPlayer?
    private var loopObserver: Any?

    init(videoData: Data) {
        super.init(frame: .zero)

        // Write data to temp file for AVPlayer
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LogginVideo_\(UUID().uuidString).mp4")
        try? videoData.write(to: tempURL)

        let item = AVPlayerItem(url: tempURL)
        player = AVPlayer(playerItem: item)
        player?.isMuted = true

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)

        // Loop
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }

        player?.play()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    deinit {
        if let obs = loopObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        player?.pause()
    }
}

// MARK: - Profile Selector View

struct ProfileSelectorView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Group {
            if let usuario = auth.usuarioActual {
                NavigationStack {
                    destinoVista(para: usuario.perfil)
                }
            }
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

// MARK: - Glass Profile Card

struct ProfileCardGlass: View {
    let perfil: PerfilUsuario
    let action: () -> Void
    @State private var presionado = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [perfil.colorSecundario, perfil.colorPrimario],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: perfil.icono)
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(perfil.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(perfil.descripcion)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(.ultraThinMaterial.opacity(0.7))
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .scaleEffect(presionado ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { p in
            withAnimation(.easeInOut(duration: 0.1)) { presionado = p }
        }, perform: {})
    }
}

// MARK: - Tab Views

struct CiudadanoTabView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(AuthManager.self) private var auth

    var body: some View {
        TabView {
            PerfilCiudadanoView(onCambiarPerfil: { auth.logout() })
                .tabItem { Label("Perfil", systemImage: "person.circle.fill") }
            MapaAcopioView()
                .tabItem { Label("Mapa", systemImage: "map.fill") }
            ScannerView()
                .tabItem { Label("Escanear", systemImage: "camera.viewfinder") }
            DepositView()
                .tabItem { Label("Depositar", systemImage: "qrcode.viewfinder") }
            AsistenteView()
                .tabItem { Label("Asistente", systemImage: "sparkles") }
        }
        .tint(Color(hex: "#2E7D32"))
        .navigationBarHidden(true)
    }
}

struct PepenadorTabView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(AuthManager.self) private var auth
    @State private var tabActivo: Int = 0

    var body: some View {
        ZStack {
            TabView(selection: $tabActivo) {
                MapaRutasView()
                    .tabItem { Label("Mapa", systemImage: "map.fill") }
                    .tag(0)
                EntregaView()
                    .tabItem { Label("Entregar", systemImage: "checkmark.circle.fill") }
                    .tag(1)
                HistorialPepenadorView(onCambiarPerfil: { auth.logout() })
                    .tabItem { Label("Historial", systemImage: "list.bullet.rectangle") }
                    .tag(2)
            }
            .tint(Color(hex: "#E65100"))
            .navigationBarHidden(true)

            if let solicitud = store.solicitudNuevaParaPepenador {
                AlertaRecoleccionView(
                    solicitud: solicitud,
                    onAccept: {
                        store.solicitudNuevaParaPepenador = nil
                        withAnimation { tabActivo = 1 }
                    },
                    onDismiss: {
                        store.solicitudNuevaParaPepenador = nil
                    }
                )
                .zIndex(100)
            }
        }
    }
}

struct EmpresaTabView: View {
    @StateObject private var vm = EmpresaViewModel()
    @Environment(AuthManager.self) private var auth

    var body: some View {
        TabView {
            DashboardEmpresaView(vm: vm, onCambiarPerfil: { auth.logout() })
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
            ScannerEmpresaView(vm: vm)
                .tabItem { Label("Escanear", systemImage: "camera.viewfinder") }
            AhorroFiscalView(vm: vm)
                .tabItem { Label("Ahorro Fiscal", systemImage: "dollarsign.circle.fill") }
            ResumenLegalView(vm: vm)
                .tabItem { Label("Legal", systemImage: "doc.text.fill") }
            EquipoView(vm: vm, onCambiarPerfil: { auth.logout() })
                .tabItem { Label("Equipo", systemImage: "person.2.fill") }
        }
        .tint(Color(hex: "#1565C0"))
        .navigationBarHidden(true)
    }
}

struct PuntoAcopioTabView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(AuthManager.self) private var auth

    var body: some View {
        TabView {
            PanelContenedoresView(onCambiarPerfil: { auth.logout() })
                .tabItem { Label("Panel", systemImage: "trash.fill") }
            QREstaticoView()
                .tabItem { Label("Mi QR", systemImage: "qrcode") }
        }
        .tint(Color(hex: "#6A1B9A"))
        .navigationBarHidden(true)
    }
}

struct CentroAcopioTabView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(AuthManager.self) private var auth

    var body: some View {
        TabView {
            ConfirmarRecepcionView(onCambiarPerfil: { auth.logout() })
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

#Preview {
    ProfileSelectorView()
        .environment(AuthManager.shared)
}
