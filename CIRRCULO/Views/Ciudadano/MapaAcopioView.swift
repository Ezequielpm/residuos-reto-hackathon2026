import SwiftUI
import MapKit

struct MapaAcopioView: View {
    @State private var puntos = MockDataService.shared.puntosAcopio
    @State private var puntoSeleccionado: PuntoAcopio?
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.4184, longitude: -99.1631),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                ForEach(puntos) { punto in
                    Annotation(punto.nombre, coordinate: punto.coordenadas) {
                        PuntoAcopioPin(punto: punto)
                            .onTapGesture { puntoSeleccionado = punto }
                    }
                }
                UserAnnotation()
            }
            .navigationTitle("Puntos de Acopio")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $puntoSeleccionado) { punto in
                DetallePuntoAcopioSheet(punto: punto)
                    .presentationDetents([.medium])
            }
        }
    }
}

struct PuntoAcopioPin: View {
    let punto: PuntoAcopio

    private var colorCapacidad: Color {
        let pct = punto.porcentajeCapacidad
        if pct < 0.5 { return Color(hex: "#4CAF50") }
        if pct < 0.75 { return Color(hex: "#F9A825") }
        return Color(hex: "#FF5722")
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(colorCapacidad)
                .frame(width: 36, height: 36)
                .shadow(radius: 3)
            Image(systemName: "arrow.3.trianglepath")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

struct DetallePuntoAcopioSheet: View {
    let punto: PuntoAcopio

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text(punto.nombre)
                    .font(.title2.bold())
                Text(punto.direccion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Capacidad
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Capacidad disponible")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int((1 - punto.porcentajeCapacidad) * 100))% libre")
                        .font(.caption.bold())
                        .foregroundStyle(punto.porcentajeCapacidad < 0.75 ? Color(hex: "#4CAF50") : Color(hex: "#FF5722"))
                }
                ProgressView(value: punto.porcentajeCapacidad)
                    .tint(punto.porcentajeCapacidad < 0.5 ? Color(hex: "#4CAF50") :
                          punto.porcentajeCapacidad < 0.75 ? Color(hex: "#F9A825") : Color(hex: "#FF5722"))
            }
            .padding(.horizontal)

            // Materiales
            if !punto.materialDisponible.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Materiales aceptados")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(punto.materialDisponible.keys), id: \.self) { mat in
                                Text(mat)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#E8F5E9"))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // Botón cómo llegar
            Link(destination: URL(string: "maps://?daddr=\(punto.latitud),\(punto.longitud)")!) {
                Label("Cómo llegar", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#388E3C"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

#Preview {
    MapaAcopioView()
}
