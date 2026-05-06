import SwiftUI
import AVFoundation

struct DepositView: View {
    @EnvironmentObject var store: AppDataStore
    @State private var modoVerificacion = false
    @State private var depositoVerificado = false
    @State private var mostrarMapa = false
    @State private var puntosGanados = 0

    private var totalPuntos: Int {
        store.ticketPuntosEstimados
    }

    var body: some View {
        NavigationStack {
            Group {
                if depositoVerificado {
                    CelebracionView(puntos: puntosGanados)
                } else if modoVerificacion {
                    VerificacionQRView(onVerificado: { puntoId in
                        puntosGanados = totalPuntos
                        store.depositarEnPunto(puntoAcopioId: puntoId)
                        withAnimation(.spring()) { depositoVerificado = true }
                    }, onCancelar: {
                        modoVerificacion = false
                    }, puntosAcopio: store.puntosAcopio)
                } else {
                    ScrollView {
                        TicketView(
                            materiales: store.ticketActual,
                            totalPuntos: totalPuntos,
                            onIrADepositar: { mostrarMapa = true },
                            onVerificarEnPunto: { modoVerificacion = true }
                        )
                        .padding()
                    }
                }
            }
            .navigationTitle(modoVerificacion ? "Verificar depósito" : "Depositar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $mostrarMapa) {
                NavigationStack {
                    MapaAcopioView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    mostrarMapa = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                }
            }
            .toolbar {
                if !depositoVerificado && !modoVerificacion && !store.ticketActual.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            store.ticketActual = [:]
                        } label: {
                            Label("Limpiar", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Ticket View

struct TicketView: View {
    let materiales: [TipoResiduo: Double]
    let totalPuntos: Int
    let onIrADepositar: () -> Void
    let onVerificarEnPunto: () -> Void

    private var materialesOrdenados: [TipoResiduo] {
        materiales.keys.sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header Card
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#2E7D32"), Color(hex: "#388E3C")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color(hex: "#2E7D32").opacity(0.3), radius: 12, y: 6)

                VStack(spacing: 10) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.8))

                    VStack(spacing: 4) {
                        Text("\(totalPuntos)")
                            .font(.system(size: 44, weight: .black))
                            .foregroundStyle(.white)
                        Text("puntos al depositar")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(24)
            }

            if materiales.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 52))
                        .foregroundStyle(Color(.systemGray3))
                    Text("Escanea residuos en la pestaña Escanear para agregarlos a tu ticket")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
            } else {
                // Lista de materiales
                VStack(spacing: 0) {
                    ForEach(materialesOrdenados, id: \.self) { tipo in
                        MaterialRow(tipo: tipo, kg: materiales[tipo] ?? 0)
                        if tipo != materialesOrdenados.last {
                            Divider().padding(.horizontal, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)

                // Botones
                VStack(spacing: 10) {
                    Button(action: onVerificarEnPunto) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Ya estoy en el punto — verificar QR")
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

                    Button(action: onIrADepositar) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Ver puntos de acopio cercanos")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }
}

struct MaterialRow: View {
    let tipo: TipoResiduo
    let kg: Double

    private var colorContenedor: Color {
        switch tipo.contenedor {
        case .verde:   return Color(hex: "#4CAF50")
        case .gris:    return Color(hex: "#607D8B")
        case .naranja: return Color(hex: "#FF5722")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(colorContenedor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(tipo.rawValue)
                    .font(.subheadline.bold())
                Text("Contenedor \(tipo.contenedor.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", kg)) kg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("+\(Int(kg * Double(tipo.puntosPorKg))) pts")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "#388E3C"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Verificación QR

struct VerificacionQRView: View {
    let onVerificado: (UUID) -> Void
    let onCancelar: () -> Void
    let puntosAcopio: [PuntoAcopio]
    @State private var qrDetectado = false
    @State private var puntoSeleccionado: PuntoAcopio?
    @State private var procesando = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    if !qrDetectado {
                        VStack(spacing: 20) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80))
                                .foregroundStyle(.white)

                            Text("Apunta al código QR del punto de acopio")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            // Simular escaneo QR con selector de punto
                            VStack(spacing: 10) {
                                Text("Simular escaneo QR (demo)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white.opacity(0.6))

                                ForEach(puntosAcopio.prefix(3)) { punto in
                                    Button {
                                        puntoSeleccionado = punto
                                        withAnimation { qrDetectado = true }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "mappin.circle.fill")
                                            Text(punto.nombre)
                                                .font(.subheadline.bold())
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(.white.opacity(0.2))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(.white.opacity(0.4), lineWidth: 1))
                                    }
                                }
                            }
                        }
                    } else if let punto = puntoSeleccionado {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(Color(hex: "#4CAF50"))

                            Text("QR de \(punto.nombre) detectado")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("Ahora toma una foto del material que estás depositando para verificar")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            Button {
                                procesando = true
                                Task {
                                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                                    await MainActor.run { onVerificado(punto.id) }
                                }
                            } label: {
                                if procesando {
                                    HStack(spacing: 10) {
                                        ProgressView().tint(.white)
                                        Text("Verificando con IA...")
                                    }
                                    .font(.headline)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "#388E3C"))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                                } else {
                                    Label("Tomar foto del material", systemImage: "camera.fill")
                                        .font(.headline)
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 14)
                                        .background(Color(hex: "#388E3C"))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                            .disabled(procesando)
                        }
                    }

                    Spacer()

                    Button(action: onCancelar) {
                        Text("Cancelar")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

// MARK: - Celebración

struct CelebracionView: View {
    let puntos: Int
    @State private var escala: CGFloat = 0.5
    @State private var opacidad: Double = 0
    @State private var particulas = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill([Color(hex: "#4CAF50"), Color(hex: "#F9A825"), Color(hex: "#388E3C")][i % 3])
                        .frame(width: 8, height: 8)
                        .offset(
                            x: particulas ? cos(Double(i) * .pi / 4) * 90 : 0,
                            y: particulas ? sin(Double(i) * .pi / 4) * 90 : 0
                        )
                        .opacity(particulas ? 0 : 1)
                }

                Circle()
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 150, height: 150)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color(hex: "#388E3C"))
            }
            .scaleEffect(escala)
            .opacity(opacidad)

            VStack(spacing: 8) {
                Text("¡Depósito verificado!")
                    .font(.title.bold())
                    .foregroundStyle(Color(hex: "#1B5E20"))

                Text("+\(puntos)")
                    .font(.system(size: 64, weight: .black))
                    .foregroundStyle(Color(hex: "#388E3C"))

                Text("puntos ganados")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .opacity(opacidad)

            Text("Gracias por contribuir a la economía circular de México")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(opacidad)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                escala = 1.0
                opacidad = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                particulas = true
            }
        }
    }
}

#Preview {
    DepositView()
        .environmentObject(AppDataStore())
}
