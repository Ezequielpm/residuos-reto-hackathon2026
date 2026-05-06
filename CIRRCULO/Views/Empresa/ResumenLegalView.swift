import SwiftUI

struct ResumenLegalView: View {
    @ObservedObject var vm: EmpresaViewModel
    @EnvironmentObject var store: AppDataStore
    @State private var resumenGenerado: String?
    @State private var generando = false
    @State private var copiado = false

    private var registroConCertificados: RegistroEmpresa {
        var r = vm.registro
        r.certificados = store.certificados(empresaId: vm.registro.empresaId)
        return r
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    ResumenLegalHeader(vm: vm)

                    VStack(spacing: 20) {
                        // Datos del mes
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(titulo: "Datos del mes",
                                          icono: "chart.bar.doc.horizontal.fill",
                                          color: Color(hex: "#1565C0"))

                            VStack(spacing: 0) {
                                DatoRow(label: "Kg totales registrados",
                                        valor: String(format: "%.1f kg", vm.registro.kgTotalesMes))
                                DatoRow(label: "Registros documentados",
                                        valor: "\(vm.registro.residuosRegistrados.count)")
                                DatoRow(label: "Ahorro fiscal estimado",
                                        valor: "$\(String(format: "%.0f", vm.registro.ahorroFiscalEstimado)) MXN")
                                DatoRow(label: "Marco legal", valor: "LGPGIR + NADF-024", isLast: true)
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        }
                        .padding(.horizontal, 20)

                        // Botón generar
                        Button { generarResumen() } label: {
                            HStack(spacing: 10) {
                                if generando {
                                    ProgressView().tint(.white)
                                    Text("Generando con Apple Intelligence…")
                                        .font(.headline)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generar resumen para auditoría")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                generando
                                    ? AnyShapeStyle(Color(hex: "#1565C0").opacity(0.6))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color(hex: "#42A5F5"), Color(hex: "#1565C0")],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: generando ? .clear : Color(hex: "#1565C0").opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(generando)
                        .padding(.horizontal, 20)

                        // Resultado
                        if let resumen = resumenGenerado {
                            VStack(alignment: .leading, spacing: 14) {
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
                                        HStack(spacing: 4) {
                                            Image(systemName: copiado ? "checkmark" : "doc.on.doc")
                                            Text(copiado ? "Copiado" : "Copiar")
                                        }
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(copiado ? Color(hex: "#E8F5E9") : Color(hex: "#E3F2FD"))
                                        .foregroundStyle(copiado ? Color(hex: "#2E7D32") : Color(hex: "#1565C0"))
                                        .clipShape(Capsule())
                                    }
                                }

                                Text(resumen)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .padding(16)
                                    .background(Color(hex: "#E3F2FD"))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))

                                HStack(spacing: 6) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "#1565C0"))
                                    Text("Apple Intelligence · Todo el procesamiento ocurre en este dispositivo")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(20)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
        }
    }

    private func generarResumen() {
        generando = true
        Task {
            let texto = await FoundationModelsService.shared.resumenEjecutivoEmpresa(registroConCertificados)
            await MainActor.run {
                withAnimation(.spring()) {
                    resumenGenerado = texto
                    generando = false
                }
            }
        }
    }
}

// MARK: - Header

struct ResumenLegalHeader: View {
    @ObservedObject var vm: EmpresaViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#0D47A1"), Color(hex: "#1565C0"), Color(hex: "#1976D2")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 130, y: -30)
            Circle().fill(.white.opacity(0.04)).frame(width: 150).offset(x: -70, y: 20)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resumen Legal")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Generado con Apple Intelligence")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    ZStack {
                        Circle().fill(.white.opacity(0.15)).frame(width: 52, height: 52)
                        Image(systemName: "doc.badge.gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }

                // Contexto
                HStack(spacing: 14) {
                    InfoBadge(valor: String(format: "%.1f kg", vm.registro.kgTotalesMes), label: "Kg registrados")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    InfoBadge(valor: "\(vm.registro.residuosRegistrados.count)", label: "Registros")
                    Divider().frame(width: 1, height: 32).background(.white.opacity(0.3))
                    InfoBadge(valor: "SEDEMA", label: "Destino")
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 24)
        }
    }
}

struct InfoBadge: View {
    let valor: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(valor).font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Helpers

struct DatoRow: View {
    let label: String
    let valor: String
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(valor)
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if !isLast {
                Divider().padding(.horizontal, 16)
            }
        }
    }
}
