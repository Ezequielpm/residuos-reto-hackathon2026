import SwiftUI
import MapKit

struct MapaRutasView: View {
    @EnvironmentObject var store: AppDataStore
    @State private var seleccionada: SolicitudRecoleccion?
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.4000, longitude: -99.1700),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )

    private var solicitudes: [SolicitudRecoleccion] { store.solicitudes }
    private var disponibles: Int { solicitudes.filter { $0.estado == .disponible }.count }
    private var reclamadas: Int { solicitudes.filter { $0.reclamadaPor == store.currentUserId }.count }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
                ForEach(solicitudes) { solicitud in
                    Annotation("", coordinate: solicitud.puntoAcopio.coordenadas) {
                        SolicitudPin(solicitud: solicitud, esMia: solicitud.reclamadaPor == store.currentUserId)
                            .onTapGesture { seleccionada = solicitud }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            // Barra superior con stats
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recolecciones")
                                .font(.title3.bold())
                            Text(store.currentUserName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 12) {
                            StatPill(valor: "\(disponibles)", label: "abiertas", color: Color(hex: "#E65100"))
                            StatPill(valor: "\(reclamadas)", label: "tuyas", color: Color(hex: "#4CAF50"))
                        }
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

                // Leyenda
                HStack(spacing: 14) {
                    LeyendaItem(color: Color(hex: "#E65100"), texto: "Disponible")
                    LeyendaItem(color: Color(hex: "#0D47A1"), texto: "Empresa")
                    LeyendaItem(color: Color(hex: "#4CAF50"), texto: "Tuya")
                    LeyendaItem(color: Color(.systemGray3), texto: "Reclamada")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 100)
            }
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
        store.reclamarSolicitud(solicitud.id)
        seleccionada = nil
    }
}

// MARK: - Pin mejorado

struct SolicitudPin: View {
    let solicitud: SolicitudRecoleccion
    var esMia: Bool = false

    private var disponible: Bool { solicitud.estado == .disponible }
    private var esEmpresa: Bool { solicitud.puntoAcopio.esEmpresa }

    private var pinColor: LinearGradient {
        if esMia {
            return LinearGradient(colors: [Color(hex: "#66BB6A"), Color(hex: "#2E7D32")],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if esEmpresa && disponible {
            return LinearGradient(colors: [Color(hex: "#42A5F5"), Color(hex: "#0D47A1")],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if disponible {
            return LinearGradient(colors: [Color(hex: "#FF7043"), Color(hex: "#E65100")],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color(.systemGray4), Color(.systemGray3)],
                                  startPoint: .top, endPoint: .bottom)
        }
    }

    private var triangleColor: Color {
        if esMia { return Color(hex: "#2E7D32") }
        else if esEmpresa && disponible { return Color(hex: "#0D47A1") }
        else if disponible { return Color(hex: "#E65100") }
        else { return Color(.systemGray3) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.12))
                    .frame(width: 72, height: 54)
                    .offset(y: 3)
                    .blur(radius: 4)

                RoundedRectangle(cornerRadius: 12)
                    .fill(pinColor)
                    .frame(width: 72, height: 54)

                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        if esEmpresa {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        Text(String(format: "%.0f kg", solicitud.kgEstimados))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text("$\(String(format: "%.0f", solicitud.valorEstimado))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            Triangle()
                .fill(triangleColor)
                .frame(width: 12, height: 7)
        }
    }
}

struct StatPill: View {
    let valor: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(valor)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
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

#Preview { MapaRutasView().environmentObject(AppDataStore()) }
