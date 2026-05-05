import Foundation
import FoundationModels

// MARK: - FoundationModelsService
// Usa Apple Intelligence on-device LLM vía LanguageModelSession en iOS 26+.
// No bloquea con isAvailable — siempre intenta; el catch gestiona errores de assets.
// En dispositivos sin soporte usa respuestas hardcodeadas sin degradar el flujo.

actor FoundationModelsService {

    static let shared = FoundationModelsService()
    private init() {}

    private let systemPrompt = """
    Eres el asistente de CIRRCULO, app de economía circular en México.
    Ayuda con dudas sobre reciclaje y la norma NADF-024 de la Ciudad de México.
    Responde siempre en español, de forma concisa (máximo 3 oraciones).
    NADF-024: Verde=orgánicos(Mar,Jue,Sáb), Gris=reciclables(Lun,Mié,Vie,Dom),
    Naranja=no reciclables(Lun,Mié,Vie,Dom).
    """

    // Estado de disponibilidad real del modelo
    nonisolated var modelActivo: Bool {
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
    }

    // Razón concisa de por qué el modelo no está disponible (nil = disponible)
    nonisolated var unavailabilityReason: String? {
        guard !modelActivo else { return nil }
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return nil
            case .unavailable(let reason):
                switch reason {
                case .deviceNotEligible:
                    return "Dispositivo no compatible con Apple Intelligence"
                case .appleIntelligenceNotEnabled:
                    return "Activa Apple Intelligence en Ajustes"
                case .modelNotReady:
                    return "Descargando modelo, intenta en un momento"
                @unknown default:
                    return "Apple Intelligence no disponible"
                }
            }
        }
        return "Requiere iOS 26 o superior"
    }

    // MARK: - API pública
    // Siempre intenta Foundation Models en iOS 26+; el catch hace fallback si falla.

    func pregunta(_ texto: String) async -> String {
        if #available(iOS 26.0, *) {
            print("[FM] availability=\(SystemLanguageModel.default.availability)")
            guard SystemLanguageModel.default.isAvailable else {
                return await fallbackConDelay(para: texto)
            }
            do {
                let session = LanguageModelSession(instructions: systemPrompt)
                session.prewarm()
                let respuesta = try await session.respond(to: texto).content
                print("[FM] respuesta OK (\(respuesta.count) chars)")
                return respuesta
            } catch {
                print("[FM] respond falló: \(error)")
                return respuestaHardcodeada(para: texto)
            }
        }
        return await fallbackConDelay(para: texto)
    }

    func instruccionesParaMaterial(_ resultado: ResultadoClasificacion) async -> String {
        let prompt = """
        El usuario escaneó: \(resultado.tipo.rawValue) → contenedor \(resultado.contenedor.rawValue).
        Da una instrucción breve y práctica de cómo preparar este material antes de depositarlo.
        """
        if #available(iOS 26.0, *) {
            do {
                let session = LanguageModelSession(instructions: systemPrompt)
                return try await session.respond(to: prompt).content
            } catch {}
        }
        return ClassifierService.instruccionesHardcodeadas[resultado.tipo]
            ?? "Deposita este material en el contenedor correspondiente."
    }

    func resolverAmbiguedad(opcion1: TipoResiduo, opcion2: TipoResiduo) async -> String {
        let prompt = "¿Cómo distingo visualmente \(opcion1.rawValue) de \(opcion2.rawValue)? Una oración."
        if #available(iOS 26.0, *) {
            do {
                let session = LanguageModelSession(instructions: systemPrompt)
                return try await session.respond(to: prompt).content
            } catch {}
        }
        return "Busca el número en la base del envase: PET tiene el 1, HDPE tiene el 2."
    }

    func resumenEjecutivoEmpresa(_ registro: RegistroEmpresa) async -> String {
        let prompt = """
        Empresa registró este mes: \(String(format: "%.1f", registro.kgTotalesMes)) kg de residuos, \
        \(registro.residuosRegistrados.count) registros documentados, \
        ahorro fiscal estimado: $\(String(format: "%.0f", registro.ahorroFiscalEstimado)) MXN.
        Genera un párrafo ejecutivo de 2 oraciones para presentar ante auditor de SEDEMA, \
        destacando cumplimiento de LGPGIR y NADF-024.
        """
        if #available(iOS 26.0, *) {
            do {
                let session = LanguageModelSession(instructions: systemPrompt)
                return try await session.respond(to: prompt).content
            } catch {}
        }
        return fallbackResumen(registro)
    }

    // MARK: - Fallback hardcodeado

    private func fallbackConDelay(para texto: String) async -> String {
        try? await Task.sleep(nanoseconds: 700_000_000)
        return respuestaHardcodeada(para: texto)
    }

    private func fallbackResumen(_ registro: RegistroEmpresa) -> String {
        "Durante el presente mes, la empresa registró \(String(format: "%.1f", registro.kgTotalesMes)) kg de residuos con \(registro.residuosRegistrados.count) registros documentados, cumpliendo con la NADF-024 y la LGPGIR. Como resultado, la empresa es elegible para una reducción en el impuesto sobre nómina de hasta $\(String(format: "%.0f", registro.ahorroFiscalEstimado)) MXN, previa validación ante SEDEMA."
    }

    private func respuestaHardcodeada(para texto: String) -> String {
        let p = texto.lowercased()
        if p.contains("botella") || p.contains("limpiar") {
            return "Enjuaga la botella con agua y retira la etiqueta. No necesita estar perfectamente limpia, solo libre de residuos sólidos."
        }
        if p.contains("tetra") {
            return "El Tetra Pak va en el contenedor gris. Enjuágalo y aplástalo antes de depositarlo. Recolección: lunes, miércoles, viernes y domingo."
        }
        if p.contains("pila") || p.contains("batería") {
            return "Las pilas son residuos peligrosos. Llévalas a puntos especializados en Home Depot, Walmart o tu ECOCENTRO más cercano. No van en los contenedores NADF-024."
        }
        if p.contains("ropa") || p.contains("tela") {
            return "La ropa no va en contenedores NADF-024. Dónala si está en buen estado o busca contenedores de Cruz Roja o Cáritas."
        }
        if p.contains("vidrio") {
            return "Enjuaga frascos y botellas. No los rompas. El vidrio templado (vasos, espejos) no es reciclable junto con vidrio ordinario."
        }
        if p.contains("cartón") || p.contains("papel") {
            return "Aplana cajas de cartón para ahorrar espacio. El papel mojado o encerado va al naranja. Recolección: lunes, miércoles, viernes y domingo."
        }
        if p.contains("orgánico") || p.contains("comida") {
            return "Los orgánicos van en el contenedor verde. Incluye cáscaras, restos de comida y poda. Recolección: martes, jueves y sábado."
        }
        if p.contains("pet") || p.contains("plástico") {
            return "El PET suena hueco al golpearlo y es transparente. El HDPE es más rígido y opaco, con el número 2 en la base. Ambos van en el gris."
        }
        if p.contains("recolección") || p.contains("cuándo") || p.contains("verde") {
            return "Contenedor verde: martes, jueves y sábado. Contenedor gris y naranja: lunes, miércoles, viernes y domingo. Horario habitual: 7–10 am."
        }
        return "Recuerda NADF-024: verde para orgánicos (mar, jue, sáb), gris para reciclables, naranja para no reciclables (lun, mié, vie, dom). ¿Tienes alguna duda específica?"
    }
}
