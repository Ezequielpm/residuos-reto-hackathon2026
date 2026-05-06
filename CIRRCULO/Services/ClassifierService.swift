import Vision
import CoreML
import CoreImage

/// Servicio de clasificación de residuos.
/// Port 1:1 de la lógica de WasteClassifier del ContentView:
/// Vision keywords → categoría intermedia → si trusted/alto score retorna directo →
/// sino BioTraceClassifier decide el material.
final class ClassifierService {

    static let shared = ClassifierService()
    private init() {}

    // MARK: - Resultado enriquecido

    struct ResultadoEnriquecido {
        let resultado: ResultadoClasificacion
        let candidatos: [TipoResiduo]
        let topVisionTags: [String]
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - BioTraceClassifier model (lazy load)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var cachedModel: VNCoreMLModel?

    private func getBioTraceModel() -> VNCoreMLModel? {
        if let m = cachedModel { return m }
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let model = try VNCoreMLModel(for: BioTraceClassifier_1(configuration: config).model)
            cachedModel = model
            return model
        } catch {
            print("⚠️ No se pudo cargar BioTraceClassifier: \(error)")
            return nil
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Keywords (idénticos al WasteClassifier original)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Categoría intermedia (= WasteCategory del ContentView)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private enum Cat: String, Hashable {
        case organic, plastic, glass, metal, paper, cardboard, electronic, textile, unknown

        func toTipoResiduo() -> TipoResiduo {
            switch self {
            case .organic:    return .organicoComida
            case .plastic:    return .plasticoPET
            case .glass:      return .vidrio
            case .metal:      return .aluminio
            case .paper:      return .papel
            case .cardboard:  return .carton
            case .electronic: return .electronico
            case .textile:    return .textil
            case .unknown:    return .noReciclable
            }
        }
    }

    private lazy var keywordSets: [(Cat, Set<String>)] = [
        (.organic, organicKeywords), (.plastic, plasticKeywords),
        (.glass, glassKeywords), (.metal, metalKeywords),
        (.paper, paperKeywords), (.cardboard, cardboardKeywords),
        (.electronic, electronicKeywords), (.textile, textileKeywords)
    ]

    private let bioTraceMapping: [String: TipoResiduo] = [
        "plastic": .plasticoPET,
        "glass":   .vidrio,
        "metal":   .aluminio,
        "paper":   .papel,
        "cardboard": .carton,
        "trash":   .noReciclable
    ]

    private let trustedCategories: Set<Cat> = [.organic, .electronic, .textile]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - API pública
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// Clasificación desde CGImage — método principal.
    /// Replica exactamente WasteClassifier.classify() del ContentView.
    func clasificar(cgImage: CGImage, orientation: CGImagePropertyOrientation = .up,
                    completion: @escaping (ResultadoEnriquecido) -> Void) {

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        let request = VNClassifyImageRequest { [weak self] req, _ in
            guard let self,
                  let results = req.results as? [VNClassificationObservation] else {
                return
            }

            // 1) Filtrar tags significativos (> 3% confianza)
            let significant = results
                .filter { $0.confidence > 0.03 }
                .sorted { $0.confidence > $1.confidence }

            guard !significant.isEmpty else { return }

            // 2) Keyword matching sobre los top 20 tags
            let (visionCat, scores) = self.mapVision(significant)

            // 3) Info del resultado top
            let top = significant[0]
            let topScore = scores.values.max() ?? 0
            let detectedName = top.identifier
                .replacingOccurrences(of: "_", with: " ")
                .capitalized

            // 4) Tags para contexto de Foundation Model
            let topTags = Array(significant.prefix(10).map { $0.identifier })

            // 5) Top 2 categorías candidatas
            let sortedCats = scores.sorted { $0.value > $1.value }
            let candidates = Array(sortedCats.prefix(2).map { $0.key })
            let candidatos = candidates.map { $0.toTipoResiduo() }

            // 6) Detectar ambigüedad: segunda categoría tiene >40% del score de la primera
            let isAmbiguous: Bool = {
                guard sortedCats.count >= 2 else { return false }
                let first = sortedCats[0].value
                let second = sortedCats[1].value
                return second > first * 0.4
            }()

            // 7) DECISIÓN — igual que WasteClassifier:
            //    trusted (orgánico/electrónico/textil) o score alto → retornar directo
            if self.trustedCategories.contains(visionCat) || topScore >= 0.5 {
                let tipo = visionCat.toTipoResiduo()
                // Trusted + no ambiguo → boost confianza para evitar falsa ambigüedad
                let confianza: Float
                if self.trustedCategories.contains(visionCat) {
                    confianza = max(top.confidence, 0.75)
                } else {
                    confianza = top.confidence
                }
                // Trusted categories nunca marcan ambigüedad
                let finalAmbiguous = isAmbiguous && !self.trustedCategories.contains(visionCat)
                let finalConfianza = finalAmbiguous ? min(confianza, 0.65) : confianza

                let resultado = self.buildResultado(tipo: tipo, confianza: finalConfianza, objetoDetectado: detectedName)
                DispatchQueue.main.async {
                    completion(ResultadoEnriquecido(
                        resultado: resultado,
                        candidatos: candidatos.isEmpty ? [tipo] : candidatos,
                        topVisionTags: topTags
                    ))
                }
                return
            }

            // 8) FALLBACK — Vision no está seguro → BioTraceClassifier decide el material
            self.clasificarConBioTrace(cgImage: cgImage, orientation: orientation) { bioTraceTipo in
                let finalTipo = bioTraceTipo ?? visionCat.toTipoResiduo()
                let resultado = self.buildResultado(
                    tipo: finalTipo,
                    confianza: top.confidence,
                    objetoDetectado: detectedName
                )
                DispatchQueue.main.async {
                    completion(ResultadoEnriquecido(
                        resultado: resultado,
                        candidatos: candidatos.isEmpty ? [finalTipo] : candidatos,
                        topVisionTags: topTags
                    ))
                }
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - BioTraceClassifier (CoreML material detection)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func clasificarConBioTrace(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        completion: @escaping (TipoResiduo?) -> Void
    ) {
        guard let model = getBioTraceModel() else { completion(nil); return }

        let request = VNCoreMLRequest(model: model) { [weak self] req, _ in
            guard let results = req.results as? [VNClassificationObservation],
                  let top = results.first,
                  top.confidence > 0.35 else {
                completion(nil)
                return
            }
            completion(self?.bioTraceMapping[top.identifier])
        }
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        DispatchQueue.global(qos: .userInitiated).async { try? handler.perform([request]) }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Vision keyword mapping (idéntico a WasteClassifier.mapVision)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func mapVision(_ observations: [VNClassificationObservation]) -> (Cat, [Cat: Float]) {
        var scores: [Cat: Float] = [:]
        for obs in observations.prefix(20) {
            let tokens = obs.identifier.lowercased()
                .split(separator: "_")
                .map(String.init) + [obs.identifier.lowercased()]
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

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func buildResultado(tipo: TipoResiduo, confianza: Float, objetoDetectado: String = "") -> ResultadoClasificacion {
        ResultadoClasificacion(
            tipo: tipo,
            contenedor: tipo.contenedor,
            confianza: confianza,
            proximaRecoleccion: proximaRecoleccionTexto(para: tipo.contenedor),
            instrucciones: Self.instruccionesHardcodeadas[tipo] ?? "Deposita este material en el contenedor correspondiente.",
            valorMercado: tipo.valorMercado,
            objetoDetectado: objetoDetectado
        )
    }

    // MARK: - Instrucciones hardcodeadas (fallback sin Foundation Models)

    static let instruccionesHardcodeadas: [TipoResiduo: String] = [
        .plasticoPET:     "Enjuaga la botella, retira la etiqueta y aplástala. Deja el tapón puesto.",
        .plasticoHDPE:    "Enjuaga el envase y aplástalo. Si tiene residuos de aceite, enjuaga bien con agua caliente.",
        .carton:          "Aplana la caja y quita cualquier residuo de comida. Si está mojado o grasoso, va al naranja.",
        .papel:           "El papel limpio y seco va en gris. Papel encerado, húmedo o con grasa va en naranja.",
        .vidrio:          "Enjuaga el frasco o botella. No rompas el vidrio. El vidrio templado NO es reciclable aquí.",
        .aluminio:        "Enjuaga la lata y aplástala. El aluminio es el material más valioso para reciclar.",
        .lata:            "Enjuaga bien la lata. Puedes aplastarla para ahorrar espacio en el contenedor.",
        .organicoComida:  "Coloca restos de comida en bolsa compostable o directamente en el contenedor verde.",
        .organicoPoda:    "Corta ramas grandes en trozos de máximo 50 cm. Deposita hojas y pasto sueltos.",
        .electronico:     "Los electrónicos van a un Punto Limpio. No los mezcles con basura común.",
        .textil:          "La ropa y telas en buen estado pueden donarse. Si están dañadas, llévalas a un contenedor textil.",
        .noReciclable:    "Este material no es reciclable. Deposítalo en el contenedor naranja.",
        .tetraPak:        "Enjuaga el envase Tetra Pak, aplástalo y deposítalo en el contenedor gris."
    ]
}
