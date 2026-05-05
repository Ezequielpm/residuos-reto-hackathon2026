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

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                ForEach(solicitudes) { solicitud in
                    Annotation(solicitud.puntoAcopio.nombre,
                               coordinate: solicitud.puntoAcopio.coordenadas) {
                        SolicitudPin(solicitud: solicitud)
                            .onTapGesture { seleccionada = solicitud }
                    }
                }
                UserAnnotation()
            }
            .navigationTitle("Rutas disponibles")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $seleccionada) { solicitud in
                DetallePuntoView(solicitud: Binding(
                    get: { solicitud },
                    set: { seleccionada = $0 }
                ), onReclamar: {
                    reclamar(solicitud)
                })
                .presentationDetents([.medium, .large])
            }
            .overlay(alignment: .bottom) {
                ContadorSolicitudes(cantidad: solicitudes.filter { $0.estado == .disponible }.count)
                    .padding(.bottom, 12)
            }
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

struct SolicitudPin: View {
    let solicitud: SolicitudRecoleccion

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(solicitud.estado == .disponible ? Color(hex: "#F9A825") : Color(.systemGray4))
                    .frame(width: 54, height: 44)
                    .shadow(radius: 3)

                VStack(spacing: 1) {
                    Text("\(String(format: "%.0f", solicitud.kgEstimados)) kg")
                        .font(.caption2.bold())
                        .foregroundStyle(solicitud.estado == .disponible ? .white : .secondary)
                    Text("$\(String(format: "%.0f", solicitud.valorEstimado))")
                        .font(.caption2)
                        .foregroundStyle(solicitud.estado == .disponible ? .white.opacity(0.9) : .secondary)
                }
            }
            // Triángulo
            Triangle()
                .fill(solicitud.estado == .disponible ? Color(hex: "#F9A825") : Color(.systemGray4))
                .frame(width: 10, height: 6)
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

struct ContadorSolicitudes: View {
    let cantidad: Int

    var body: some View {
        Label("\(cantidad) solicitudes disponibles", systemImage: "circle.fill")
            .font(.subheadline.bold())
            .foregroundStyle(Color(hex: "#F9A825"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .shadow(radius: 4)
    }
}

#Preview {
    MapaRutasView()
}
