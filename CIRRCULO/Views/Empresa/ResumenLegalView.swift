import SwiftUI

struct ResumenLegalView: View {
    @State private var registro = MockDataService.shared.registroEmpresa
    @State private var resumenGenerado: String?
    @State private var generando = false
    @State private var copiado = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.gearshape.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hex: "#1565C0"))

                        Text("Resumen para Auditoría")
                            .font(.title2.bold())

                        Text("Genera un párrafo ejecutivo con los datos de reciclaje del mes para presentar ante SEDEMA y auditores.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Datos usados
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Datos del mes")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            DatoRow(label: "Kg totales registrados",
                                    valor: String(format: "%.1f kg", registro.kgTotalesMes))
                            DatoRow(label: "Registros documentados",
                                    valor: "\(registro.residuosRegistrados.count)")
                            DatoRow(label: "Ahorro fiscal estimado",
                                    valor: "$\(String(format: "%.0f", registro.ahorroFiscalEstimado)) MXN")
                            DatoRow(label: "Marco legal",
                                    valor: "LGPGIR + NADF-024")
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.06), radius: 4)
                        .padding(.horizontal)
                    }

                    // Botón generar
                    Button {
                        generarResumen()
                    } label: {
                        if generando {
                            HStack {
                                ProgressView()
                                    .tint(.white)
                                Text("Generando con Apple Intelligence...")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#1565C0").opacity(0.7))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Generar resumen para auditoría", systemImage: "sparkles")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#1565C0"))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .disabled(generando)
                    .padding(.horizontal)

                    // Resultado
                    if let resumen = resumenGenerado {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Resumen generado", systemImage: "sparkles")
                                    .font(.headline)
                                    .foregroundStyle(Color(hex: "#1565C0"))
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = resumen
                                    withAnimation { copiado = true }
                                    Task {
                                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                                        await MainActor.run { withAnimation { copiado = false } }
                                    }
                                } label: {
                                    Label(copiado ? "Copiado" : "Copiar",
                                          systemImage: copiado ? "checkmark" : "doc.on.doc")
                                        .font(.caption.bold())
                                        .foregroundStyle(copiado ? Color(hex: "#4CAF50") : Color(hex: "#1565C0"))
                                }
                            }

                            Text(resumen)
                                .font(.body)
                                .padding()
                                .background(Color(hex: "#E3F2FD"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Label("Generado con Apple Intelligence · Todo el procesamiento ocurre en este dispositivo",
                                  systemImage: "iphone.and.arrow.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Resumen Legal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func generarResumen() {
        generando = true
        Task {
            let texto = await FoundationModelsService.shared.resumenEjecutivoEmpresa(registro)
            await MainActor.run {
                resumenGenerado = texto
                generando = false
            }
        }
    }
}

struct DatoRow: View {
    let label: String
    let valor: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(valor)
                .font(.subheadline.bold())
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        Divider().padding(.horizontal)
    }
}

#Preview {
    ResumenLegalView()
}
