import Vision
import CoreML
import CoreImage

/// Servicio de clasificación de residuos.
/// Vision keywords + mapeo directo → categoría intermedia → BioTrace confirma material.
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
    // MARK: - Mapeo directo de identificadores compuestos de Vision
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// Identificadores exactos de VNClassifyImageRequest → categoría directa (alta prioridad)
    private let directIdentifierMap: [String: Cat] = [
        // Plásticos
        "water_bottle": .plastic, "pop_bottle": .plastic, "soda_bottle": .plastic,
        "plastic_bag": .plastic, "shopping_bag": .plastic, "trash_bag": .plastic,
        "milk_jug": .plastic, "detergent": .plastic, "shampoo": .plastic,
        "water_jug": .plastic, "jerry_can": .plastic, "bucket": .plastic,
        "tupperware": .plastic, "food_container": .plastic, "styrofoam": .plastic,
        "disposable_cup": .plastic, "straw": .plastic, "plastic_wrap": .plastic,

        // Vidrio
        "wine_bottle": .glass, "beer_bottle": .glass, "beer_glass": .glass,
        "wine_glass": .glass, "wineglass": .glass, "goblet": .glass,
        "cocktail": .glass, "champagne": .glass, "whiskey_jug": .glass,
        "red_wine": .glass, "white_wine": .glass,
        "mason_jar": .glass, "jar": .glass, "vase": .glass,
        "perfume": .glass, "pill_bottle": .glass,

        // Metal / Latas
        "beer_can": .metal, "soda_can": .metal, "pop_can": .metal,
        "tin_can": .metal, "soup_can": .metal, "food_can": .metal,
        "aerosol": .metal, "spray_can": .metal, "aluminum_foil": .metal,
        "frying_pan": .metal, "wok": .metal, "pot": .metal,

        // Papel
        "newspaper": .paper, "envelope": .paper, "letter": .paper,
        "tissue": .paper, "paper_towel": .paper, "toilet_paper": .paper,
        "magazine": .paper, "comic_book": .paper, "book": .paper,

        // Cartón
        "cardboard_box": .cardboard, "shipping_box": .cardboard,
        "pizza_box": .cardboard, "cereal_box": .cardboard,
        "shoe_box": .cardboard, "egg_carton": .cardboard,
        "carton": .cardboard, "moving_box": .cardboard,

        // Orgánico — objetos específicos que Vision suele emitir
        "banana": .organic, "apple": .organic, "orange": .organic,
        "lemon": .organic, "strawberry": .organic, "pineapple": .organic,
        "watermelon": .organic, "pizza": .organic, "sandwich": .organic,
        "bread": .organic, "bagel": .organic, "pretzel": .organic,
        "hotdog": .organic, "hamburger": .organic, "taco": .organic,
        "burrito": .organic, "salad": .organic, "broccoli": .organic,
        "carrot": .organic, "corn": .organic, "mushroom": .organic,
        "bell_pepper": .organic, "cucumber": .organic, "head_cabbage": .organic,
        "cauliflower": .organic, "zucchini": .organic, "spaghetti_squash": .organic,
        "acorn_squash": .organic, "butternut_squash": .organic,
        "ice_cream": .organic, "chocolate": .organic, "cake": .organic,
        "coffee": .organic, "espresso": .organic,

        // Electrónico
        "cellphone": .electronic, "cell_phone": .electronic, "smartphone": .electronic,
        "laptop": .electronic, "notebook_computer": .electronic, "desktop_computer": .electronic,
        "keyboard": .electronic, "computer_mouse": .electronic, "mouse": .electronic,
        "remote_control": .electronic, "television": .electronic, "monitor": .electronic,
        "iPod": .electronic, "speaker": .electronic, "headphone": .electronic,

        // Textil
        "jersey": .textile, "t_shirt": .textile, "running_shoe": .textile,
        "sandal": .textile, "sock": .textile, "cowboy_hat": .textile,
        "sombrero": .textile, "bonnet": .textile, "backpack": .textile,
        "handbag": .textile, "purse": .textile, "diaper": .textile,
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Keywords (ampliados)
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
        "plastic", "bottle", "wrapper", "packaging", "toy", "pen", "lighter",
        "toothbrush", "comb", "hanger", "tupperware", "container",
        "syringe", "crayon", "marker", "eraser", "ruler",
        "cap", "lid", "jug", "gallon", "canteen", "thermos",
        "bag", "wrap", "film", "foam", "styrofoam", "polystyrene"
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
    /// Recorta el centro del frame (70%) para que el análisis corresponda al viewfinder visible.
    func clasificar(cgImage: CGImage, orientation: CGImagePropertyOrientation = .up,
                    completion: @escaping (ResultadoEnriquecido) -> Void) {

        // Recortar al 70% central del frame — corresponde al área del viewfinder en pantalla
        let croppedImage: CGImage = {
            let w = CGFloat(cgImage.width)
            let h = CGFloat(cgImage.height)
            let cropFraction: CGFloat = 0.70
            let cropW = w * cropFraction
            let cropH = h * cropFraction
            let cropRect = CGRect(x: (w - cropW) / 2, y: (h - cropH) / 2, width: cropW, height: cropH)
            return cgImage.cropping(to: cropRect) ?? cgImage
        }()

        let handler = VNImageRequestHandler(cgImage: croppedImage, orientation: orientation, options: [:])

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

            // 6) Detectar ambigüedad: segunda categoría tiene >60% del score de la primera
            //    (antes era 40% — demasiado sensible, causaba falsos ambiguos)
            let isAmbiguous: Bool = {
                guard sortedCats.count >= 2 else { return false }
                let first = sortedCats[0].value
                let second = sortedCats[1].value
                return second > first * 0.6
            }()

            // 7) DECISIÓN — trusted (orgánico/electrónico/textil) o score alto → retornar directo
            //    Bajamos umbral de topScore a 0.35 ya que el mapeo directo da bonus 2x
            if self.trustedCategories.contains(visionCat) || topScore >= 0.35 {
                let tipo = visionCat.toTipoResiduo()
                let confianza: Float
                if self.trustedCategories.contains(visionCat) {
                    confianza = max(top.confidence, 0.75)
                } else {
                    // Boost de confianza proporcional al topScore para mapeos directos fuertes
                    confianza = min(top.confidence + topScore * 0.3, 0.95)
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
            self.clasificarConBioTrace(cgImage: croppedImage, orientation: orientation) { bioTraceTipo in
                let finalTipo = bioTraceTipo ?? visionCat.toTipoResiduo()

                // Boost confianza si BioTrace coincide con Vision
                let finalConfianza: Float
                if bioTraceTipo != nil && bioTraceTipo == visionCat.toTipoResiduo() {
                    finalConfianza = min(top.confidence + 0.25, 0.90)
                } else {
                    finalConfianza = top.confidence
                }

                let resultado = self.buildResultado(
                    tipo: finalTipo,
                    confianza: finalConfianza,
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
                  top.confidence > 0.25 else {
                completion(nil)
                return
            }
            completion(self?.bioTraceMapping[top.identifier])
        }
        request.imageCropAndScaleOption = .centerCrop  // centerCrop alinea con el viewfinder

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        DispatchQueue.global(qos: .userInitiated).async { try? handler.perform([request]) }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Vision keyword mapping (mejorado con mapeo directo)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func mapVision(_ observations: [VNClassificationObservation]) -> (Cat, [Cat: Float]) {
        var scores: [Cat: Float] = [:]

        for obs in observations.prefix(20) {
            let id = obs.identifier.lowercased()

            // 1) Mapeo directo por identificador completo (alta prioridad, bonus 2x)
            if let directCat = directIdentifierMap[id] {
                scores[directCat, default: 0] += obs.confidence * 2.0
                continue  // no hacer keyword matching si ya matcheó directo
            }

            // 2) Fallback: keyword matching por tokens
            let tokens = id.split(separator: "_").map(String.init) + [id]
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
