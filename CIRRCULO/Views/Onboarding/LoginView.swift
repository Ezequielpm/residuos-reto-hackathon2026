import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth
    @State private var email = ""
    @State private var password = ""
    @State private var mostrarRegistro = false
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
                colors: [.black.opacity(0.4), .black.opacity(0.8), .black.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 100)

                    // Logo
                    VStack(spacing: 10) {
                        Image(systemName: "arrow.3.trianglepath")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(aparecio ? 1 : 0.5)
                            .opacity(aparecio ? 1 : 0)

                        Text("CIRRCULO")
                            .font(.system(size: 32, weight: .black))
                            .tracking(4)
                            .foregroundStyle(.white)

                        Text("ECONOMÍA CIRCULAR")
                            .font(.caption2.weight(.medium))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.bottom, 48)

                    // Login form
                    VStack(spacing: 16) {
                        Text("Iniciar Sesión")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Correo electrónico")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))

                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.white.opacity(0.5))
                                    .frame(width: 20)
                                TextField("tu@email.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
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

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Contraseña")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))

                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.white.opacity(0.5))
                                    .frame(width: 20)
                                SecureField("••••••••", text: $password)
                                    .textContentType(.password)
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

                        // Error message
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

                        // Login button
                        Button {
                            iniciarSesion()
                        } label: {
                            HStack(spacing: 8) {
                                if cargando {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Entrar")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#388E3C"), Color(hex: "#2E7D32")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color(hex: "#2E7D32").opacity(0.4), radius: 8, y: 4)
                        }
                        .disabled(cargando)
                        .padding(.top, 8)

                        // Divider
                        HStack {
                            Rectangle().fill(.white.opacity(0.2)).frame(height: 0.5)
                            Text("o")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                            Rectangle().fill(.white.opacity(0.2)).frame(height: 0.5)
                        }
                        .padding(.vertical, 8)

                        // Register link
                        Button {
                            mostrarRegistro = true
                        } label: {
                            Text("Crear una cuenta nueva")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial.opacity(0.5))
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                    }
                    .padding(.horizontal, 28)
                    .opacity(aparecio ? 1 : 0)
                    .offset(y: aparecio ? 0 : 20)

                    // Cuentas demo para la presentación
                    VStack(spacing: 12) {
                        HStack {
                            Rectangle().fill(.white.opacity(0.15)).frame(height: 0.5)
                            Text("CUENTAS DEMO")
                                .font(.caption2.weight(.bold))
                                .tracking(1.5)
                                .foregroundStyle(.white.opacity(0.35))
                            Rectangle().fill(.white.opacity(0.15)).frame(height: 0.5)
                        }
                        .padding(.horizontal, 28)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(AuthManager.demoUsers, id: \.id) { demo in
                                    DemoUserButton(demo: demo) {
                                        loginDemo(demo)
                                    }
                                }
                            }
                            .padding(.horizontal, 28)
                        }
                    }
                    .padding(.top, 20)
                    .opacity(aparecio ? 1 : 0)

                    // Footer
                    HStack(spacing: 6) {
                        Image(systemName: "apple.intelligence")
                            .font(.caption2)
                        Text("IA on-device")
                            .font(.caption2)
                        Text("·")
                            .font(.caption2)
                        Text("Swift Changemakers 2026")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .fullScreenCover(isPresented: $mostrarRegistro) {
            RegistroView()
        }
        .onAppear {
            if let asset = NSDataAsset(name: "LogginVideo") {
                videoData = asset.data
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                aparecio = true
            }
        }
    }

    private func iniciarSesion() {
        error = nil
        cargando = true
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            do {
                try auth.login(email: email, password: password)
            } catch let authError as AuthManager.AuthError {
                error = authError.errorDescription
            } catch {
                self.error = "Error inesperado"
            }
            cargando = false
        }
    }

    private func loginDemo(_ demo: AuthManager.DemoUser) {
        error = nil
        cargando = true
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            do {
                try auth.login(email: demo.email, password: AuthManager.demoPassword)
            } catch {
                self.error = "Error cargando cuenta demo"
            }
            cargando = false
        }
    }
}

// MARK: - Demo User Button

struct DemoUserButton: View {
    let demo: AuthManager.DemoUser
    let action: () -> Void

    private var perfil: PerfilUsuario { demo.perfil }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [perfil.colorSecundario, perfil.colorPrimario],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Text(String(demo.nombre.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 1) {
                    Text(demo.nombre)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(perfil.rawValue)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LoginView()
        .environment(AuthManager.shared)
}
