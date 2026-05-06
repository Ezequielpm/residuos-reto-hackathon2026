import SwiftUI

struct AhorroFiscalView: View {
    @ObservedObject var vm: EmpresaViewModel
    @EnvironmentObject var store: AppDataStore
    @State private var nominaMensual: Double = 150_000
    @State private var nominaTexto = "150000"
    @State private var animado = false
    @State private var pdfURL: URL?
    @State private var generandoPDF = false
    @State private var mostrandoShare = false

    private var ahorroTotal: Double { nominaMensual * vm.porcentajeReduccion }

    private var certificados: [CertificadoTrazabilidad] {
        store.certificados(empresaId: vm.registro.empresaId)
    }

    private var kgTrazables: Double {
        certificados.reduce(0) { $0 + $1.kgTotales }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    AhorroFiscalHeader(
                        reduccion: vm.porcentajeReduccion,
                        ahorro: ahorroTotal,
                        animado: animado
                    )

                    VStack(spacing: 20) {
                        // Input nómina
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(titulo: "Nómina mensual", icono: "building.2.fill", color: Color(hex: "#1565C0"))

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("$")
                                        .font(.title2.bold())
                                        .foregroundStyle(.secondary)
                                    TextField("150000", text: $nominaTexto)
                                        .keyboardType(.decimalPad)
                                        .font(.title2.bold())
                                        .onChange(of: nominaTexto) { _, v in
                                            nominaMensual = Double(v) ?? 150_000
                                        }
                                    Text("MXN")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)

                                Text("Ingresa la nómina mensual total de tu empresa")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Cumplimiento
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(titulo: "Cumplimiento NADF-024", icono: "checkmark.shield.fill", color: Color(hex: "#1565C0"))
                                .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Nivel de clasificación")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.0f%%", vm.porcentajeClasificados * 100))
                                        .font(.title3.bold())
                                        .foregroundStyle(Color(hex: "#1565C0"))
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(.systemGray6))
                                            .frame(height: 10)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "#42A5F5"), Color(hex: "#1565C0")],
                                                startPoint: .leading, endPoint: .trailing
                                            ))
                                            .frame(width: animado ? geo.size.width * vm.porcentajeClasificados : 0, height: 10)
                                            .animation(.spring(response: 0.8).delay(0.3), value: animado)
                                    }
                                }
                                .frame(height: 10)

                                // Niveles de reducción
                                HStack(spacing: 8) {
                                    NivelBadge(porcentaje: "20%", label: "Básico", activo: vm.porcentajeReduccion >= 0.20, color: Color(hex: "#42A5F5"))
                                    NivelBadge(porcentaje: "30%", label: "Estándar", activo: vm.porcentajeReduccion >= 0.30, color: Color(hex: "#1E88E5"))
                                    NivelBadge(porcentaje: "40%", label: "Óptimo", activo: vm.porcentajeReduccion >= 0.40, color: Color(hex: "#1565C0"))
                                }
                            }
                            .padding(20)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                            .padding(.horizontal, 20)
                        }

                        // Trazabilidad certificada
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(titulo: "Trazabilidad certificada", icono: "checkmark.seal.fill", color: Color(hex: "#2E7D32"))

                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Color(hex: "#E8F5E9")).frame(width: 52, height: 52)
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color(hex: "#2E7D32"))
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                                        Text("\(certificados.count)")
                                            .font(.title2.bold())
                                            .foregroundStyle(Color(hex: "#2E7D32"))
                                        Text("certificados")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(String(format: "%.1f kg con destino verificado por SEDEMA", kgTrazables))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                        }
                        .padding(.horizontal, 20)

                        // Ahorro destacado
                        VStack(spacing: 8) {
                            Text("Ahorro estimado mensual")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.0f", ahorroTotal))")
                                .font(.system(size: 44, weight: .black))
                                .foregroundStyle(Color(hex: "#2E7D32"))
                            Text("MXN al presentar reporte ante SEDEMA")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#E8F5E9"), Color(hex: "#F1F8E9")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#4CAF50").opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        // Pasos
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(titulo: "¿Cómo funciona?", icono: "info.circle.fill", color: Color(hex: "#1565C0"))
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(Array(pasos.enumerated()), id: \.offset) { idx, paso in
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "#E3F2FD"))
                                                .frame(width: 36, height: 36)
                                            Text("\(idx + 1)")
                                                .font(.headline)
                                                .foregroundStyle(Color(hex: "#1565C0"))
                                        }
                                        Text(paso)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                    .padding(16)

                                    if idx < pasos.count - 1 {
                                        Divider().padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                            .padding(.horizontal, 20)
                        }

                        // Exportar
                        Button(action: exportarPDF) {
                            HStack(spacing: 10) {
                                if generandoPDF {
                                    ProgressView().tint(.white)
                                    Text("Generando PDF…").font(.headline)
                                } else {
                                    Image(systemName: "arrow.down.doc.fill")
                                    Text("Exportar reporte PDF").font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#42A5F5"), Color(hex: "#1565C0")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color(hex: "#1565C0").opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(generandoPDF)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear {
                withAnimation { animado = true }
            }
            .sheet(isPresented: $mostrandoShare) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    @MainActor
    private func exportarPDF() {
        generandoPDF = true
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            let pdfView = ReportePDFView(
                empresaNombre: "Walmart Polanco — Centro Logístico",
                periodo: ReportePDFView.periodoActual(),
                kgTotalesMes: vm.registro.kgTotalesMes,
                registrosCount: vm.registro.residuosRegistrados.count,
                kgPorTipo: vm.kgPorTipo,
                porcentajeClasificados: vm.porcentajeClasificados,
                porcentajeReduccion: vm.porcentajeReduccion,
                nominaMensual: nominaMensual,
                ahorroTotal: ahorroTotal,
                certificados: certificados
            )
            let url = ReportePDFView.renderToPDF(view: pdfView)
            await MainActor.run {
                self.pdfURL = url
                self.generandoPDF = false
                if url != nil { self.mostrandoShare = true }
            }
        }
    }

    private let pasos = [
        "Registra y clasifica tus residuos con Nexia",
        "Exporta el reporte de cumplimiento NADF-024",
        "Preséntalo ante SEDEMA para obtener la reducción",
        "Aplica el ahorro en tu declaración mensual de nómina"
    ]
}

// MARK: - Header

struct AhorroFiscalHeader: View {
    let reduccion: Double
    let ahorro: Double
    let animado: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#0D47A1"), Color(hex: "#1565C0"), Color(hex: "#1976D2")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 140, y: -40)
            Circle().fill(.white.opacity(0.04)).frame(width: 150).offset(x: -80, y: 30)

            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ahorro Fiscal")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Beneficio NADF-024")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.3))
                }

                HStack(spacing: 0) {
                    MetricaTarjeta(
                        valor: String(format: "%.0f%%", reduccion * 100),
                        unidad: "reducción",
                        label: "Impuesto nómina",
                        icono: "percent"
                    )
                    MetricaTarjeta(
                        valor: "$\(String(format: "%.0f", ahorro))",
                        unidad: "MXN",
                        label: "Ahorro estimado",
                        icono: "banknote.fill"
                    )
                }
                .scaleEffect(animado ? 1 : 0.9)
                .animation(.spring(response: 0.5).delay(0.2), value: animado)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Helpers

struct NivelBadge: View {
    let porcentaje: String
    let label: String
    let activo: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(porcentaje)
                .font(.headline.bold())
                .foregroundStyle(activo ? .white : color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(activo ? .white.opacity(0.85) : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(activo ? color : color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Reporte PDF

struct ReportePDFView: View {
    let empresaNombre: String
    let periodo: String
    let kgTotalesMes: Double
    let registrosCount: Int
    let kgPorTipo: [(tipo: String, kg: Double)]
    let porcentajeClasificados: Double
    let porcentajeReduccion: Double
    let nominaMensual: Double
    let ahorroTotal: Double
    let certificados: [CertificadoTrazabilidad]

    private var kgTrazables: Double { certificados.reduce(0) { $0 + $1.kgTotales } }
    private var folio: String { "REP-\(Int(Date().timeIntervalSince1970))" }
    private var fechaEmision: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "d 'de' MMMM 'de' yyyy"
        return f.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXIA")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(Color(hex: "#1B5E20"))
                    Text("Reporte de Trazabilidad de Residuos")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Folio").font(.system(size: 9)).foregroundColor(.secondary)
                    Text(folio).font(.system(size: 11, weight: .bold))
                    Text("Emisión").font(.system(size: 9)).foregroundColor(.secondary).padding(.top, 2)
                    Text(fechaEmision).font(.system(size: 11))
                }
            }
            .padding(.bottom, 12)

            Divider().background(Color(hex: "#1B5E20"))

            // Empresa + período
            VStack(alignment: .leading, spacing: 4) {
                Text("EMPRESA").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary).padding(.top, 12)
                Text(empresaNombre).font(.system(size: 15, weight: .semibold))
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PERÍODO").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                        Text(periodo).font(.system(size: 12))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MARCO LEGAL").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                        Text("NADF-024 · LGPGIR").font(.system(size: 12))
                    }
                }
                .padding(.top, 6)
            }

            // Métricas
            seccion(titulo: "Métricas del período")
            VStack(spacing: 6) {
                filaPDF(label: "Kg totales registrados", valor: String(format: "%.1f kg", kgTotalesMes))
                filaPDF(label: "Registros documentados", valor: "\(registrosCount)")
                filaPDF(label: "Kg con trazabilidad certificada", valor: String(format: "%.1f kg", kgTrazables))
                filaPDF(label: "Cumplimiento NADF-024", valor: String(format: "%.0f%%", porcentajeClasificados * 100))
                filaPDF(label: "Reducción aplicable", valor: String(format: "%.0f%% sobre nómina", porcentajeReduccion * 100))
                filaPDF(label: "Nómina mensual base", valor: "$\(formatoMoneda(nominaMensual)) MXN")
                filaPDF(label: "Ahorro fiscal estimado", valor: "$\(formatoMoneda(ahorroTotal)) MXN", destacado: true)
            }

            // Materiales
            if !kgPorTipo.isEmpty {
                seccion(titulo: "Desglose por tipo de residuo")
                VStack(spacing: 4) {
                    ForEach(kgPorTipo.prefix(6), id: \.tipo) { dato in
                        filaPDF(label: dato.tipo, valor: String(format: "%.1f kg", dato.kg))
                    }
                }
            }

            // Certificados
            if !certificados.isEmpty {
                seccion(titulo: "Certificados de trazabilidad emitidos")
                VStack(spacing: 0) {
                    HStack {
                        Text("FOLIO").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary).frame(width: 78, alignment: .leading)
                        Text("FECHA").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary).frame(width: 64, alignment: .leading)
                        Text("KG").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary).frame(width: 50, alignment: .leading)
                        Text("CENTRO DESTINO").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(Color(hex: "#E8F5E9"))

                    ForEach(certificados.prefix(10)) { cert in
                        HStack {
                            Text(cert.folio).font(.system(size: 10, weight: .semibold)).foregroundColor(Color(hex: "#1B5E20")).frame(width: 78, alignment: .leading)
                            Text(fechaCorta(cert.fecha)).font(.system(size: 10)).frame(width: 64, alignment: .leading)
                            Text(String(format: "%.1f", cert.kgTotales)).font(.system(size: 10)).frame(width: 50, alignment: .leading)
                            Text(cert.centroDestino).font(.system(size: 10)).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#C8E6C9"), lineWidth: 0.5))
            }

            Spacer(minLength: 12)

            // Footer
            VStack(spacing: 4) {
                Divider()
                HStack {
                    Text("Generado por Nexia · Procesado on-device con Apple Intelligence")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Pág. 1 de 1").font(.system(size: 8)).foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(36)
        .frame(width: 612, height: 792, alignment: .top)
        .background(Color.white)
    }

    private func seccion(titulo: String) -> some View {
        Text(titulo)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color(hex: "#1B5E20"))
            .padding(.top, 14)
            .padding(.bottom, 4)
    }

    private func filaPDF(label: String, valor: String, destacado: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(destacado ? Color(hex: "#1B5E20") : .primary)
            Spacer()
            Text(valor)
                .font(.system(size: 11, weight: destacado ? .bold : .regular))
                .foregroundColor(destacado ? Color(hex: "#1B5E20") : .primary)
        }
        .padding(.vertical, 3)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(.systemGray5)).frame(height: 0.5)
        }
    }

    private func fechaCorta(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "d MMM yyyy"
        return f.string(from: d)
    }

    private func formatoMoneda(_ valor: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: valor)) ?? String(format: "%.0f", valor)
    }

    static func periodoActual() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date()).capitalized
    }

    @MainActor
    static func renderToPDF(view: ReportePDFView) -> URL? {
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: 612, height: 792)

        let nombre = "Nexia-Reporte-\(Int(Date().timeIntervalSince1970)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(nombre)

        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            return nil
        }

        renderer.render { _, drawingContext in
            pdfContext.beginPDFPage(nil)
            drawingContext(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }

        return url
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
