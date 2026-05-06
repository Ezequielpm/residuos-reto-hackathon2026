import SwiftUI
import MapKit

struct MapaAcopioView: View {
    @EnvironmentObject var store: AppDataStore
    private var puntos: [PuntoAcopio] { store.puntosAcopio }
    @State private var puntoSeleccionado: PuntoAcopio?
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.4184, longitude: -99.1631),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    private var disponibles: Int { puntos.filter { $0.porcentajeCapacidad < 0.75 }.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(puntos) { punto in
                    Annotation("", coordinate: punto.coordenadas) {
                        PuntoAcopioPin(punto: punto)
                            .onTapGesture { puntoSeleccionado = punto }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            // Barra superior
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Puntos de Acopio")
                            .font(.title3.bold())
                        Text("\(disponibles) con espacio disponible")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(disponibles > 0 ? Color(hex: "#2E7D32") : Color(.systemGray5))
                            .frame(width: 40, height: 40)
                        Text("\(disponibles)")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
                .padding(.horizontal, 16)
                .padding(.top, 60)
                Spacer()
            }

            // Leyenda
            HStack(spacing: 16) {
                LeyendaItemVerde(color: Color(hex: "#4CAF50"), texto: "Disponible")
                LeyendaItemVerde(color: Color(hex: "#F9A825"), texto: "Medio lleno")
                LeyendaItemVerde(color: Color(hex: "#FF5722"), texto: "Lleno")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .padding(.bottom, 100)
        }
        .sheet(item: $puntoSeleccionado) { punto in
            DetallePuntoAcopioSheet(punto: punto)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Pin

struct PuntoAcopioPin: View {
    let punto: PuntoAcopio

    private var colorCapacidad: Color {
        let pct = punto.porcentajeCapacidad
        if pct < 0.5  { return Color(hex: "#4CAF50") }
        if pct < 0.75 { return Color(hex: "#F9A825") }
        return Color(hex: "#FF5722")
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.15))
                    .frame(width: 46, height: 46)
                    .offset(y: 3)
                    .blur(radius: 4)

                Circle()
                    .fill(colorCapacidad)
                    .frame(width: 44, height: 44)

                Image(systemName: "arrow.3.trianglepath")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            Triangle()
                .fill(colorCapacidad)
                .frame(width: 10, height: 6)
        }
    }
}

struct LeyendaItemVerde: View {
    let color: Color
    let texto: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(texto).font(.caption.bold()).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Sheet Detalle

struct DetallePuntoAcopioSheet: View {
    let punto: PuntoAcopio

    private var colorCapacidad: Color {
        let pct = punto.porcentajeCapacidad
        if pct < 0.5  { return Color(hex: "#4CAF50") }
        if pct < 0.75 { return Color(hex: "#F9A825") }
        return Color(hex: "#FF5722")
    }

    private var pctLibre: Int { Int((1 - punto.porcentajeCapacidad) * 100) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Cabecera verde
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color(hex: "#1B5E20"), Color(hex: "#2E7D32")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )

                    VStack(spacing: 14) {
                        Capsule()
                            .fill(.white.opacity(0.3))
                            .frame(width: 36, height: 4)

                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(.white.opacity(0.15)).frame(width: 48, height: 48)
                                Image(systemName: "arrow.3.trianglepath")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(punto.nombre)
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                Label(punto.direccion, systemImage: "location.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                        }

                        // Capacidad
                        VStack(spacing: 8) {
                            HStack {
                                Text("Capacidad disponible")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                Spacer()
                                Text("\(pctLibre)% libre")
                                    .font(.caption.bold())
                                    .foregroundStyle(colorCapacidad)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(colorCapacidad.opacity(0.2))
                                    .clipShape(Capsule())
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.white.opacity(0.2))
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(colorCapacidad)
                                        .frame(width: geo.size.width * punto.porcentajeCapacidad, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }

                VStack(spacing: 20) {
                    // Materiales
                    if !punto.materialDisponible.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(titulo: "Materiales aceptados",
                                          icono: "shippingbox.fill",
                                          color: Color(hex: "#2E7D32"))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(punto.materialDisponible.keys), id: \.self) { mat in
                                        HStack(spacing: 5) {
                                            Circle()
                                                .fill(Color(hex: "#4CAF50"))
                                                .frame(width: 6, height: 6)
                                            Text(mat)
                                                .font(.caption.bold())
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(hex: "#E8F5E9"))
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Botón llegar
                    Link(destination: URL(string: "maps://?daddr=\(punto.latitud),\(punto.longitud)")!) {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            Text("Cómo llegar")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#388E3C"), Color(hex: "#2E7D32")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color(hex: "#2E7D32").opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .padding(.top, 20)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    MapaAcopioView()
}
