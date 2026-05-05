import SwiftUI
import AVFoundation

struct ScannerView: View {
    @StateObject private var camera = CameraService()

    @State private var resultado: ResultadoClasificacion?
    @State private var instruccionesDinamicas: String?
    @State private var pistAmbiguedad: String?
    @State private var materialesTicket: [TipoResiduo: Double] = [:]
    @State private var mostrarGuardado = false
    @State private var clasificando = false
    @State private var mostrarModoDemo = false

    // Objetos de demo para la presentación
    private let objetosDemo: [(nombre: String, tipo: TipoResiduo, confianza: Float)] = [
        ("Botella PET",        .plasticoPET,    0.94),
        ("Lata de aluminio",   .aluminio,       0.97),
        ("Caja de cartón",     .carton,         0.91),
        ("Botella de vidrio",  .vidrio,         0.88),
        ("Restos de comida",   .organicoComida, 0.93),
        ("Envase HDPE",        .plasticoHDPE,   0.62), // ambiguo a propósito
        ("Tetra Pak",          .tetraPak,       0.85),
        ("Basura mixta",       .noReciclable,   0.96),
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Preview cámara
                CameraPreviewLayer(session: camera.captureSession)
                    .ignoresSafeArea()

                // Overlay animado
                ScannerOverlay()

                // Panel demo (si está activo)
                if mostrarModoDemo {
                    PanelModoDemo(objetos: objetosDemo) { obj in
                        mostrarModoDemo = false
                        simularClasificacion(nombre: obj.nombre, tipo: obj.tipo, confianza: obj.confianza)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    VStack {
                        Spacer()
                        if let resultado {
                            PanelResultado(
                                resultado: resultado,
                                instrucciones: instruccionesDinamicas,
                                pistaAmbiguedad: pistAmbiguedad,
                                onGuardar: { guardarEnTicket(resultado) },
                                onSeleccionManual: { tipo in aplicarSeleccionManual(tipo) }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            HintEscaneo(clasificando: clasificando) {
                                withAnimation { mostrarModoDemo = true }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Clasificar Residuo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if mostrarModoDemo {
                        Button("Cancelar") {
                            withAnimation { mostrarModoDemo = false }
                        }
                        .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if !materialesTicket.isEmpty {
                            Label("\(materialesTicket.count)", systemImage: "bag.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color(hex: "#4CAF50"))
                        }
                        if !mostrarModoDemo {
                            Button {
                                withAnimation { mostrarModoDemo = true }
                            } label: {
                                Label("Demo", systemImage: "play.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: "#F9A825"))
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                if mostrarGuardado {
                    GuardadoBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .task { await camera.solicitarPermiso() }
        .onChange(of: camera.pixelBuffer) { _, buffer in
            guard let buffer, !clasificando, !mostrarModoDemo else { return }
            clasificando = true
            Task {
                if let r = await ClassifierService.shared.clasificar(pixelBuffer: buffer) {
                    await MainActor.run {
                        withAnimation(.spring(response: 0.4)) { resultado = r }
                        clasificando = false
                    }
                    let ins = await FoundationModelsService.shared.instruccionesParaMaterial(r)
                    await MainActor.run { instruccionesDinamicas = ins }

                    if r.esAmbiguo, let top2 = topDosOpciones(r) {
                        let pista = await FoundationModelsService.shared
                            .resolverAmbiguedad(opcion1: top2.0, opcion2: top2.1)
                        await MainActor.run { pistAmbiguedad = pista }
                    }
                } else {
                    await MainActor.run { clasificando = false }
                }
            }
        }
    }

    // MARK: - Acciones

    private func simularClasificacion(nombre: String, tipo: TipoResiduo, confianza: Float) {
        let contenedor = tipo.contenedor
        let r = ResultadoClasificacion(
            tipo: tipo,
            contenedor: contenedor,
            confianza: confianza,
            proximaRecoleccion: proximaRecoleccionTexto(para: contenedor),
            instrucciones: ClassifierService.instruccionesHardcodeadas[tipo] ?? "",
            valorMercado: tipo.valorMercado
        )
        withAnimation(.spring(response: 0.4)) { resultado = r }

        Task {
            let ins = await FoundationModelsService.shared.instruccionesParaMaterial(r)
            await MainActor.run { instruccionesDinamicas = ins }
            if r.esAmbiguo, let top2 = topDosOpciones(r) {
                let pista = await FoundationModelsService.shared
                    .resolverAmbiguedad(opcion1: top2.0, opcion2: top2.1)
                await MainActor.run { pistAmbiguedad = pista }
            }
        }
    }

    private func guardarEnTicket(_ r: ResultadoClasificacion) {
        materialesTicket[r.tipo, default: 0] += 0.5
        withAnimation { mostrarGuardado = true }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { withAnimation { mostrarGuardado = false } }
        }
    }

    private func aplicarSeleccionManual(_ tipo: TipoResiduo) {
        guard let r = resultado else { return }
        let nuevo = ResultadoClasificacion(
            tipo: tipo, contenedor: tipo.contenedor, confianza: 1.0,
            proximaRecoleccion: r.proximaRecoleccion,
            instrucciones: ClassifierService.instruccionesHardcodeadas[tipo] ?? "",
            valorMercado: tipo.valorMercado
        )
        withAnimation { resultado = nuevo; pistAmbiguedad = nil }
        guardarEnTicket(nuevo)
    }

    private func topDosOpciones(_ r: ResultadoClasificacion) -> (TipoResiduo, TipoResiduo)? {
        let otros = TipoResiduo.allCases.filter { $0 != r.tipo }
        guard let segundo = otros.first else { return nil }
        return (r.tipo, segundo)
    }
}

// MARK: - Hint inicial

struct HintEscaneo: View {
    let clasificando: Bool
    let onDemo: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(clasificando ? "Clasificando…" : "Apunta a un residuo")
                .font(.headline)
                .foregroundStyle(.white)

            Button(action: onDemo) {
                Label("Modo Demo", systemImage: "play.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "#F9A825"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 36)
    }
}

// MARK: - Panel Modo Demo

struct PanelModoDemo: View {
    let objetos: [(nombre: String, tipo: TipoResiduo, confianza: Float)]
    let onSeleccionar: ((nombre: String, tipo: TipoResiduo, confianza: Float)) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            Text("Selecciona un objeto para la demo")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(objetos, id: \.nombre) { obj in
                        Button { onSeleccionar(obj) } label: {
                            HStack(spacing: 14) {
                                // Color del contenedor
                                Circle()
                                    .fill(colorContenedor(obj.tipo.contenedor))
                                    .frame(width: 14, height: 14)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(obj.nombre)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Text(obj.tipo.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                // Confianza
                                Text(obj.confianza < 0.70 ? "⚠ Ambiguo" : "\(Int(obj.confianza * 100))%")
                                    .font(.caption.bold())
                                    .foregroundStyle(obj.confianza < 0.70
                                                     ? Color(hex: "#F9A825")
                                                     : Color(hex: "#388E3C"))

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(maxHeight: 380)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 20)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func colorContenedor(_ c: ContenedorNADF) -> Color {
        switch c {
        case .verde:   return Color(hex: "#4CAF50")
        case .gris:    return Color(hex: "#607D8B")
        case .naranja: return Color(hex: "#FF5722")
        }
    }
}

// MARK: - CameraPreviewLayer

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Scanner Overlay

struct ScannerOverlay: View {
    @State private var animando = false
    private let boxSize: CGFloat = 220

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height * 0.33

            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .mask(
                        Rectangle()
                            .ignoresSafeArea()
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: boxSize, height: boxSize)
                                    .position(x: cx, y: cy)
                                    .blendMode(.destinationOut)
                            )
                    )

                Group {
                    CornerL().position(x: cx - boxSize/2 + 14, y: cy - boxSize/2 + 14)
                    CornerL().rotationEffect(.degrees(90)).position(x: cx + boxSize/2 - 14, y: cy - boxSize/2 + 14)
                    CornerL().rotationEffect(.degrees(180)).position(x: cx + boxSize/2 - 14, y: cy + boxSize/2 - 14)
                    CornerL().rotationEffect(.degrees(270)).position(x: cx - boxSize/2 + 14, y: cy + boxSize/2 - 14)
                }
                .foregroundStyle(.white)

                Rectangle()
                    .fill(Color(hex: "#4CAF50").opacity(0.85))
                    .frame(width: boxSize - 20, height: 2)
                    .clipShape(Capsule())
                    .position(x: cx, y: animando ? cy + boxSize/2 - 10 : cy - boxSize/2 + 10)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: animando)
            }
        }
        .onAppear { animando = true }
    }
}

struct CornerL: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: -14, y: 0))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 0, y: 14))
        }
        .stroke(lineWidth: 3)
        .frame(width: 28, height: 28)
    }
}

// MARK: - Panel Resultado

struct PanelResultado: View {
    let resultado: ResultadoClasificacion
    let instrucciones: String?
    let pistaAmbiguedad: String?
    let onGuardar: () -> Void
    let onSeleccionManual: (TipoResiduo) -> Void

    private var colorContenedor: Color {
        switch resultado.contenedor {
        case .verde:   return Color(hex: "#4CAF50")
        case .gris:    return Color(hex: "#607D8B")
        case .naranja: return Color(hex: "#FF5722")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(resultado.esAmbiguo ? Color(hex: "#F9A825") : colorContenedor)
                .frame(height: 4)

            VStack(spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resultado.tipo.rawValue)
                            .font(.title2.bold())
                        HStack(spacing: 6) {
                            Circle().fill(colorContenedor).frame(width: 10, height: 10)
                            Text("Contenedor \(resultado.contenedor.rawValue)")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(resultado.proximaRecoleccion)
                            .font(.caption.bold()).foregroundStyle(colorContenedor)
                        Text("próxima recolección")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }

                if let ins = instrucciones {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(colorContenedor)
                            .font(.caption)
                        Text(ins)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(colorContenedor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if resultado.esAmbiguo {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color(hex: "#F9A825"))
                                .font(.caption)
                            Text("Confianza baja — selecciona manualmente")
                                .font(.caption.bold())
                                .foregroundStyle(Color(hex: "#F9A825"))
                        }

                        if let pista = pistaAmbiguedad {
                            Text(pista)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 8) {
                            AmbiguedadBoton(tipo: resultado.tipo,
                                            onSelect: { onSeleccionManual(resultado.tipo) })
                            let alternativo: TipoResiduo = resultado.tipo == .plasticoPET ? .plasticoHDPE : .carton
                            AmbiguedadBoton(tipo: alternativo,
                                            onSelect: { onSeleccionManual(alternativo) })
                        }
                    }
                    .padding(12)
                    .background(Color(hex: "#FFF8E1"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#F9A825").opacity(0.4)))
                }

                Button(action: onGuardar) {
                    Label("Guardar en ticket (+\(Int(0.5 * Double(resultado.tipo.puntosPorKg))) pts)",
                          systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(colorContenedor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

struct AmbiguedadBoton: View {
    let tipo: TipoResiduo
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(tipo.rawValue)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Banner Guardado

struct GuardadoBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text("Guardado en tu ticket").font(.subheadline.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(radius: 4)
        .padding(.top, 8)
    }
}

#Preview {
    ScannerView()
}
