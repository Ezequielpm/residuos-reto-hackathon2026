import Vision
import CoreML
import CoreImage
import UIKit

@MainActor
final class ClassifierService: ObservableObject {

    static let shared = ClassifierService()
    private init() {}

    // MARK: - Clasificación principal

    func clasificar(pixelBuffer: CVPixelBuffer) async -> ResultadoClasificacion? {
        // Intentar con modelo Core ML primero; fallback a Vision genérico
        if let resultado = await clasificarConVision(pixelBuffer: pixelBuffer) {
            return resultado
        }
        return nil
    }

    // MARK: - Vision genérico (fallback para el hackathon)

    private func clasificarConVision(pixelBuffer: CVPixelBuffer) async -> ResultadoClasificacion? {
        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard let observaciones = request.results as? [VNClassificationObservation],
                      let top = observaciones.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let tipo = Self.mapearObservacion(top.identifier)
                let confianza = top.confidence
                let contenedor = tipo.contenedor
                let resultado = ResultadoClasificacion(
                    tipo: tipo,
                    contenedor: contenedor,
                    confianza: confianza,
                    proximaRecoleccion: proximaRecoleccionTexto(para: contenedor),
                    instrucciones: Self.instruccionesHardcodeadas[tipo] ?? "Deposita este material en el contenedor correspondiente.",
                    valorMercado: tipo.valorMercado
                )
                continuation.resume(returning: resultado)
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Mapping ImageNet → TipoResiduo

    static func mapearObservacion(_ identifier: String) -> TipoResiduo {
        let id = identifier.lowercased()

        if id.contains("bottle") || id.contains("plastic") || id.contains("pet") { return .plasticoPET }
        if id.contains("container") || id.contains("canister") || id.contains("hdpe") { return .plasticoHDPE }
        if id.contains("cardboard") || id.contains("carton") || id.contains("box") { return .carton }
        if id.contains("paper") || id.contains("newspaper") || id.contains("book") { return .papel }
        if id.contains("glass") || id.contains("wine_glass") || id.contains("jar") { return .vidrio }
        if id.contains("can") && (id.contains("tin") || id.contains("beer") || id.contains("soda")) { return .aluminio }
        if id.contains("banana") || id.contains("apple") || id.contains("orange") ||
           id.contains("food") || id.contains("fruit") || id.contains("vegetable") { return .organicoComida }
        if id.contains("plant") || id.contains("leaf") || id.contains("flower") { return .organicoPoda }
        if id.contains("tetra") { return .tetraPak }

        return .noReciclable
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
        .noReciclable:    "Este material no es reciclable. Deposítalo en el contenedor naranja.",
        .tetraPak:        "Enjuaga el envase Tetra Pak, aplástalo y deposítalo en el contenedor gris."
    ]
}
