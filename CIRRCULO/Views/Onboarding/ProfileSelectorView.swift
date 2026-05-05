import SwiftUI

enum PerfilUsuario: String, CaseIterable {
    case ciudadano   = "Ciudadano"
    case pepenador   = "Pepenador"
    case empresa     = "Empresa"
    case puntoAcopio = "Punto de Acopio"
    case centroAcopio = "Centro de Acopio"

    var icono: String {
        switch self {
        case .ciudadano:   return "person.fill"
        case .pepenador:   return "bicycle"
        case .empresa:     return "building.2.fill"
        case .puntoAcopio: return "mappin.circle.fill"
        case .centroAcopio: return "shippingbox.fill"
        }
    }

    var color: Color {
        switch self {
        case .ciudadano:   return Color(hex: "#388E3C")
        case .pepenador:   return Color(hex: "#F9A825")
        case .empresa:     return Color(hex: "#1565C0")
        case .puntoAcopio: return Color(hex: "#6A1B9A")
        case .centroAcopio: return Color(hex: "#BF360C")
        }
    }

    var descripcion: String {
        switch self {
        case .ciudadano:   return "Clasifica residuos y gana puntos"
        case .pepenador:   return "Recolecta y genera ingresos"
        case .empresa:     return "Gestiona residuos y ahorra impuestos"
        case .puntoAcopio: return "Administra tu punto de acopio"
        case .centroAcopio: return "Gestiona recepciones y precios"
        }
    }
}

struct ProfileSelectorView: View {
    @State private var perfilSeleccionado: PerfilUsuario?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F1F8E9")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.3.trianglepath")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hex: "#1B5E20"))

                        Text("CIRRCULO")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color(hex: "#1B5E20"))

                        Text("Economía Circular en México")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 48)
                    .padding(.bottom, 32)

                    // Selección de perfil
                    Text("¿Cómo participas hoy?")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#1B5E20"))
                        .padding(.bottom, 16)

                    VStack(spacing: 12) {
                        ForEach(PerfilUsuario.allCases, id: \.self) { perfil in
                            PerfilCard(perfil: perfil) {
                                perfilSeleccionado = perfil
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    Text("Swift Changemakers Hackathon 2026 · Enactus México")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 12)
                }
            }
            .navigationDestination(item: $perfilSeleccionado) { perfil in
                destinoVista(para: perfil)
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

struct PerfilCard: View {
    let perfil: PerfilUsuario
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(perfil.color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: perfil.icono)
                        .font(.title2)
                        .foregroundStyle(perfil.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(perfil.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(perfil.descripcion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Views de cada perfil

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
        .tint(Color(hex: "#388E3C"))
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
        .tint(Color(hex: "#F9A825"))
        .navigationBarHidden(true)
    }
}

struct EmpresaTabView: View {
    var body: some View {
        TabView {
            DashboardEmpresaView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            ScannerEmpresaView()
                .tabItem { Label("Escanear", systemImage: "camera.viewfinder") }

            AhorroFiscalView()
                .tabItem { Label("Ahorro Fiscal", systemImage: "dollarsign.circle.fill") }

            ResumenLegalView()
                .tabItem { Label("Legal", systemImage: "doc.text.fill") }

            EquipoView()
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
        .tint(Color(hex: "#BF360C"))
        .navigationBarHidden(true)
    }
}

// MARK: - Color hex helper

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
}
