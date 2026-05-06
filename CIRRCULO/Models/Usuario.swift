import Foundation
import SwiftData
import CryptoKit

@Model
final class Usuario {
    @Attribute(.unique) var id: UUID
    var nombre: String
    @Attribute(.unique) var email: String
    var passwordHash: String
    var perfilRaw: String
    var fechaRegistro: Date
    var activo: Bool

    var perfil: PerfilUsuario {
        get { PerfilUsuario(rawValue: perfilRaw) ?? .ciudadano }
        set { perfilRaw = newValue.rawValue }
    }

    init(nombre: String, email: String, password: String, perfil: PerfilUsuario) {
        self.id = UUID()
        self.nombre = nombre
        self.email = email.lowercased().trimmingCharacters(in: .whitespaces)
        self.passwordHash = Usuario.hashPassword(password)
        self.perfilRaw = perfil.rawValue
        self.fechaRegistro = Date()
        self.activo = true
    }

    /// Init con UUID fijo (para usuarios demo pre-cargados)
    init(id: UUID, nombre: String, email: String, password: String, perfil: PerfilUsuario) {
        self.id = id
        self.nombre = nombre
        self.email = email.lowercased().trimmingCharacters(in: .whitespaces)
        self.passwordHash = Usuario.hashPassword(password)
        self.perfilRaw = perfil.rawValue
        self.fechaRegistro = Date()
        self.activo = true
    }

    // MARK: - IDs fijos de usuarios demo

    static let idMaria    = UUID(uuidString: "D1000000-0000-0000-0000-000000000001")!
    static let idJorge    = UUID(uuidString: "D2000000-0000-0000-0000-000000000002")!
    static let idBeto     = UUID(uuidString: "D3000000-0000-0000-0000-000000000003")!
    static let idRosa     = UUID(uuidString: "D3000000-0000-0000-0000-000000000004")!
    static let idEcoTech  = UUID(uuidString: "D4000000-0000-0000-0000-000000000001")!
    static let idGreenCorp = UUID(uuidString: "D4000000-0000-0000-0000-000000000002")!
    static let idLaura    = UUID(uuidString: "D5000000-0000-0000-0000-000000000001")! // Op. Ecocentro Coyoacán
    static let idCarmen   = UUID(uuidString: "D5000000-0000-0000-0000-000000000002")! // Op. Punto Verde Roma
    static let idRicardo  = UUID(uuidString: "D6000000-0000-0000-0000-000000000001")! // Op. Centro Sur
    static let idElena    = UUID(uuidString: "D6000000-0000-0000-0000-000000000002")! // Op. Acopio Oriente

    func verificarPassword(_ password: String) -> Bool {
        return Usuario.hashPassword(password) == self.passwordHash
    }

    static func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
