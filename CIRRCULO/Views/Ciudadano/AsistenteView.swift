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
            VStack(spacing: 0) {
                // Lista de mensajes
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Mensaje de bienvenida
                            if mensajes.isEmpty {
                                BienvenidaAsistente(sugerencias: sugerencias) { texto in
                                    enviar(texto)
                                }
                            }

                            ForEach(mensajes) { msg in
                                BurbujaChat(mensaje: msg)
                                    .id(msg.id)
                            }

                            if cargando {
                                EscribiendoIndicador()
                                    .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: mensajes.count) { _, _ in
                        withAnimation {
                            let scrollTarget: UUID? = mensajes.last?.id
                            if let id = scrollTarget {
                                proxy.scrollTo(id, anchor: .bottom)
                            } else {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Campo de entrada
                HStack(spacing: 12) {
                    TextField("Pregunta sobre reciclaje...", text: $inputTexto, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        let texto = inputTexto.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !texto.isEmpty else { return }
                        inputTexto = ""
                        enviar(texto)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputTexto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                             ? Color(.systemGray4) : Color(hex: "#388E3C"))
                    }
                    .disabled(inputTexto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()

                // Pie de privacidad
                Text("Procesado en tu dispositivo · Sin conexión a internet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            .navigationTitle("Asistente IA")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Subvistas

struct MensajeChat: Identifiable {
    let id: UUID
    let texto: String
    let esUsuario: Bool
}

struct BurbujaChat: View {
    let mensaje: MensajeChat

    var body: some View {
        HStack {
            if mensaje.esUsuario { Spacer(minLength: 60) }

            Text(mensaje.texto)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(mensaje.esUsuario ? Color(hex: "#388E3C") : Color(.systemGray5))
                .foregroundStyle(mensaje.esUsuario ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if !mensaje.esUsuario { Spacer(minLength: 60) }
        }
    }
}

struct EscribiendoIndicador: View {
    @State private var animando = false

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(animando ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: animando)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer(minLength: 60)
        }
        .onAppear { animando = true }
    }
}

struct BienvenidaAsistente: View {
    let sugerencias: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "#388E3C"))

            Text("Hola, soy tu asistente de reciclaje")
                .font(.headline)

            Text("Pregúntame sobre cómo clasificar residuos, la norma NADF-024 o cómo preparar materiales.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(sugerencias, id: \.self) { s in
                    Button {
                        onSelect(s)
                    } label: {
                        Text(s)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#E8F5E9"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
    }
}

#Preview {
    AsistenteView()
}
