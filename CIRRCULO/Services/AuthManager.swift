import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class AuthManager {

    var usuarioActual: Usuario?
    var estaAutenticado: Bool { usuarioActual != nil }

    private var modelContext: ModelContext?

    // Singleton para acceso global
    static let shared = AuthManager()
    private init() {}

    func configurar(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedDemoUsers()
        restaurarSesion()
    }

    // MARK: - Usuarios demo pre-cargados

    struct DemoUser {
        let id: UUID
        let nombre: String
        let email: String
        let perfil: PerfilUsuario
    }

    static let demoUsers: [DemoUser] = [
        DemoUser(id: Usuario.idMaria,     nombre: "María López",       email: "maria@nexia.mx",    perfil: .ciudadano),
        DemoUser(id: Usuario.idJorge,     nombre: "Jorge Hernández",   email: "jorge@nexia.mx",    perfil: .ciudadano),
        DemoUser(id: Usuario.idBeto,      nombre: "Beto Sánchez",      email: "beto@nexia.mx",     perfil: .pepenador),
        DemoUser(id: Usuario.idRosa,      nombre: "Rosa García",       email: "rosa@nexia.mx",     perfil: .pepenador),
        DemoUser(id: Usuario.idEcoTech,   nombre: "EcoTech Solutions",  email: "ecotech@nexia.mx",  perfil: .empresa),
        DemoUser(id: Usuario.idGreenCorp, nombre: "GreenCorp MX",      email: "greencorp@nexia.mx", perfil: .empresa),
        DemoUser(id: Usuario.idLaura,     nombre: "Laura Méndez",      email: "laura@nexia.mx",    perfil: .puntoAcopio),
        DemoUser(id: Usuario.idCarmen,    nombre: "Carmen Ruiz",       email: "carmen@nexia.mx",   perfil: .puntoAcopio),
        DemoUser(id: Usuario.idRicardo,   nombre: "Ricardo Flores",    email: "ricardo@nexia.mx",  perfil: .centroAcopio),
        DemoUser(id: Usuario.idElena,     nombre: "Elena Ortiz",       email: "elena@nexia.mx",    perfil: .centroAcopio),
    ]

    /// Password de todos los usuarios demo
    static let demoPassword = "demo123"

    private func seedDemoUsers() {
        guard let context = modelContext else { return }

        // Verificar si ya existen
        let descriptor = FetchDescriptor<Usuario>()
        let existentes = (try? context.fetch(descriptor)) ?? []
        let existingIds = Set(existentes.map { $0.id })

        for demo in Self.demoUsers {
            guard !existingIds.contains(demo.id) else { continue }
            let usuario = Usuario(
                id: demo.id,
                nombre: demo.nombre,
                email: demo.email,
                password: Self.demoPassword,
                perfil: demo.perfil
            )
            context.insert(usuario)
        }
        try? context.save()
    }

    // MARK: - Registro

    enum AuthError: LocalizedError {
        case emailExistente
        case credencialesInvalidas
        case camposVacios
        case passwordsNoCoinciden
        case passwordMuyCorta

        var errorDescription: String? {
            switch self {
            case .emailExistente:       return "Ya existe una cuenta con este correo"
            case .credencialesInvalidas: return "Correo o contraseña incorrectos"
            case .camposVacios:         return "Todos los campos son obligatorios"
            case .passwordsNoCoinciden: return "Las contraseñas no coinciden"
            case .passwordMuyCorta:     return "La contraseña debe tener al menos 6 caracteres"
            }
        }
    }

    func registrar(nombre: String, email: String, password: String, confirmar: String, perfil: PerfilUsuario) throws {
        guard let context = modelContext else { return }

        // Validaciones
        guard !nombre.isEmpty, !email.isEmpty, !password.isEmpty else {
            throw AuthError.camposVacios
        }
        guard password == confirmar else {
            throw AuthError.passwordsNoCoinciden
        }
        guard password.count >= 6 else {
            throw AuthError.passwordMuyCorta
        }

        // Verificar email único
        let emailLower = email.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<Usuario>(predicate: #Predicate { $0.email == emailLower })
        let existentes = (try? context.fetch(descriptor)) ?? []
        guard existentes.isEmpty else {
            throw AuthError.emailExistente
        }

        // Crear usuario
        let usuario = Usuario(nombre: nombre, email: email, password: password, perfil: perfil)
        context.insert(usuario)
        try? context.save()

        // Login automático
        usuarioActual = usuario
        guardarSesion(userId: usuario.id)
    }

    // MARK: - Login

    func login(email: String, password: String) throws {
        guard let context = modelContext else { return }

        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.camposVacios
        }

        let emailLower = email.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<Usuario>(predicate: #Predicate { $0.email == emailLower })
        guard let usuario = (try? context.fetch(descriptor))?.first else {
            throw AuthError.credencialesInvalidas
        }

        guard usuario.verificarPassword(password) else {
            throw AuthError.credencialesInvalidas
        }

        usuarioActual = usuario
        guardarSesion(userId: usuario.id)
    }

    // MARK: - Logout

    func logout() {
        usuarioActual = nil
        UserDefaults.standard.removeObject(forKey: "sesionActivaUserId")
    }

    // MARK: - Sesión persistente

    private func guardarSesion(userId: UUID) {
        UserDefaults.standard.set(userId.uuidString, forKey: "sesionActivaUserId")
    }

    private func restaurarSesion() {
        guard let context = modelContext,
              let idString = UserDefaults.standard.string(forKey: "sesionActivaUserId"),
              let id = UUID(uuidString: idString) else { return }

        let descriptor = FetchDescriptor<Usuario>(predicate: #Predicate { $0.id == id })
        if let usuario = (try? context.fetch(descriptor))?.first {
            usuarioActual = usuario
        } else {
            // Sesión inválida, limpiar
            UserDefaults.standard.removeObject(forKey: "sesionActivaUserId")
        }
    }
}
