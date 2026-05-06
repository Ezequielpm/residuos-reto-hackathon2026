import SwiftUI
import MapKit

struct AlertaRecoleccionView: View {
    @EnvironmentObject var store: AppDataStore
    let solicitud: SolicitudRecoleccion
    let onAccept: () -> Void
    let onDismiss: () -> Void

    @State private var tiempoRestante: Int = 30
    @State private var mostrarCard = false
    @State private var pulso = false
    @State private var aceptada = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var kgPorMaterial: Double {
        guard !solicitud.materialesPrincipales.isEmpty else { return 0 }
        return solicitud.kgEstimados / Double(solicitud.materialesPrincipales.count)
    }

    var body: some View {
        ZStack {
            // Fondo dimmed
            Color.black.opacity(mostrarCard ? 0.5 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.35), value: mostrarCard)

            VStack {
                Spacer()

                VStack(spacing: 0) {
                    if aceptada {
                        confirmacionView
                    } else {
                        contenidoAlerta
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                .shadow(color: .black.opacity(0.3), radius: 30, y: -10)
                .offset(y: mostrarCard ? 0 : 700)
                .animation(.spring(response: 0.6, dampingFraction: 0.82), value: mostrarCard)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                mostrarCard = true
            }
            pulso = true
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.warning)
        }
        .onReceive(timer) { _ in
            guard !aceptada else { return }
            if tiempoRestante > 1 {
                tiempoRestante -= 1
            } else {
                dismissCard()
            }
        }
    }

    // MARK: - Alerta

    private var contenidoAlerta: some View {
        VStack(spacing: 0) {
            // Top handle + timer compacto
            HStack {
                Capsule()
                    .fill(Color(.systemGray3))
                    .frame(width: 36, height: 4)
                Spacer()
                // Timer inline
                HStack(spacing: 6) {
                    timerRing
                        .frame(width: 32, height: 32)
                    Text("\(tiempoRestante)s")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(tiempoRestante > 10 ? Color(hex: "#E65100") : .red)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Encabezado con mapa mini
            HStack(spacing: 14) {
                // Mini mapa
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: solicitud.puntoAcopio.coordenadas,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                ))) {
                    Annotation("", coordinate: solicitud.puntoAcopio.coordenadas) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#E65100"))
                                .frame(width: 28, height: 28)
                            Image(systemName: "mappin")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .disabled(true)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Solicitud de recoleccion")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "#E65100"))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(solicitud.puntoAcopio.nombre)
                        .font(.title3.bold())
                        .lineLimit(1)

                    Label(solicitud.puntoAcopio.direccion, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)

            // Divider
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // Materiales en fila con valor
            HStack(spacing: 12) {
                ForEach(solicitud.materialesPrincipales.prefix(3), id: \.self) { tipo in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#FFF3E0"))
                                .frame(width: 44, height: 44)
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "#E65100"))
                        }
                        Text(tipo.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                        Text("\(String(format: "%.0f", kgPorMaterial)) kg")
                            .font(.caption2.bold())
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)

            // Gran numero de ganancia estimada
            VStack(spacing: 2) {
                Text("Ganancia estimada")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("$\(String(format: "%.0f", solicitud.valorEstimado)) MXN")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#E65100"))
            }
            .padding(.top, 16)

            // Botones
            HStack(spacing: 12) {
                Button(action: dismissCard) {
                    Text("Rechazar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button(action: aceptar) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        Text("Aceptar recolección")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FF8F00"), Color(hex: "#E65100")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(hex: "#E65100").opacity(0.4), radius: 10, y: 5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Timer ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(tiempoRestante) / 30.0)
                .stroke(
                    tiempoRestante > 10 ? Color(hex: "#E65100") : .red,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: tiempoRestante)
        }
    }

    // MARK: - Confirmacion aceptada

    private var confirmacionView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 20)

            ZStack {
                // Anillos de expansion
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color(hex: "#4CAF50").opacity(0.2), lineWidth: 1.5)
                        .frame(width: CGFloat(80 + i * 24), height: CGFloat(80 + i * 24))
                }

                Circle()
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: "#4CAF50"))
            }

            Text("¡Recolección aceptada!")
                .font(.title2.bold())
                .foregroundStyle(Color(hex: "#1B5E20"))

            VStack(spacing: 4) {
                Text(solicitud.puntoAcopio.nombre)
                    .font(.subheadline.bold())
                Text(solicitud.puntoAcopio.direccion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Boton abrir ruta
            Link(destination: URL(string: "maps://?daddr=\(solicitud.puntoAcopio.latitud),\(solicitud.puntoAcopio.longitud)")!) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    Text("Abrir ruta en Mapas")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#43A047"), Color(hex: "#2E7D32")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)
        }
        .frame(maxWidth: .infinity)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    // MARK: - Acciones

    private func aceptar() {
        store.reclamarSolicitud(solicitud.id)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            aceptada = true
        }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.35)) { mostrarCard = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onAccept()
            }
        }
    }

    private func dismissCard() {
        withAnimation(.easeOut(duration: 0.35)) { mostrarCard = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}
