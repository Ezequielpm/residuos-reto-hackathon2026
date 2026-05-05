import SwiftUI

struct AsistenteView: View {
    @State private var mensajes: [MensajeChat] = []
    @State private var inputTexto = ""
    @State private var cargando = false
    @State private var ultimoAsistenteId: UUID?
    @State private var modelActivo = false
    @State private var unavailabilityReason: String?

    private let sugerencias = [
        "¿Cómo limpio una botella antes de reciclarla?",
        "¿El tetra pak va en gris o naranja?",
        "¿Qué hago con pilas usadas?",
        "¿Cuándo recogen el contenedor verde?"
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    AsistenteNavBar(modelActivo: modelActivo)

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if mensajes.isEmpty {
                                    BienvenidaAsistente(sugerencias: sugerencias) { texto in
                                        enviar(texto)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 20)
                                }

                                ForEach(mensajes) { msg in
                                    BurbujaChat(
                                        mensaje: msg,
                                        animarEntrada: msg.id == ultimoAsistenteId && !msg.esUsuario
                                    )
                                    .id(msg.id)
                                }

                                if cargando {
                                    EscribiendoIndicador()
                                        .id("loading")
                                }

                                Color.clear.frame(height: 100).id("bottom")
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
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 22))

                        Button {
                            let texto = inputTexto.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !texto.isEmpty else { return }
                            inputTexto = ""
                            enviar(texto)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(inputTexto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                          ? Color(.systemGray4) : Color(hex: "#2E7D32"))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .disabled(inputTexto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .animation(.easeInOut(duration: 0.15), value: inputTexto.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))

                    HStack(spacing: 4) {
                        Image(systemName: modelActivo ? "cpu.fill" : "exclamationmark.circle")
                            .font(.caption2)
                            .foregroundStyle(modelActivo ? Color(hex: "#2E7D32") : .secondary)
                        Text(modelActivo
                             ? "Apple Intelligence activa · Procesado en este dispositivo"
                             : (unavailabilityReason ?? "Respuestas locales · Apple Intelligence no disponible"))
                            .font(.caption2)
                            .foregroundStyle(modelActivo ? Color(hex: "#2E7D32") : .secondary)
                    }
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            modelActivo = FoundationModelsService.shared.modelActivo
            unavailabilityReason = FoundationModelsService.shared.unavailabilityReason
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
                let nuevoMsg = MensajeChat(id: UUID(), texto: respuesta, esUsuario: false)
                ultimoAsistenteId = nuevoMsg.id
                mensajes.append(nuevoMsg)
            }
        }
    }
}

// MARK: - Barra de navegación compacta

struct AsistenteNavBar: View {
    let modelActivo: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 42, height: 42)
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "#2E7D32"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Asistente IA")
                    .font(.headline)
                Text("Apple Intelligence · On-device")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(modelActivo ? Color.green : Color(hex: "#F9A825"))
                    .frame(width: 7, height: 7)
                Text(modelActivo ? "Activo" : "Offline")
                    .font(.caption2.bold())
                    .foregroundStyle(modelActivo ? .green : Color(hex: "#F9A825"))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(modelActivo ? Color.green.opacity(0.1) : Color(hex: "#F9A825").opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }
}

// MARK: - Modelos

struct MensajeChat: Identifiable {
    let id: UUID
    let texto: String
    let esUsuario: Bool
}

// MARK: - Burbuja de chat

struct BurbujaChat: View {
    let mensaje: MensajeChat
    let animarEntrada: Bool
    @State private var textoVisible: String
    @State private var visible = false

    init(mensaje: MensajeChat, animarEntrada: Bool = false) {
        self.mensaje = mensaje
        self.animarEntrada = animarEntrada
        self._textoVisible = State(initialValue: (animarEntrada && !mensaje.esUsuario) ? "" : mensaje.texto)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if mensaje.esUsuario {
                Spacer(minLength: 56)
            } else {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#E8F5E9"))
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#2E7D32"))
                }
            }

            Text(textoVisible.isEmpty ? " " : textoVisible)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background {
                    if mensaje.esUsuario {
                        LinearGradient(
                            colors: [Color(hex: "#388E3C"), Color(hex: "#1B5E20")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    } else {
                        Color(hex: "#F1F8E9")
                    }
                }
                .foregroundStyle(mensaje.esUsuario ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.07), radius: 4, y: 2)

            if !mensaje.esUsuario {
                Spacer(minLength: 56)
            }
        }
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 10)
        .task {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                visible = true
            }
            if animarEntrada && !mensaje.esUsuario {
                await typewrite()
            }
        }
    }

    private func typewrite() async {
        guard !mensaje.texto.isEmpty else { return }
        let chars = Array(mensaje.texto)
        for i in 0..<chars.count {
            textoVisible = String(chars.prefix(i + 1))
            let delay: UInt64 = chars[i] == " " ? 5_000_000 : 18_000_000
            try? await Task.sleep(nanoseconds: delay)
        }
    }
}

// MARK: - Indicador "escribiendo"

struct EscribiendoIndicador: View {
    @State private var animando = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#2E7D32"))
            }

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "#A5D6A7"))
                        .frame(width: 7, height: 7)
                        .scaleEffect(animando ? 1.35 : 0.75)
                        .animation(
                            .easeInOut(duration: 0.45).repeatForever().delay(Double(i) * 0.13),
                            value: animando
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color(hex: "#F1F8E9"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

            Spacer(minLength: 56)
        }
        .onAppear { animando = true }
    }
}

// MARK: - Pantalla de bienvenida

struct BienvenidaAsistente: View {
    let sugerencias: [String]
    let onSelect: (String) -> Void
    @State private var aparecio = false

    var body: some View {
        VStack(spacing: 32) {
            // Hero con anillos concéntricos
            VStack(spacing: 16) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color(hex: "#A5D6A7").opacity(0.25 - Double(i) * 0.07), lineWidth: 1.5)
                            .frame(width: CGFloat(76 + i * 28), height: CGFloat(76 + i * 28))
                            .scaleEffect(aparecio ? 1 : 0.3)
                            .opacity(aparecio ? 1 : 0)
                            .animation(
                                .spring(response: 0.7, dampingFraction: 0.7).delay(0.05 + Double(i) * 0.08),
                                value: aparecio
                            )
                    }
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#E8F5E9"), Color(hex: "#C8E6C9")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color(hex: "#2E7D32"))
                        .scaleEffect(aparecio ? 1 : 0.4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: aparecio)
                }
                .frame(height: 150)

                VStack(spacing: 8) {
                    Text("Hola, soy tu guía de reciclaje")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("Pregúntame sobre NADF-024, horarios de\nrecolección o cómo preparar tus materiales.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .opacity(aparecio ? 1 : 0)
            .offset(y: aparecio ? 0 : 24)

            // Chips en grid 2×2
            VStack(alignment: .leading, spacing: 10) {
                Text("Temas frecuentes")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(sugerencias, id: \.self) { s in
                        Button { onSelect(s) } label: {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: "#2E7D32"))
                                    .padding(.top, 1)
                                Text(s)
                                    .font(.caption.bold())
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "#C8E6C9"), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .opacity(aparecio ? 1 : 0)
            .offset(y: aparecio ? 0 : 16)
        }
        .padding(.bottom, 24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                aparecio = true
            }
        }
    }
}

#Preview { AsistenteView() }
