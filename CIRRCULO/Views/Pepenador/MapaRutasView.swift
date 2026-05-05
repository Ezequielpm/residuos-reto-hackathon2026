import SwiftUI
import MapKit

struct MapaRutasView: View {
    @State private var solicitudes = MockDataService.shared.solicitudesRecoleccion
    @State private var seleccionada: SolicitudRecoleccion?
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.4000, longitude: -99.1700),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )

    private var disponibles: Int { solicitudes.filter { $0.estado == .disponible }.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(solicitudes) { solicitud in
                    Annotation("", coordinate: solicitud.puntoAcopio.coordenadas) {
                        SolicitudPinV2(solicitud: solicitud)
                            .onTapGesture { seleccionada = solicitud }
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
                        Text("Rutas disponibles")
                            .font(.title3.bold())
                        Text("\(disponibles) solicitudes activas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(disponibles > 0 ? Color(hex: "#E65100") : Color(.systemGray5))
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
                LeyendaItem(color: Color(hex: "#E65100"), texto: "Disponible")
                LeyendaItem(color: Color(.systemGray3), texto: "Reclamada")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .padding(.bottom, 100)
        }
        .sheet(item: $seleccionada) { solicitud in
            DetallePuntoView(
                solicitud: Binding(
                    get: { solicitud },
                    set: { seleccionada = $0 }
                ),
                onReclamar: { reclamar(solicitud) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func reclamar(_ solicitud: SolicitudRecoleccion) {
        if let idx = solicitudes.firstIndex(where: { $0.id == solicitud.id }) {
            solicitudes[idx].estado = .reclamada
            solicitudes[idx].reclamadaPor = "pepenador-demo-01"
        }
        seleccionada = nil
    }
}

struct SolicitudPinV2: View {
    let solicitud: SolicitudRecoleccion
    private var disponible: Bool { solicitud.estado == .disponible }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Sombra
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.15))
                    .frame(width: 68, height: 52)
                    .offset(y: 3)
                    .blur(radius: 4)

                RoundedRectangle(cornerRadius: 12)
                    .fill(disponible
                          ? LinearGradient(colors: [Color(hex: "#FF7043"), Color(hex: "#E65100")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray3)],
                                           startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 68, height: 52)

                VStack(spacing: 1) {
                    Text(String(format: "%.0f kg", solicitud.kgEstimados))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text("$\(String(format: "%.0f", solicitud.valorEstimado))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            // Puntero
            Triangle()
                .fill(disponible ? Color(hex: "#E65100") : Color(.systemGray3))
                .frame(width: 12, height: 7)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct LeyendaItem: View {
    let color: Color
    let texto: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(texto).font(.caption.bold()).foregroundStyle(.secondary)
        }
    }
}

#Preview { MapaRutasView() }
