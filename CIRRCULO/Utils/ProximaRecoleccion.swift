import Foundation

/// Calcula el próximo día de recolección según NADF-024s
func proximaRecoleccionTexto(para contenedor: ContenedorNADF) -> String {
    let calendar = Calendar.current
    let hoy = Date()
    let weekdayHoy = calendar.component(.weekday, from: hoy)
    let diasValidos = contenedor.diasRecoleccion

    // Busca el próximo día válido en los siguientes 7 días
    for offset in 0...7 {
        let fecha = calendar.date(byAdding: .day, value: offset, to: hoy)!
        let weekday = calendar.component(.weekday, from: fecha)
        if diasValidos.contains(weekday) {
            if offset == 0 { return "Hoy" }
            if offset == 1 { return "Mañana, \(nombreDia(weekday))" }
            return "En \(offset) días (\(nombreDia(weekday)))"
        }
    }
    return "Próxima semana"
}

private func nombreDia(_ weekday: Int) -> String {
    switch weekday {
    case 1: return "Domingo"
    case 2: return "Lunes"
    case 3: return "Martes"
    case 4: return "Miércoles"
    case 5: return "Jueves"
    case 6: return "Viernes"
    case 7: return "Sábado"
    default: return ""
    }
}
