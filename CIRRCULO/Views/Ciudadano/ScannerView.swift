import SwiftUI
import AVFoundation

// MARK: - ViewModel

@MainActor
final class ScannerCiudadanoViewModel: ObservableObject {
    @Published var resultado: ResultadoClasificacion?
    @Published var candidatos: [TipoResiduo] = []
    @Published var topVisionTags: [String] = []
    @Published var instruccionesDinamicas: String?
    @Published var isAnalyzing = false
    @Published var isPaused = false

    // Desambiguación
    @Published var showDisambiguation = false
    @Published var disambiguationQuestion: String?
    @Published var isGeneratingQuestion = false

    // Ticket
    @Published var materialesTicket: [TipoResiduo: Double] = [:]
    @Published var mostrarGuardado = false
    @Published var ptsGuardados = 0

    private var lastClassification: Date = .distantPast

    func processFrame(_ cgImage: CGImage) {
        let now = Date()
        guard now.timeIntervalSince(lastClassification) >= 0.8, !isAnalyzing, !isPaused else { return }
        lastClassification = now
        isAnalyzing = true

        ClassifierService.shared.clasificar(cgImage: cgImage) { [weak self] enriquecido in
            guard let self else { return }
            let r = enriquecido.resultado

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.resultado = r
                self.candidatos = enriquecido.candidatos
                self.topVisionTags = enriquecido.topVisionTags
            }
            self.isAnalyzing = false

            // Instrucciones dinámicas del LLM
            Task {
                let ins = await FoundationModelsService.shared.instruccionesParaMaterial(r)
                await MainActor.run { withAnimation { self.instruccionesDinamicas = ins } }
            }

            // Si es ambiguo → generar pregunta de desambiguación
            if r.esAmbiguo && enriquecido.candidatos.count >= 2 && !self.showDisambiguation {
                self.triggerDisambiguation(candidatos: enriquecido.candidatos, tags: enriquecido.topVisionTags)
            }
        }
    }

    private func triggerDisambiguation(candidatos: [TipoResiduo], tags: [String]) {
        isPaused = true
        isGeneratingQuestion = true
        withAnimation(.spring(response: 0.4)) { showDisambiguation = true }

        Task {
            let pista = await FoundationModelsService.shared
                .resolverAmbiguedad(opcion1: candidatos[0], opcion2: candidatos[1])
            withAnimation { disambiguationQuestion = pista; isGeneratingQuestion = false }
        }
    }

    func selectCategory(_ tipo: TipoResiduo) {
        guard let r = resultado else { return }
        let nuevo = ResultadoClasificacion(
            tipo: tipo, contenedor: tipo.contenedor, confianza: 1.0,
            proximaRecoleccion: r.proximaRecoleccion,
            instrucciones: ClassifierService.instruccionesHardcodeadas[tipo] ?? "",
            valorMercado: tipo.valorMercado,
            objetoDetectado: r.objetoDetectado
        )
        withAnimation(.spring(response: 0.3)) {
            resultado = nuevo
            showDisambiguation = false
            disambiguationQuestion = nil
        }
        guardarEnTicket(nuevo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.isPaused = false
        }
    }

    func dismissDisambiguation() {
        withAnimation(.spring(response: 0.3)) {
            showDisambiguation = false
            disambiguationQuestion = nil
        }
        isPaused = false
    }

    /// Referencia al store compartido — se asigna desde ScannerView.onAppear
    weak var store: AppDataStore?

    func guardarEnTicket(_ r: ResultadoClasificacion) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        ptsGuardados = Int(0.5 * Double(r.tipo.puntosPorKg))
        materialesTicket[r.tipo, default: 0] += 0.5
        // Sincronizar con el store compartido
        store?.agregarAlTicket(tipo: r.tipo, kg: 0.5)
        withAnimation(.spring(response: 0.3)) { mostrarGuardado = true }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run { withAnimation { mostrarGuardado = false } }
        }
    }
}

// MARK: - ScannerView

struct ScannerView: View {
    @EnvironmentObject var store: AppDataStore
    @StateObject private var vm = ScannerCiudadanoViewModel()
    @StateObject private var camera = CameraService()

    private var activeColor: Color {
        guard let r = vm.resultado else { return .white.opacity(0.5) }
        return Color(hex: r.contenedor.colorHex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Camera feed
            CameraPreviewLayer(session: camera.captureSession)
                .ignoresSafeArea()

            // Gradient overlays for legibility
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 300)
            }
            .ignoresSafeArea()

            // Main UI
            VStack(spacing: 0) {
                headerBar
                Spacer()
                viewfinder
                Spacer()
                bottomPanel
            }

            // Saved banner
            if vm.mostrarGuardado {
                VStack {
                    savedBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 60)
                .zIndex(10)
            }
        }
        .task {
            vm.store = store
            await camera.solicitarPermiso()
        }
        .onChange(of: camera.frameCount) { _, _ in
            guard let frame = camera.currentFrame else { return }
            vm.processFrame(frame)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            // Ticket badge
            if !vm.materialesTicket.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "bag.fill")
                        .font(.caption)
                    Text("\(vm.materialesTicket.count)")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }

            Spacer()

            Text("CIRRCULO")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.9))
                .tracking(1.5)

            Spacer()

            // Live indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.isAnalyzing ? .orange : .green)
                    .frame(width: 7, height: 7)
                    .shadow(color: vm.isAnalyzing ? .orange : .green, radius: 4)
                Text(vm.isAnalyzing ? "Analizando" : "En vivo")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Viewfinder

    private var viewfinder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(activeColor.opacity(0.6), lineWidth: 2)
                .frame(width: 260, height: 260)
                .shadow(color: activeColor.opacity(0.2), radius: 12)

            ScannerCornerBrackets(color: activeColor)
                .frame(width: 260, height: 260)

            if let r = vm.resultado, !r.esAmbiguo {
                VStack(spacing: 8) {
                    Image(systemName: iconForTipo(r.tipo))
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(activeColor)
                        .padding(18)
                        .background(activeColor.opacity(0.15))
                        .clipShape(Circle())
                        .background(
                            Circle()
                                .stroke(activeColor.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 76, height: 76)
                        )
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.35), value: r.tipo)
            }
        }
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            if vm.showDisambiguation {
                disambiguationCard
            } else if let r = vm.resultado, !r.esAmbiguo {
                resultCard(r)
            } else if let r = vm.resultado, r.esAmbiguo && !vm.showDisambiguation {
                // Brief result while disambiguation loads
                resultCardMinimal(r)
            } else {
                placeholderPill
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: vm.showDisambiguation)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: vm.resultado?.tipo)
        .padding(.horizontal, 16)
        .padding(.bottom, 36)
    }

    // MARK: - Result Card

    private func resultCard(_ r: ResultadoClasificacion) -> some View {
        VStack(spacing: 14) {
            // Material + container
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: r.contenedor.colorHex).opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: iconForTipo(r.tipo))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color(hex: r.contenedor.colorHex))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(r.tipo.rawValue)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    if !r.objetoDetectado.isEmpty {
                        Text("Detectado: \(r.objetoDetectado)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: r.contenedor.colorHex))
                            .frame(width: 8, height: 8)
                        Text("Contenedor \(r.contenedor.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(r.proximaRecoleccion)
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: r.contenedor.colorHex))
                    Text("recolección")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Instructions
            if let ins = vm.instruccionesDinamicas {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text(ins)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(3)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Container destination bar
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(Color(hex: r.contenedor.colorHex))
                Text("Depositar en contenedor \(r.contenedor.rawValue.lowercased())")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: r.contenedor.colorHex).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Save button
            Button {
                vm.guardarEnTicket(r)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Guardar en ticket  +\(Int(0.5 * Double(r.tipo.puntosPorKg))) pts")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: r.contenedor.colorHex))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func resultCardMinimal(_ r: ResultadoClasificacion) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconForTipo(r.tipo))
                .font(.title3)
                .foregroundStyle(Color(hex: r.contenedor.colorHex))
                .frame(width: 42, height: 42)
                .background(Color(hex: r.contenedor.colorHex).opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(r.tipo.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("Analizando...")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            ProgressView()
                .tint(.white)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Disambiguation Card

    private var disambiguationCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
                Text("Ayuda a clasificar")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                Spacer()
                Button { vm.dismissDisambiguation() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            if vm.isGeneratingQuestion {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.white)
                    Text("Generando pregunta...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.vertical, 12)
            } else if let question = vm.disambiguationQuestion {
                Text(question)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if vm.candidatos.count >= 2 && !vm.isGeneratingQuestion {
                HStack(spacing: 10) {
                    ForEach(vm.candidatos.prefix(2), id: \.self) { tipo in
                        Button { vm.selectCategory(tipo) } label: {
                            HStack(spacing: 6) {
                                Image(systemName: iconForTipo(tipo))
                                    .font(.caption)
                                Text(tipo.rawValue)
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: tipo.contenedor.colorHex).opacity(0.2))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: tipo.contenedor.colorHex).opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Placeholder

    private var placeholderPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "viewfinder")
                .font(.subheadline)
            Text("Apunta la cámara a un residuo")
                .font(.subheadline)
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(.vertical, 14)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(Capsule())
    }

    // MARK: - Saved Banner

    private var savedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(vm.ptsGuardados > 0 ? "+\(vm.ptsGuardados) pts guardados" : "Guardado en ticket")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    // MARK: - Helpers

    private func iconForTipo(_ tipo: TipoResiduo) -> String {
        switch tipo {
        case .plasticoPET, .plasticoHDPE: return "waterbottle.fill"
        case .carton:          return "shippingbox.fill"
        case .papel:           return "doc.fill"
        case .vidrio:          return "wineglass.fill"
        case .aluminio, .lata: return "cylinder.fill"
        case .organicoComida:  return "leaf.fill"
        case .organicoPoda:    return "tree.fill"
        case .electronico:     return "bolt.fill"
        case .textil:          return "tshirt.fill"
        case .noReciclable:    return "xmark.bin.fill"
        case .tetraPak:        return "takeoutbag.and.cup.and.straw.fill"
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Corner Brackets

struct ScannerCornerBrackets: View {
    let color: Color
    private let len: CGFloat = 30
    private let thick: CGFloat = 3.5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let style = StrokeStyle(lineWidth: thick, lineCap: .round)
            Path { p in p.move(to: .init(x: 0, y: len)); p.addLine(to: .zero); p.addLine(to: .init(x: len, y: 0)) }.stroke(color, style: style)
            Path { p in p.move(to: .init(x: w-len, y: 0)); p.addLine(to: .init(x: w, y: 0)); p.addLine(to: .init(x: w, y: len)) }.stroke(color, style: style)
            Path { p in p.move(to: .init(x: 0, y: h-len)); p.addLine(to: .init(x: 0, y: h)); p.addLine(to: .init(x: len, y: h)) }.stroke(color, style: style)
            Path { p in p.move(to: .init(x: w-len, y: h)); p.addLine(to: .init(x: w, y: h)); p.addLine(to: .init(x: w, y: h-len)) }.stroke(color, style: style)
        }
    }
}

#Preview {
    ScannerView()
}
