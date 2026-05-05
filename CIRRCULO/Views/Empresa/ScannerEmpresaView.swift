import SwiftUI

struct ScannerEmpresaView: View {
    @ObservedObject var vm: EmpresaViewModel
    @StateObject private var camera = CameraService()

    @State private var resultado: ResultadoClasificacion?
    @State private var mostrandoConfirmacion = false
    @State private var contadorSesion = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                CameraPreviewLayer(session: camera.captureSession)
                    .ignoresSafeArea()

                ScannerOverlay()

                VStack {
                    Spacer()

                    if let resultado {
                        PanelEmpresaResultado(resultado: resultado) {
                            vm.registrarEscaneo(tipo: resultado.tipo)
                            contadorSesion += 1
                            withAnimation { mostrandoConfirmacion = true }
                            Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                await MainActor.run { withAnimation { mostrandoConfirmacion = false } }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Text("Apunta al residuo para clasificar")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Escáner Corporativo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if contadorSesion > 0 {
                        Label("\(contadorSesion) registrados", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Color(hex: "#4CAF50"))
                    }
                }
            }
            .overlay(alignment: .top) {
                if mostrandoConfirmacion {
                    RegistradoBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .task { await camera.solicitarPermiso() }
        .onChange(of: camera.pixelBuffer) { _, buffer in
            guard let buffer else { return }
            Task {
                if let r = await ClassifierService.shared.clasificar(pixelBuffer: buffer) {
                    await MainActor.run {
                        withAnimation(.spring(response: 0.4)) { resultado = r }
                    }
                }
            }
        }
    }
}

struct PanelEmpresaResultado: View {
    let resultado: ResultadoClasificacion
    let onRegistrar: () -> Void

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
                .fill(Color(hex: "#1565C0"))
                .frame(height: 4)

            VStack(spacing: 16) {
                HStack {
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
                        Text("$\(String(format: "%.2f", resultado.valorMercado))/kg")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(hex: "#1565C0"))
                        Text("valor mercado")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }

                Button(action: onRegistrar) {
                    Label("Registrar en dashboard", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#1565C0"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

struct RegistradoBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "#1565C0"))
            Text("Registrado en el dashboard")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(radius: 4)
        .padding(.top, 8)
    }
}
