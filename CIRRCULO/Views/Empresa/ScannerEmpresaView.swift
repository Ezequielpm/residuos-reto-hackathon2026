import SwiftUI

struct ScannerEmpresaView: View {
    @ObservedObject var vm: EmpresaViewModel
    @StateObject private var camera = CameraService()

    @State private var resultado: ResultadoClasificacion?
    @State private var isAnalyzing = false
    @State private var mostrandoConfirmacion = false
    @State private var contadorSesion = 0
    @State private var lastClassification: Date = .distantPast

    private let accentColor = Color(hex: "#1565C0")

    private var activeColor: Color {
        guard let r = resultado else { return .white.opacity(0.5) }
        return Color(hex: r.contenedor.colorHex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewLayer(session: camera.captureSession)
                .ignoresSafeArea()

            // Gradient overlays
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 280)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                Spacer()
                viewfinder
                Spacer()
                bottomPanel
            }

            // Confirmation banner
            if mostrandoConfirmacion {
                VStack {
                    registradoBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 60)
                .zIndex(10)
            }
        }
        .task { await camera.solicitarPermiso() }
        .onChange(of: camera.frameCount) { _, _ in
            guard let frame = camera.currentFrame else { return }
            let now = Date()
            guard now.timeIntervalSince(lastClassification) >= 0.8, !isAnalyzing else { return }
            lastClassification = now
            isAnalyzing = true

            ClassifierService.shared.clasificar(cgImage: frame) { enriquecido in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.resultado = enriquecido.resultado
                }
                self.isAnalyzing = false
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            if contadorSesion > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("\(contadorSesion)")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }

            Spacer()

            Text("ESCÁNER CORPORATIVO")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.9))
                .tracking(1.2)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(isAnalyzing ? .orange : accentColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: isAnalyzing ? .orange : accentColor, radius: 4)
                Text(isAnalyzing ? "Analizando" : "En vivo")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Viewfinder

    private var viewfinder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(accentColor.opacity(0.5), lineWidth: 2)
                .frame(width: 260, height: 260)
                .shadow(color: accentColor.opacity(0.2), radius: 12)

            ScannerCornerBrackets(color: accentColor)
                .frame(width: 260, height: 260)

            if let r = resultado {
                Image(systemName: iconForTipo(r.tipo))
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(activeColor)
                    .padding(18)
                    .background(activeColor.opacity(0.15))
                    .clipShape(Circle())
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.35), value: r.tipo)
            }
        }
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            if let r = resultado {
                resultCard(r)
            } else {
                placeholderPill
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: resultado?.tipo)
        .padding(.horizontal, 16)
        .padding(.bottom, 36)
    }

    private func resultCard(_ r: ResultadoClasificacion) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: r.contenedor.colorHex).opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: iconForTipo(r.tipo))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color(hex: r.contenedor.colorHex))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(r.tipo.rawValue)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    if !r.objetoDetectado.isEmpty {
                        Text("Detectado: \(r.objetoDetectado)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: r.contenedor.colorHex))
                            .frame(width: 8, height: 8)
                        Text("Contenedor \(r.contenedor.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("$\(String(format: "%.2f", r.valorMercado))/kg")
                        .font(.subheadline.bold())
                        .foregroundStyle(accentColor)
                    Text("valor mercado")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Container info bar
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(Color(hex: r.contenedor.colorHex))
                Text("Depositar en contenedor \(r.contenedor.rawValue.lowercased())")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: r.contenedor.colorHex).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Register button
            Button {
                vm.registrarEscaneo(tipo: r.tipo)
                contadorSesion += 1
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.3)) { mostrandoConfirmacion = true }
                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    await MainActor.run { withAnimation { mostrandoConfirmacion = false } }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Registrar en dashboard")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var placeholderPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "viewfinder")
                .font(.subheadline)
            Text("Apunta al residuo para clasificar")
                .font(.subheadline)
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(.vertical, 14)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(Capsule())
    }

    private var registradoBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(accentColor)
            Text("Registrado en dashboard")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private func iconForTipo(_ tipo: TipoResiduo) -> String {
        switch tipo {
        case .plasticoPET, .plasticoHDPE: return "waterbottle.fill"
        case .carton:          return "shippingbox.fill"
        case .papel:           return "doc.fill"
        case .vidrio:          return "wineglass.fill"
        case .aluminio, .lata: return "cylinder.fill"
        case .organicoComida:  return "leaf.fill"
        case .electronico:     return "bolt.fill"
        case .textil:          return "tshirt.fill"
        case .organicoPoda:    return "tree.fill"
        case .noReciclable:    return "xmark.bin.fill"
        case .tetraPak:        return "takeoutbag.and.cup.and.straw.fill"
        }
    }
}
