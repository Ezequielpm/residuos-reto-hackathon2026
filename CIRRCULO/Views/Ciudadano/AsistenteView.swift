import SwiftUI

struct AsistenteView: View {
    @State private var mensajes: [MensajeChat] = []
    @State private var inputTexto = ""
    @State private var cargando = false

    private let sugerencias = [
        "¿Cómo limpio una botella antes de reciclarla?",
        "¿El tetra pak va en gris o naranja?",
        "¿Qué hago con pilas usadas?",
        "¿Puedo reciclar ropa?"
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    AsistenteHeader()

                    // Mensajes
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                if mensajes.isEmpty {
                                    BienvenidaAsistente(sugerencias: sugerencias) { texto in
                                        enviar(texto)
                                    }
                                    .padding(.top, 8)
                                }

                                ForEach(mensajes) { msg in
                                    BurbujaChat(mensaje: msg)
                                        .id(msg.id)
                                }

                                if cargando {
                                    EscribiendoIndicador()
                                        .id("loading")
                                }

                                Color.clear.frame(height: 90).id("bottom")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                        .onChange(of: mensajes.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: cargando) { _, _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }

                // Input flotante
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 10) {
                        TextField("Pregunta sobre reciclaje...", text: $inputTexto, axis: .vertical)
                            .lineLimit(1...4)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                            )

                        Button {
                            let texto = inputTexto.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !texto.isEmpty else { return }
                            inputTexto = ""
                            enviar(texto)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(inputTexto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                          ? Color(.systemGray5) : Color(hex: "#2E7D32"))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .disabled(inputTexto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .animation(.easeInOut(duration: 0.2), value: inputTexto.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial)

                    Text("Procesado en tu dispositivo · Sin conexión a internet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 6)
                        .background(.regularMaterial)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func enviar(_ texto: String) {
        let msgUsuario = MensajeChat(id: UUID(), texto: texto, esUsuario: true)
        mensajes.append(msgUsuario)
        cargando = true

        Task {
            let respuesta = await FoundationModelsService.shared.pregunta(texto)
            await MainActor.run {
                cargando = false
                mensajes.append(MensajeChat(id: UUID(), texto: respuesta, esUsuario: false))
            }
        }
    }
}

// MARK: - Header

struct AsistenteHeader: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#1B5E20"), Color(hex: "#2E7D32")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 180).offset(x: 130, y: -30)
            Circle().fill(.white.opacity(0.04)).frame(width: 130).offset(x: -60, y: 20)

            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(.white.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Asistente IA")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("On-device · Apple Intelligence")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Subvistas

struct MensajeChat: Identifiable {
    let id: UUID
    let texto: String
    let esUsuario: Bool
}

struct BurbujaChat: View {
    let mensaje: MensajeChat

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if mensaje.esUsuario {
                Spacer(minLength: 60)
            } else {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#E8F5E9"))
                        .frame(width: 30, height: 30)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#2E7D32"))
                }
            }

            Text(mensaje.texto)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    mensaje.esUsuario
                        ? LinearGradient(colors: [Color(hex: "#388E3C"), Color(hex: "#2E7D32")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(.systemBackground), Color(.systemBackground)],
                                         startPoint: .top, endPoint: .bottom)
                )
                .foregroundStyle(mensaje.esUsuario ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(mensaje.esUsuario ? 0.12 : 0.06), radius: 4, y: 2)

            if !mensaje.esUsuario {
                Spacer(minLength: 60)
            }
        }
    }
}

struct EscribiendoIndicador: View {
    @State private var animando = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 30, height: 30)
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#2E7D32"))
            }
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 7, height: 7)
                        .scaleEffect(animando ? 1.3 : 0.8)
                        .animation(.easeInOut(duration: 0.45).repeatForever().delay(Double(i) * 0.13), value: animando)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

            Spacer(minLength: 60)
        }
        .onAppear { animando = true }
    }
}

struct BienvenidaAsistente: View {
    let sugerencias: [String]
    let onSelect: (String) -> Void
    @State private var aparecio = false

    var body: some View {
        VStack(spacing: 20) {
            // Hero
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [Color(hex: "#E8F5E9"), Color(hex: "#C8E6C9")],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 80, height: 80)
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(hex: "#2E7D32"))
                        .scaleEffect(aparecio ? 1 : 0.6)
                }

                Text("Hola, soy tu asistente de reciclaje")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text("Pregúntame sobre cómo clasificar residuos,\nla norma NADF-024 o cómo preparar materiales.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
            .opacity(aparecio ? 1 : 0)
            .offset(y: aparecio ? 0 : 20)

            // Sugerencias
            VStack(spacing: 8) {
                Text("Prueba preguntando...")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(sugerencias, id: \.self) { s in
                    Button { onSelect(s) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right.circle")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "#2E7D32"))
                            Text(s)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .opacity(aparecio ? 1 : 0)
            .offset(y: aparecio ? 0 : 15)
        }
        .padding(.bottom, 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                aparecio = true
            }
        }
    }
}

#Preview {
    AsistenteView()
}
