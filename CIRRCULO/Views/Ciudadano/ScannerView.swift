import SwiftUI
import AVFoundation

struct ScannerView: View {
    @StateObject private var camera = CameraService()
    @StateObject private var classifier = ClassifierService.shared

    @State private var resultado: ResultadoClasificacion?
    @State private var materialesTicket: [TipoResiduo: Double] = [:]
    @State private var mostrarGuardado = false
    @State private var instruccionesDinamicas: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Preview de cámara
                CameraPreviewLayer(session: camera.captureSession)
                    .ignoresSafeArea()

                // Overlay animado
                ScannerOverlay()

                // Panel de resultado
                if let resultado {
                    PanelResultado(
                        resultado: resultado,
                        instrucciones: instruccionesDinamicas,
                        onGuardar: {
                            guardarEnTicket(resultado)
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Estado inicial
                    VStack {
                        Spacer()
                        Text("Apunta la cámara a un residuo")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Clasificar Residuo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .overlay(alignment: .top) {
                if mostrarGuardado {
                    GuardadoBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .task {
            await camera.solicitarPermiso()
        }
        .onChange(of: camera.pixelBuffer) { _, buffer in
            guard let buffer else { return }
            Task {
                if let nuevoResultado = await ClassifierService.shared.clasificar(pixelBuffer: buffer) {
                    withAnimation(.spring(response: 0.4)) {
                        resultado = nuevoResultado
                    }
                    // Instrucciones dinámicas via Foundation Models (con fallback automático)
                    instruccionesDinamicas = await FoundationModelsService.shared
                        .instruccionesParaMaterial(nuevoResultado)
                }
            }
        }
    }

    private func guardarEnTicket(_ r: ResultadoClasificacion) {
        // Kg estimados: 0.5 kg por defecto para el hackathon
        materialesTicket[r.tipo, default: 0] += 0.5
        withAnimation {
            mostrarGuardado = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { mostrarGuardado = false }
            }
        }
    }
}

// MARK: - CameraPreviewLayer

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = UIScreen.main.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Scanner Overlay

struct ScannerOverlay: View {
    @State private var animando = false

    var body: some View {
        GeometryReader { geo in
            let size: CGFloat = 220
            let x = (geo.size.width - size) / 2
            let y = geo.size.height * 0.25

            ZStack {
                // Fondo oscuro excepto el cuadro
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                // Cuadro transparente
                RoundedRectangle(cornerRadius: 16)
                    .blendMode(.destinationOut)
                    .frame(width: size, height: size)
                    .position(x: geo.size.width / 2, y: y + size / 2)

                // Esquinas del cuadro
                ScannerCorners(size: size)
                    .position(x: geo.size.width / 2, y: y + size / 2)
                    .foregroundStyle(.white)

                // Línea de escaneo
                Rectangle()
                    .fill(Color(hex: "#4CAF50").opacity(0.8))
                    .frame(width: size - 20, height: 2)
                    .clipShape(Capsule())
                    .position(x: geo.size.width / 2,
                              y: animando ? y + size - 10 : y + 10)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: animando)
            }
            .compositingGroup()
        }
        .onAppear { animando = true }
    }
}

struct ScannerCorners: View {
    let size: CGFloat
    private let grosor: CGFloat = 3
    private let largo: CGFloat = 24

    var body: some View {
        ZStack {
            ForEach([(0, 0), (1, 0), (0, 1), (1, 1)], id: \.0) { hFlip, vFlip in
                CornerShape()
                    .stroke(lineWidth: grosor)
                    .frame(width: largo, height: largo)
                    .scaleEffect(x: hFlip == 0 ? 1 : -1, y: vFlip == 0 ? 1 : -1)
                    .offset(x: hFlip == 0 ? -(size / 2 - largo / 2) : (size / 2 - largo / 2),
                            y: vFlip == 0 ? -(size / 2 - largo / 2) : (size / 2 - largo / 2))
            }
        }
    }
}

struct CornerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

// MARK: - Panel Resultado

struct PanelResultado: View {
    let resultado: ResultadoClasificacion
    let instrucciones: String?
    let onGuardar: () -> Void

    private var colorContenedor: Color {
        switch resultado.contenedor {
        case .verde:   return Color(hex: "#4CAF50")
        case .gris:    return Color(hex: "#607D8B")
        case .naranja: return Color(hex: "#FF5722")
        }
    }

    private var colorConfianza: Color {
        resultado.confianza >= 0.70 ? colorContenedor : Color(hex: "#F9A825")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Barra de confianza
            Rectangle()
                .fill(colorConfianza)
                .frame(height: 4)

            VStack(spacing: 16) {
                // Material y contenedor
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resultado.tipo.rawValue)
                            .font(.title2.bold())
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorContenedor)
                                .frame(width: 12, height: 12)
                            Text("Contenedor \(resultado.contenedor.rawValue)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(resultado.proximaRecoleccion)
                            .font(.caption.bold())
                            .foregroundStyle(colorContenedor)
                        Text("Próxima recolección")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Instrucciones
                if let instrucciones {
                    Text(instrucciones)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Ambigüedad
                if resultado.esAmbiguo {
                    AmbiguedadView()
                }

                // Botón guardar
                Button(action: onGuardar) {
                    Label("Guardar escaneo", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(colorContenedor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

struct AmbiguedadView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Confianza baja — selecciona manualmente:", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "#F9A825"))

            HStack(spacing: 8) {
                ForEach([TipoResiduo.plasticoPET, .carton], id: \.self) { tipo in
                    Button {
                        // Selección manual
                    } label: {
                        Text(tipo.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Banner guardado

struct GuardadoBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Escaneo guardado en tu ticket")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(radius: 4)
        .padding(.top, 8)
    }
}

#Preview {
    ScannerView()
}
