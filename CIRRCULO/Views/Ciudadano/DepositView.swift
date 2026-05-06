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
    @State private var puntoDetectado: PuntoAcopio?
    @State private var camaraAbierta = false
    @State private var fotoTomada: UIImage?
    @State private var verificandoFoto = false
    @State private var mensajeRechazo: String?
    @State private var materialDetectado: String?
    @State private var mensajeError: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let punto = puntoDetectado {
                if let foto = fotoTomada {
                    VerificacionFotoView(
                        foto: foto,
                        verificando: verificandoFoto,
                        materialDetectado: materialDetectado,
                        mensajeRechazo: mensajeRechazo,
                        onRetomar: {
                            fotoTomada = nil
                            materialDetectado = nil
                            mensajeRechazo = nil
                            camaraAbierta = true
                        },
                        onCancelar: onCancelar
                    )
                } else {
                    QRConfirmadoView(
                        punto: punto,
                        onTomarFoto: { camaraAbierta = true },
                        onCancelar: onCancelar
                    )
                }
            } else {
                QRScannerRepresentable { codigo in handleDetection(codigo) }
                    .ignoresSafeArea()

                QRScannerOverlay(mensajeError: mensajeError, onCancelar: onCancelar)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: puntoDetectado?.id)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: fotoTomada)
        .fullScreenCover(isPresented: $camaraAbierta) {
            CamaraFotoPicker(
                onCapturada: { imagen in
                    camaraAbierta = false
                    fotoTomada = imagen
                    if let punto = puntoDetectado {
                        verificarFoto(imagen, en: punto)
                    }
                },
                onCancel: { camaraAbierta = false }
            )
            .ignoresSafeArea()
        }
    }

    private func handleDetection(_ codigo: String) {
        guard puntoDetectado == nil else { return }
        let prefijoValido = codigo.hasPrefix("NEXIA-PUNTO-") || codigo.hasPrefix("CIRRCULO-PUNTO-")
        guard prefijoValido, let punto = puntosAcopio.first(where: { $0.qrCode == codigo }) else {
            withAnimation { mensajeError = "Código no reconocido. Apunta al QR de un punto de acopio Nexia." }
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        puntoDetectado = punto
    }

    private func verificarFoto(_ imagen: UIImage, en punto: PuntoAcopio) {
        verificandoFoto = true
        materialDetectado = nil
        mensajeRechazo = nil

        guard let cgImage = imagen.cgImage else {
            verificandoFoto = false
            mensajeRechazo = "No pudimos procesar la foto. Intenta de nuevo."
            return
        }
        let orientation = orientacionDesde(imagen.imageOrientation)

        ClassifierService.shared.clasificar(cgImage: cgImage, orientation: orientation) { resultado in
            verificandoFoto = false
            let tipo = resultado.resultado.tipo
            let confianza = resultado.resultado.confianza
            let esReciclable = tipo != .noReciclable
            let confianzaSuficiente = confianza >= 0.30

            if esReciclable && confianzaSuficiente {
                materialDetectado = "\(tipo.rawValue) detectado"
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                Task {
                    try? await Task.sleep(nanoseconds: 900_000_000)
                    await MainActor.run { onVerificado(punto.id) }
                }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                mensajeRechazo = esReciclable
                    ? "No estamos seguros de lo que muestra la foto. Acerca el material y vuelve a tomarla."
                    : "No detectamos material reciclable. Asegúrate de enfocar el residuo y vuelve a intentar."
            }
        }
    }
}

// MARK: - QR Confirmado (paso intermedio)

struct QRConfirmadoView: View {
    let punto: PuntoAcopio
    let onTomarFoto: () -> Void
    let onCancelar: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: "#4CAF50"))

            VStack(spacing: 6) {
                Text("QR verificado")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(punto.nombre)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
            }

            VStack(spacing: 10) {
                Label("Paso 2 · Comprobación con IA", systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "#FFD54F"))
                Text("Toma una foto del material que estás depositando. La IA verificará que sea reciclable antes de otorgarte los puntos.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 8)

            Button(action: onTomarFoto) {
                Label("Tomar foto del material", systemImage: "camera.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#388E3C"), Color(hex: "#2E7D32")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "#2E7D32").opacity(0.4), radius: 10, y: 4)
            }
            .padding(.top, 8)

            Spacer()

            Button(action: onCancelar) {
                Text("Cancelar")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Verificación de la foto

struct VerificacionFotoView: View {
    let foto: UIImage
    let verificando: Bool
    let materialDetectado: String?
    let mensajeRechazo: String?
    let onRetomar: () -> Void
    let onCancelar: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Image(uiImage: foto)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(borderColor, lineWidth: 3)
                    )
                    .shadow(color: borderColor.opacity(0.5), radius: 12, y: 4)

                if verificando {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.black.opacity(0.45))
                        .frame(width: 280, height: 280)
                    VStack(spacing: 12) {
                        ProgressView().tint(.white).scaleEffect(1.5)
                        Text("Verificando con IA...")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                } else if mensajeRechazo != nil {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                        .padding(20)
                        .background(Color(hex: "#D32F2F").opacity(0.85))
                        .clipShape(Circle())
                } else if materialDetectado != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                        .padding(20)
                        .background(Color(hex: "#388E3C").opacity(0.85))
                        .clipShape(Circle())
                }
            }

            if let material = materialDetectado, !verificando {
                Label(material, systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#388E3C"))
                    .clipShape(Capsule())
            }

            if let mensaje = mensajeRechazo {
                Text(mensaje)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button(action: onRetomar) {
                    Label("Tomar otra foto", systemImage: "camera.rotate.fill")
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#388E3C"))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
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

    private var borderColor: Color {
        if mensajeRechazo != nil { return Color(hex: "#D32F2F") }
        if materialDetectado != nil { return Color(hex: "#4CAF50") }
        return .white.opacity(0.4)
    }
}

private func orientacionDesde(_ ui: UIImage.Orientation) -> CGImagePropertyOrientation {
    switch ui {
    case .up:            return .up
    case .upMirrored:    return .upMirrored
    case .down:          return .down
    case .downMirrored:  return .downMirrored
    case .left:          return .left
    case .leftMirrored:  return .leftMirrored
    case .right:         return .right
    case .rightMirrored: return .rightMirrored
    @unknown default:    return .up
    }
}

// MARK: - Cámara nativa para captura de foto

struct CamaraFotoPicker: UIViewControllerRepresentable {
    let onCapturada: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CamaraFotoPicker
        init(_ parent: CamaraFotoPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapturada(image)
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

// MARK: - Scanner overlay (retícula + instrucciones)

struct QRScannerOverlay: View {
    let mensajeError: String?
    let onCancelar: () -> Void
    @State private var lineaY: CGFloat = -110

    var body: some View {
        VStack {
            VStack(spacing: 8) {
                Label("Escanea el QR del punto de acopio", systemImage: "qrcode.viewfinder")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("Acerca la cámara al código pegado en el contenedor")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.black.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()

            // Retícula
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.85), lineWidth: 3)
                    .frame(width: 240, height: 240)

                ForEach(0..<4) { idx in
                    EsquinaRetícula()
                        .stroke(Color(hex: "#4CAF50"), lineWidth: 5)
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(Double(idx) * 90))
                        .offset(
                            x: idx == 1 || idx == 2 ? 104 : -104,
                            y: idx >= 2 ? 104 : -104
                        )
                }

                Rectangle()
                    .fill(LinearGradient(colors: [.clear, Color(hex: "#4CAF50"), .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: 220, height: 2)
                    .offset(y: lineaY)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                            lineaY = 110
                        }
                    }
            }

            Spacer()

            if let mensajeError {
                Text(mensajeError)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#D32F2F").opacity(0.9))
                    .clipShape(Capsule())
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }

            Button(action: onCancelar) {
                Text("Cancelar")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.55))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 32)
        }
    }
}

struct EsquinaRetícula: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

// MARK: - QR Scanner real (AVCaptureMetadataOutput)

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onDetectado: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onDetectado = onDetectado
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onDetectado: ((String) -> Void)?
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var ultimoCodigo: String?
    private var ultimaDeteccion = Date.distantPast

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurarSesion()
    }

    private func configurarSesion() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else { return }
        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else { return }
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let codigo = obj.stringValue else { return }
        // Throttle: ignora repeticiones del mismo código en ráfaga
        if codigo == ultimoCodigo, Date().timeIntervalSince(ultimaDeteccion) < 1.5 { return }
        ultimoCodigo = codigo
        ultimaDeteccion = Date()
        onDetectado?(codigo)
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
