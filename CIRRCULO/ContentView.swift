import SwiftUI
import UIKit
import Vision
import CoreML
import Combine
import AVFoundation
import FoundationModels

// MARK: - Categorías de residuos
enum WasteCategory: String, CaseIterable {
    case organic = "Orgánico"
    case plastic = "Plástico"
    case glass = "Vidrio / Cristal"
    case metal = "Metal"
    case paper = "Papel"
    case cardboard = "Cartón"
    case electronic = "Electrónico"
    case textile = "Textil"
    case unknown = "No identificado"

    var icon: String {
        switch self {
        case .organic: return "leaf.fill"
        case .plastic: return "waterbottle.fill"
        case .glass: return "wineglass.fill"
        case .metal: return "cylinder.fill"
        case .paper: return "doc.fill"
        case .cardboard: return "shippingbox.fill"
        case .electronic: return "bolt.fill"
        case .textile: return "tshirt.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .organic: return .green
        case .plastic: return .blue
        case .glass: return .cyan
        case .metal: return .gray
        case .paper: return .mint
        case .cardboard: return .brown
        case .electronic: return .yellow
        case .textile: return .purple
        case .unknown: return .orange
        }
    }

    var bin: String {
        switch self {
        case .organic: return "Contenedor Verde"
        case .plastic: return "Contenedor Amarillo"
        case .glass: return "Contenedor Blanco"
        case .metal: return "Contenedor Amarillo"
        case .paper: return "Contenedor Azul"
        case .cardboard: return "Contenedor Azul"
        case .electronic: return "Punto Limpio"
        case .textile: return "Contenedor Textil"
        case .unknown: return "Verificar manualmente"
        }
    }
}

// MARK: - Modelo de resultado
struct ClassificationResult: Identifiable {
    let id = UUID()
    let category: WasteCategory
    let confidence: Float
    let detectedObject: String
}

// MARK: - Modelo de pregunta de desambiguación
struct DisambiguationQuestion {
    let question: String
    let option1: (label: String, category: WasteCategory)
    let option2: (label: String, category: WasteCategory)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - WasteClassifier (Servicio compartido)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class WasteClassifier {
    static let shared = WasteClassifier()

    struct Result {
        let category: WasteCategory
        let detectedObject: String
        let confidence: Float
        let isAmbiguous: Bool
        let topVisionTags: [String]  // tags para contexto del Foundation Model
        let candidateCategories: [WasteCategory] // las 2 categorías más probables
    }

    // ... (Keywords stay same)
    private let organicKeywords: Set<String> = [
        "fruit", "apple", "banana", "orange", "lemon", "grape", "strawberry", "pear",
        "peach", "mango", "watermelon", "pineapple", "cherry", "berry", "melon",
        "avocado", "coconut", "kiwi", "plum", "fig", "lime", "papaya", "guava",
        "vegetable", "carrot", "tomato", "potato", "onion", "lettuce", "broccoli",
        "corn", "pepper", "cucumber", "mushroom", "garlic", "celery", "spinach",
        "cabbage", "squash", "zucchini", "eggplant", "beet", "radish", "turnip",
        "food", "bread", "egg", "meat", "fish", "chicken", "rice", "pasta", "cheese",
        "cake", "pizza", "sandwich", "salad", "soup", "sushi", "taco", "burrito",
        "cookie", "donut", "pie", "cereal", "yogurt", "butter", "cream", "sauce",
        "noodle", "dumpling", "waffle", "pancake", "pretzel", "croissant", "bagel",
        "leaf", "flower", "plant", "tree", "grass", "seed", "nut", "coffee", "tea",
        "wood", "stick", "shell", "bark", "hay", "compost", "soil", "dirt",
        "herb", "spice", "grain", "bean", "lentil", "pea",
        "juice", "smoothie", "milkshake"
    ]

    private let plasticKeywords: Set<String> = [
        "plastic", "wrapper", "packaging", "toy", "pen", "lighter",
        "toothbrush", "comb", "hanger", "tupperware",
        "syringe", "crayon", "marker", "eraser", "ruler"
    ]

    private let glassKeywords: Set<String> = [
        "glass", "jar", "mirror", "vase", "crystal", "window",
        "lamp", "bulb", "spectacles", "eyeglasses", "lens",
        "wine", "beer", "champagne", "whiskey", "cocktail", "liquor",
        "goblet", "tumbler", "chalice", "carafe", "decanter",
        "drinkware", "drinking", "stemware", "wineglass", "pint",
        "ceramic", "porcelain", "pottery", "stoneware", "earthenware",
        "transparent", "translucent", "glassware"
    ]

    private let metalKeywords: Set<String> = [
        "can", "tin", "aluminum", "metal", "steel", "iron", "copper", "wire",
        "nail", "screw", "key", "coin", "fork", "knife", "spoon", "pan", "pot",
        "foil", "chain", "wrench", "bolt",
        "razor", "blade", "scissors", "needle", "pin", "staple",
        "faucet", "pipe", "hinge", "lock", "padlock", "hook",
        "weight", "dumbbell", "medal", "trophy",
        "brass", "bronze", "chrome", "silver", "gold"
    ]

    private let paperKeywords: Set<String> = [
        "paper", "newspaper", "magazine", "envelope", "tissue", "napkin",
        "receipt", "notebook", "document", "letter", "label", "poster",
        "flyer", "brochure", "page", "sheet", "scroll", "note", "memo",
        "ticket", "stamp", "sticker", "banner", "sign", "menu",
        "bookmark", "postcard", "invitation", "certificate", "diploma",
        "newsprint", "text", "writing", "handwriting", "manuscript",
        "journal", "diary", "comic", "sketch", "drawing", "photograph",
        "calendar", "map", "print", "origami", "confetti"
    ]

    private let cardboardKeywords: Set<String> = [
        "cardboard", "carton", "box", "packaging", "corrugated",
        "shipping", "crate", "parcel", "package"
    ]

    private let electronicKeywords: Set<String> = [
        "phone", "computer", "laptop", "keyboard", "mouse", "cable", "charger",
        "television", "monitor", "speaker", "headphone", "camera", "remote",
        "circuit", "chip", "usb", "disk", "drive", "tablet", "console",
        "router", "modem", "printer", "scanner", "projector", "microphone",
        "earphone", "earbud", "smartwatch", "drone", "controller", "joystick",
        "screen", "display", "led", "lcd", "electronic", "digital", "device",
        "adapter", "plug", "socket", "switch", "sensor", "antenna"
    ]

    private let textileKeywords: Set<String> = [
        "clothing", "shirt", "pants", "shoe", "sock", "hat", "jacket", "dress",
        "fabric", "cloth", "towel", "blanket", "curtain", "carpet", "rug",
        "pillow", "glove", "scarf", "tie", "belt", "sweater", "hoodie",
        "jeans", "shorts", "skirt", "coat", "vest", "blouse", "uniform",
        "linen", "cotton", "wool", "silk", "denim", "leather", "suede",
        "yarn", "thread", "ribbon", "lace", "velvet", "satin", "nylon",
        "polyester", "fleece", "knit", "woven", "textile", "garment", "apparel"
    ]

    private let trashNetMapping: [String: WasteCategory] = [
        "plastic": .plastic, "glass": .glass, "metal": .metal,
        "paper": .paper, "cardboard": .cardboard, "trash": .organic
    ]

    private lazy var keywordSets: [(WasteCategory, Set<String>)] = [
        (.organic, organicKeywords), (.plastic, plasticKeywords),
        (.glass, glassKeywords), (.metal, metalKeywords),
        (.paper, paperKeywords), (.cardboard, cardboardKeywords),
        (.electronic, electronicKeywords), (.textile, textileKeywords)
    ]

    private var cachedModel: VNCoreMLModel?

    private func getTrashNet() -> VNCoreMLModel? {
        if let m = cachedModel { return m }
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let model = try VNCoreMLModel(for: BioTraceClassifier_1(configuration: config).model)
            cachedModel = model
            return model
        } catch { return nil }
    }

    func classify(cgImage: CGImage, orientation: CGImagePropertyOrientation = .up, completion: @escaping (Result) -> Void) {
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        let request = VNClassifyImageRequest { [weak self] req, _ in
            guard let self = self,
                  let results = req.results as? [VNClassificationObservation] else {
                DispatchQueue.main.async { completion(Result(category: .unknown, detectedObject: "Desconocido", confidence: 0, isAmbiguous: false, topVisionTags: [], candidateCategories: [])) }
                return
            }

            let significant = results.filter { $0.confidence > 0.03 }.sorted { $0.confidence > $1.confidence }
            guard !significant.isEmpty else {
                DispatchQueue.main.async { completion(Result(category: .unknown, detectedObject: "Desconocido", confidence: 0, isAmbiguous: false, topVisionTags: [], candidateCategories: [])) }
                return
            }

            let (visionCat, scores) = self.mapVision(significant)
            let top = significant[0]
            let name = top.identifier.replacingOccurrences(of: "_", with: " ").capitalized
            let topScore = scores.values.max() ?? 0

            // Tags para contexto del Foundation Model
            let topTags = significant.prefix(10).map { $0.identifier }

            // Top 2 categorías candidatas
            let sortedCats = scores.sorted { $0.value > $1.value }
            let candidates = Array(sortedCats.prefix(2).map { $0.key })

            // Detectar ambiguedad: las 2 top categorías están cerca en score
            let isAmbiguous: Bool = {
                guard sortedCats.count >= 2 else { return false }
                let first = sortedCats[0].value
                let second = sortedCats[1].value
                return second > first * 0.4 // segunda categoría tiene >40% del score de la primera
            }()

            let trusted: Set<WasteCategory> = [.organic, .electronic, .textile]
            if trusted.contains(visionCat) || topScore >= 0.5 {
                DispatchQueue.main.async {
                    completion(Result(category: visionCat, detectedObject: name, confidence: top.confidence,
                                     isAmbiguous: isAmbiguous && !trusted.contains(visionCat),
                                     topVisionTags: topTags, candidateCategories: candidates))
                }
                return
            }

            self.classifyMaterial(cgImage: cgImage, orientation: orientation) { material in
                let final = material ?? visionCat
                DispatchQueue.main.async {
                    completion(Result(category: final, detectedObject: name, confidence: top.confidence,
                                     isAmbiguous: true, topVisionTags: topTags, candidateCategories: candidates))
                }
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    private func classifyMaterial(cgImage: CGImage, orientation: CGImagePropertyOrientation, completion: @escaping (WasteCategory?) -> Void) {
        guard let model = getTrashNet() else { completion(nil); return }

        let request = VNCoreMLRequest(model: model) { [weak self] req, _ in
            guard let results = req.results as? [VNClassificationObservation],
                  let top = results.first, top.confidence > 0.35 else { completion(nil); return }
            completion(self?.trashNetMapping[top.identifier])
        }
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        DispatchQueue.global(qos: .userInitiated).async { try? handler.perform([request]) }
    }

    private func mapVision(_ observations: [VNClassificationObservation]) -> (WasteCategory, [WasteCategory: Float]) {
        var scores: [WasteCategory: Float] = [:]
        for obs in observations.prefix(20) {
            let tokens = obs.identifier.lowercased().split(separator: "_").map(String.init) + [obs.identifier.lowercased()]
            for (cat, kw) in keywordSets {
                for t in tokens where kw.contains(t) {
                    scores[cat, default: 0] += obs.confidence
                }
            }
        }
        guard let best = scores.max(by: { $0.value < $1.value }), best.value > 0.03 else {
            return (.unknown, scores)
        }
        return (best.key, scores)
    }

    // ── Lógica de Desambiguación compartida ──

    func generateQuestion(result: Result) async -> DisambiguationQuestion {
        let candidates = result.candidateCategories
        let tags = result.topVisionTags.prefix(8).joined(separator: ", ")
        let object = result.detectedObject
        
        var questionText: String?
        
        if #available(iOS 26.0, *) {
            questionText = await askFoundationModel(object: object, tags: tags, cat1: candidates[0], cat2: candidates[1])
        }
        
        if questionText == nil {
            questionText = generateFallbackQuestion(object: object, cat1: candidates[0], cat2: candidates[1])
        }
        
        return DisambiguationQuestion(
            question: questionText ?? "¿De qué material es este objeto?",
            option1: (label: candidates[0].rawValue, category: candidates[0]),
            option2: (label: candidates[1].rawValue, category: candidates[1])
        )
    }

    @available(iOS 26.0, *)
    private func askFoundationModel(object: String, tags: String, cat1: WasteCategory, cat2: WasteCategory) async -> String? {
        do {
            let session = LanguageModelSession()
            let prompt = """
            Eres BioTrace, un asistente de clasificación de residuos. \
            La cámara detectó un objeto con estas características: \(tags). \
            Parece ser: \(object). No estoy seguro si es \(cat1.rawValue) o \(cat2.rawValue). \
            Genera UNA sola pregunta corta y directa en español para que el usuario me ayude a decidir. \
            La pregunta debe ser natural, amigable y específica al objeto detectado. \
            Solo responde con la pregunta, nada más.
            """
            let response = try await session.respond(to: prompt)
            return response.content
        } catch { return nil }
    }

    private func generateFallbackQuestion(object: String, cat1: WasteCategory, cat2: WasteCategory) -> String {
        let pair = Set([cat1, cat2])
        if pair == Set([.glass, .plastic]) {
            return "Veo un \(object.lowercased()). ¿Es de cristal/vidrio o de plástico?"
        } else if pair == Set([.paper, .cardboard]) {
            return "Detecto \(object.lowercased()). ¿Es papel delgado o cartón grueso?"
        } else {
            return "Detecto un \(object.lowercased()). ¿Es \(cat1.rawValue.lowercased()) o \(cat2.rawValue.lowercased())?"
        }
    }

    // ── User Feedback Flow (Simulación de entrenamiento en la nube) ──

    func submitFeedback(object: String, correctCategory: WasteCategory, tags: [String]) {
        print("☁️ [BioTrace Cloud] Feedback recibido: Objeto '\(object)' confirmado como \(correctCategory.rawValue).")
        print("☁️ Contexto de Vision: \(tags.joined(separator: ", "))")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            print("✅ [BioTrace Cloud] Datos integrados para el próximo ciclo de entrenamiento del tensor.")
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ViewModel para foto
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ScannerViewModel: ObservableObject {
    @Published var resultText = "Toma una foto para analizar..."
    @Published var confidence: String = ""
    @Published var topResult: ClassificationResult?
    @Published var isLowConfidence = false
    // Desambiguación en modo foto
    @Published var showDisambiguation = false
    @Published var disambiguationQuestion: DisambiguationQuestion?
    @Published var isGeneratingQuestion = false
    
    private var lastResult: WasteClassifier.Result?

    func classify(image: UIImage) {
        resultText = "Analizando..."
        confidence = ""
        topResult = nil
        isLowConfidence = false
        showDisambiguation = false
        disambiguationQuestion = nil

        let fixed = image.fixedOrientation()
        guard let cg = fixed.cgImage else { return }
        let orient = CGImagePropertyOrientation(fixed.imageOrientation)

        WasteClassifier.shared.classify(cgImage: cg, orientation: orient) { [weak self] r in
            guard let self = self else { return }
            self.lastResult = r
            self.topResult = ClassificationResult(category: r.category, confidence: r.confidence, detectedObject: r.detectedObject)

            if r.category == .unknown {
                self.isLowConfidence = true
                self.resultText = "No identificado"
                self.confidence = "Objeto: \(r.detectedObject)"
            } else if r.isAmbiguous && r.candidateCategories.count >= 2 {
                self.resultText = r.category.rawValue
                self.confidence = "Detectado: \(r.detectedObject)"
                self.triggerDisambiguation(result: r)
            } else {
                self.resultText = r.category.rawValue
                self.confidence = "Detectado: \(r.detectedObject) → \(r.category.bin)"
            }
        }
    }

    private func triggerDisambiguation(result: WasteClassifier.Result) {
        isGeneratingQuestion = true
        showDisambiguation = true

        Task {
            let question = await WasteClassifier.shared.generateQuestion(result: result)
            await MainActor.run {
                self.disambiguationQuestion = question
                self.isGeneratingQuestion = false
            }
        }
    }

    func selectCategory(_ category: WasteCategory) {
        if let res = lastResult {
            WasteClassifier.shared.submitFeedback(object: res.detectedObject, correctCategory: category, tags: res.topVisionTags)
        }
        
        topResult = ClassificationResult(category: category, confidence: 1.0, detectedObject: topResult?.detectedObject ?? "")
        resultText = category.rawValue
        confidence = "Confirmado por usuario → \(category.bin)"
        showDisambiguation = false
        disambiguationQuestion = nil
    }
}

// MARK: - Fix orientación
extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return img
    }
}

extension CGImagePropertyOrientation {
    init(_ ui: UIImage.Orientation) {
        switch ui {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Live Scanner (Tiempo Real)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class LiveScannerViewModel: ObservableObject {
    @Published var category: WasteCategory = .unknown
    @Published var detectedObject: String = ""
    @Published var isAnalyzing = false
    // Desambiguación
    @Published var showDisambiguation = false
    @Published var disambiguationQuestion: DisambiguationQuestion?
    @Published var isGeneratingQuestion = false
    @Published var isPaused = false // pausar análisis mientras pregunta

    private var lastTime: Date = .distantPast
    private var lastResult: WasteClassifier.Result?

    func processFrame(_ buffer: CMSampleBuffer) {
        let now = Date()
        guard now.timeIntervalSince(lastTime) >= 0.8, !isAnalyzing, !isPaused else { return }
        lastTime = now

        guard let pb = CMSampleBufferGetImageBuffer(buffer) else { return }
        let ci = CIImage(cvPixelBuffer: pb)
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(ci, from: ci.extent) else { return }

        DispatchQueue.main.async { self.isAnalyzing = true }

        WasteClassifier.shared.classify(cgImage: cg) { [weak self] r in
            guard let self = self else { return }
            self.lastResult = r
            self.category = r.category
            self.detectedObject = r.detectedObject
            self.isAnalyzing = false

            // Si es ambiguo y hay al menos 2 candidatos → preguntar al usuario
            if r.isAmbiguous && r.candidateCategories.count >= 2 && !self.showDisambiguation {
                self.triggerDisambiguation(result: r)
            }
        }
    }

    private func triggerDisambiguation(result: WasteClassifier.Result) {
        isPaused = true
        isGeneratingQuestion = true
        showDisambiguation = true

        Task {
            let question = await WasteClassifier.shared.generateQuestion(result: result)
            await MainActor.run {
                self.disambiguationQuestion = question
                self.isGeneratingQuestion = false
            }
        }
    }

    func selectCategory(_ category: WasteCategory) {
        if let res = lastResult {
            WasteClassifier.shared.submitFeedback(object: res.detectedObject, correctCategory: category, tags: res.topVisionTags)
        }
        
        self.category = category
        self.showDisambiguation = false
        self.disambiguationQuestion = nil
        // Pausar 3 segundos para mostrar el resultado antes de reanudar
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isPaused = false
        }
    }

    func dismissDisambiguation() {
        showDisambiguation = false
        disambiguationQuestion = nil
        isPaused = false
    }
}

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    var onFrame: ((CMSampleBuffer) -> Void)?
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera", qos: .userInitiated)

    func configure() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: cam),
              session.canAddInput(input) else { session.commitConfiguration(); return }
        session.addInput(input)

        output.setSampleBufferDelegate(self, queue: queue)
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }

        if let conn = output.connection(with: .video), conn.isVideoRotationAngleSupported(90) {
            conn.videoRotationAngle = 90
        }

        session.commitConfiguration()
    }

    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.session.stopRunning() }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput buffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onFrame?(buffer)
    }
}

// UIView que auto-resizea el preview layer (fix pantalla blanca)
class VideoPreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func setup(session: AVCaptureSession) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.addSublayer(layer)
        self.previewLayer = layer
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.setup(session: session)
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.previewLayer?.frame = uiView.bounds
    }
}

struct LiveScannerView: View {
    @StateObject private var viewModel = LiveScannerViewModel()
    @StateObject private var camera = CameraManager()
    @Environment(\.dismiss) private var dismiss

    private var activeColor: Color {
        viewModel.category == .unknown ? .white.opacity(0.4) : viewModel.category.color
    }

    var body: some View {
        ZStack {
            // Fondo negro mientras carga la cámara
            Color.black.ignoresSafeArea()

            // Cámara
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            // Gradientes para legibilidad
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 140)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 250)
            }
            .ignoresSafeArea()

            // UI
            VStack(spacing: 0) {
                // ── Header ──
                HStack {
                    Button { camera.stop(); dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Text("BioTrace Scanner")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    // Indicador live
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.isAnalyzing ? .orange : .green)
                            .frame(width: 8, height: 8)
                            .shadow(color: viewModel.isAnalyzing ? .orange : .green, radius: 4)
                        Text(viewModel.isAnalyzing ? "Analizando" : "En vivo")
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // ── Visor central ──
                ZStack {
                    // Marco con esquinas animadas
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(activeColor, lineWidth: 3)
                        .frame(width: 280, height: 280)
                        .shadow(color: activeColor.opacity(0.3), radius: 10)

                    CornerBrackets(color: activeColor)
                        .frame(width: 280, height: 280)

                    // Icono de categoría en el centro cuando detecta algo
                    if viewModel.category != .unknown {
                        Image(systemName: viewModel.category.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(viewModel.category.color)
                            .padding(20)
                            .background(viewModel.category.color.opacity(0.15))
                            .clipShape(Circle())
                            .background(
                                Circle()
                                    .stroke(viewModel.category.color.opacity(0.3), lineWidth: 2)
                                    .frame(width: 90, height: 90)
                            )
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(duration: 0.3), value: viewModel.category)
                    }
                }

                Spacer()

                // ── Resultado inferior ──
                VStack(spacing: 12) {
                    // Pregunta de desambiguación con IA
                    if viewModel.showDisambiguation {
                        VStack(spacing: 14) {
                            // Header de la pregunta
                            HStack(spacing: 8) {
                                Image(systemName: "brain.head.profile.fill")
                                    .foregroundStyle(.orange)
                                Text("BioTrace necesita tu ayuda")
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)
                                Spacer()
                                Button { viewModel.dismissDisambiguation() } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }

                            if viewModel.isGeneratingQuestion {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Analizando objeto...")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(.vertical, 8)
                            } else if let q = viewModel.disambiguationQuestion {
                                // Pregunta generada por IA
                                Text(q.question)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)

                                // Botones de respuesta
                                HStack(spacing: 12) {
                                    Button {
                                        viewModel.selectCategory(q.option1.category)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: q.option1.category.icon)
                                            Text(q.option1.label)
                                        }
                                        .font(.subheadline.bold())
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(q.option1.category.color.opacity(0.3))
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }

                                    Button {
                                        viewModel.selectCategory(q.option2.category)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: q.option2.category.icon)
                                            Text(q.option2.label)
                                        }
                                        .font(.subheadline.bold())
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(q.option2.category.color.opacity(0.3))
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    } else if viewModel.category != .unknown {
                        // Categoría detectada
                        VStack(spacing: 16) {
                            HStack(spacing: 14) {
                                Image(systemName: viewModel.category.icon)
                                    .font(.title2)
                                    .foregroundStyle(viewModel.category.color)
                                    .frame(width: 48, height: 48)
                                    .background(viewModel.category.color.opacity(0.2))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(viewModel.category.rawValue)
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                    Text("Detectado: \(viewModel.detectedObject)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }

                                Spacer()
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(viewModel.category.color)
                                Text(viewModel.category.bin)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white.opacity(0.9))
                                Spacer()
                            }
                            .padding(12)
                            .background(viewModel.category.color.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .animation(.spring(duration: 0.4), value: viewModel.category)
                    } else {
                        // Instrucción
                        HStack(spacing: 10) {
                            Image(systemName: "viewfinder")
                                .font(.title3)
                            Text("Apunta la cámara al residuo")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(.ultraThinMaterial.opacity(0.5))
                        .clipShape(Capsule())
                    }
                }
                .animation(.spring(duration: 0.4), value: viewModel.showDisambiguation)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .statusBarHidden()
        .onAppear {
            camera.configure()
            camera.onFrame = { [weak viewModel] buf in viewModel?.processFrame(buf) }
            camera.start()
        }
        .onDisappear { camera.stop() }
    }
}

// MARK: - Esquinas del visor
struct CornerBrackets: View {
    let color: Color
    private let len: CGFloat = 35
    private let thick: CGFloat = 4

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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Vista Principal
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ContentView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @State private var image: UIImage?
    @State private var showingCamera = false
    @State private var showingLiveScanner = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "leaf.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                    Text("BioTrace")
                        .font(.largeTitle.bold())
                }
                .padding(.top)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .frame(width: 300, height: 300)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 50))
                                Text("Escanea un residuo")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        )
                }

                if let result = viewModel.topResult {
                    VStack(spacing: 16) {
                        HStack(spacing: 14) {
                            Image(systemName: result.category.icon)
                                .font(.title)
                                .foregroundStyle(result.category.color)
                                .frame(width: 52, height: 52)
                                .background(result.category.color.opacity(0.15))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.category.rawValue)
                                    .font(.title2.bold())
                                Text(viewModel.confidence)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(result.category.color.opacity(0.08)))

                        // Desambiguación en modo foto
                        if viewModel.showDisambiguation {
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "brain.head.profile.fill")
                                        .foregroundStyle(.orange)
                                    Text("BioTrace necesita tu ayuda")
                                        .font(.caption.bold())
                                        .foregroundStyle(.orange)
                                    Spacer()
                                }

                                if viewModel.isGeneratingQuestion {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                        Text("Generando pregunta...")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                } else if let q = viewModel.disambiguationQuestion {
                                    Text(q.question)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)

                                    HStack(spacing: 12) {
                                        Button {
                                            viewModel.selectCategory(q.option1.category)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: q.option1.category.icon)
                                                Text(q.option1.label)
                                            }
                                            .font(.subheadline.bold())
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(q.option1.category.color.opacity(0.15))
                                            .foregroundStyle(q.option1.category.color)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }

                                        Button {
                                            viewModel.selectCategory(q.option2.category)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: q.option2.category.icon)
                                                Text(q.option2.label)
                                            }
                                            .font(.subheadline.bold())
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(q.option2.category.color.opacity(0.15))
                                            .foregroundStyle(q.option2.category.color)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.orange.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.2)))
                        } else if result.category != .unknown {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(result.category.color)
                                Text("Depositar en: **\(result.category.bin)**")
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                        }
                    }
                    .padding(.horizontal)
                    .animation(.spring(duration: 0.4), value: viewModel.showDisambiguation)
                } else {
                    Text(viewModel.resultText)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding()
                }

                Spacer(minLength: 20)

                VStack(spacing: 12) {
                    Button { showingLiveScanner = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "video.fill")
                            Text("Scanner en Vivo")
                        }
                        .font(.title3.bold())
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button { showingCamera = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                            Text("Tomar Foto")
                        }
                        .font(.title3.bold())
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $image)
        }
        .fullScreenCover(isPresented: $showingLiveScanner) {
            LiveScannerView()
        }
        .onChange(of: image) { _, newImage in
            if let img = newImage { viewModel.classify(image: img) }
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.image = img }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview { ContentView() }
