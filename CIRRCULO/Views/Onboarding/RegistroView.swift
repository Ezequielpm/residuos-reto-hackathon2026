import SwiftUI

struct RegistroView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var nombre = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmarPassword = ""
    @State private var perfilSeleccionado: PerfilUsuario = .ciudadano
    @State private var error: String?
    @State private var cargando = false
    @State private var aparecio = false
    @State private var videoData: Data?

    var body: some View {
        ZStack {
            // Video background
            if let data = videoData {
                LoopingVideoPlayer(videoData: data)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Gradient overlay
            LinearGradient(
                colors: [.black.opacity(0.5), .black.opacity(0.85), .black.opacity(0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Volver")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    // Logo small
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.3.trianglepath")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)

                        Text("CIRRCULO")
                            .font(.system(size: 22, weight: .black))
                            .tracking(3)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 32)

                    // Form
                    VStack(spacing: 16) {
                        Text("Crear Cuenta")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Nombre
                        CampoTextoAuth(
                            titulo: "Nombre completo",
                            icono: "person.fill",
                            placeholder: "Tu nombre",
                            texto: $nombre,
                            tipo: .normal
                        )

                        // Email
                        CampoTextoAuth(
                            titulo: "Correo electrónico",
                            icono: "envelope.fill",
                            placeholder: "tu@email.com",
                            texto: $email,
                            tipo: .email
                        )

                        // Password
                        CampoTextoAuth(
                            titulo: "Contraseña",
                            icono: "lock.fill",
                            placeholder: "Mínimo 6 caracteres",
                            texto: $password,
                            tipo: .password
                        )

                        // Confirmar
                        CampoTextoAuth(
                            titulo: "Confirmar contraseña",
                            icono: "lock.shield.fill",
                            placeholder: "Repite tu contraseña",
                            texto: $confirmarPassword,
                            tipo: .password
                        )

                        // Perfil selector
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tipo de perfil")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(PerfilUsuario.allCases, id: \.self) { perfil in
                                        PerfilChip(
                                            perfil: perfil,
                                            seleccionado: perfilSeleccionado == perfil
                                        ) {
                                            withAnimation(.spring(response: 0.3)) {
                                                perfilSeleccionado = perfil
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Error
                        if let error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        // Register button
                        Button {
                            registrar()
                        } label: {
                            HStack(spacing: 8) {
                                if cargando {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                    Text("Crear Cuenta")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [perfilSeleccionado.colorSecundario, perfilSeleccionado.colorPrimario],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: perfilSeleccionado.colorPrimario.opacity(0.4), radius: 8, y: 4)
                        }
                        .disabled(cargando)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 28)
                    .opacity(aparecio ? 1 : 0)
                    .offset(y: aparecio ? 0 : 20)

                    Spacer().frame(height: 40)
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            if let asset = NSDataAsset(name: "LogginVideo") {
                videoData = asset.data
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                aparecio = true
            }
        }
    }

    private func registrar() {
        error = nil
        cargando = true
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            do {
                try auth.registrar(
                    nombre: nombre,
                    email: email,
                    password: password,
                    confirmar: confirmarPassword,
                    perfil: perfilSeleccionado
                )
                dismiss()
            } catch let authError as AuthManager.AuthError {
                error = authError.errorDescription
            } catch {
                self.error = "Error inesperado"
            }
            cargando = false
        }
    }
}

// MARK: - Campo de texto reutilizable

enum TipoCampoAuth {
    case normal, email, password
}

struct CampoTextoAuth: View {
    let titulo: String
    let icono: String
    let placeholder: String
    @Binding var texto: String
    let tipo: TipoCampoAuth

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 12) {
                Image(systemName: icono)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 20)

                Group {
                    switch tipo {
                    case .password:
                        SecureField(placeholder, text: $texto)
                    case .email:
                        TextField(placeholder, text: $texto)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    case .normal:
                        TextField(placeholder, text: $texto)
                            .autocorrectionDisabled()
                    }
                }
                .foregroundStyle(.white)
            }
            .padding(14)
            .background(.ultraThinMaterial.opacity(0.5))
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Perfil Chip

struct PerfilChip: View {
    let perfil: PerfilUsuario
    let seleccionado: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: perfil.icono)
                    .font(.system(size: 14))
                Text(perfil.rawValue)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                seleccionado
                    ? AnyShapeStyle(LinearGradient(
                        colors: [perfil.colorSecundario, perfil.colorPrimario],
                        startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color.white.opacity(0.08))
            )
            .foregroundStyle(seleccionado ? .white : .white.opacity(0.6))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(seleccionado ? Color.clear : .white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RegistroView()
        .environment(AuthManager.shared)
}
