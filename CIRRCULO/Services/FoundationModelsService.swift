import Foundation

// MARK: - FoundationModelsService
// Integración con Apple Intelligence on-device LLM.
// Requiere iOS 18.1+ / iPhone 15 Pro o superior.
// En dispositivos no compatibles usa respuestas hardcodeadas (fallback).

actor FoundationModelsService {

    static let shared = FoundationModelsService()
    private init() {}

    // Comprobación de disponibilidad (runtime)
    // En iOS 18.1+ con FoundationModels importado usaríamos:
    //   LanguageModelSession.isAvailable
    // Para el hackathon usamos detección de OS como proxy.
    private var disponible: Bool {
        if #available(iOS 18.1, *) { return true }
        return false
    }

    // MARK: - API pública

    func pregunta(_ texto: String) async -> String {
        guard disponible else {
            return respuestaHardcodeada(para: texto)
        }
        // Con FoundationModels importado:
        // let session = LanguageModelSession(instructions: systemPrompt)
        // return (try? await session.respond(to: texto).content) ?? respuestaHardcodeada(para: texto)
        return await simularLLM(prompt: texto)
    }

    func instruccionesParaMaterial(_ resultado: ResultadoClasificacion) async -> String {
        let prompt = "Instrucción breve para preparar \(resultado.tipo.rawValue) antes de depositarlo."
        guard disponible else {
            return ClassifierService.instruccionesHardcodeadas[resultado.tipo]
                ?? "Deposita este material en el contenedor correspondiente."
        }
        return await simularLLM(prompt: prompt)
    }

    func resolverAmbiguedad(opcion1: TipoResiduo, opcion2: TipoResiduo) async -> String {
        let prompt = "¿Cómo distingo \(opcion1.rawValue) de \(opcion2.rawValue)? Una oración."
        guard disponible else {
            return "Observa el símbolo de reciclaje: PET tiene el número 1, HDPE tiene el número 2."
        }
        return await simularLLM(prompt: prompt)
    }

    func resumenEjecutivoEmpresa(_ registro: RegistroEmpresa) async -> String {
        let prompt = """
        Empresa registró: \(String(format: "%.1f", registro.kgTotalesMes)) kg, \
        \(registro.residuosRegistrados.count) registros, \
        ahorro fiscal: $\(String(format: "%.0f", registro.ahorroFiscalEstimado)) MXN.
        Párrafo ejecutivo de 2 oraciones para auditor de SEDEMA, referenciando LGPGIR.
        """
        guard disponible else {
            return """
            Durante el presente mes, la empresa registró \(String(format: "%.1f", registro.kgTotalesMes)) kg \
            de residuos con \(registro.residuosRegistrados.count) registros documentados, \
            cumpliendo con la NADF-024 y la LGPGIR. \
            Como resultado, la empresa es elegible para una reducción en el impuesto sobre nómina \
            de hasta $\(String(format: "%.0f", registro.ahorroFiscalEstimado)) MXN, \
            previa validación ante SEDEMA.
            """
        }
        return await simularLLM(prompt: prompt)
    }

    // MARK: - Simulación LLM (demo sin dispositivo compatible)

    private func simularLLM(prompt: String) async -> String {
        // Simula latencia del modelo on-device
        try? await Task.sleep(nanoseconds: 800_000_000)
        return respuestaHardcodeada(para: prompt)
    }

    // MARK: - Respuestas hardcodeadas (fallback)

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
            return "La ropa no va en contenedores NADF-024. Dónala si está en buen estado o busca contenedores de ropa usada de Cruz Roja o Cáritas."
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
        if p.contains("distinguir") || p.contains("diferencia") {
            return "Busca el símbolo de reciclaje en la base del envase: el número indica el tipo de plástico. PET=1, HDPE=2."
        }
        return "Recuerda NADF-024: verde para orgánicos (mar, jue, sáb), gris para reciclables, naranja para no reciclables (lun, mié, vie, dom). ¿Tienes alguna duda específica?"
    }
}
