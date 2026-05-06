import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct QREstaticoView: View {
    @EnvironmentObject var store: AppDataStore
    private var punto: PuntoAcopio { store.puntosAcopio[store.miPuntoAcopioIndex] }
    @State private var aparecio = false

    private var qrImage: Image {
        generarQR(desde: punto.qrCode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    QRHeader(punto: punto)

                    VStack(spacing: 28) {
                        // QR Card
                        VStack(spacing: 20) {
                            // QR grande con borde decorativo
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.white)
                                    .shadow(color: Color(hex: "#6A1B9A").opacity(0.15), radius: 20, y: 8)

                                VStack(spacing: 16) {
                                    qrImage
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 220, height: 220)

                                    VStack(spacing: 4) {
                                        Text(punto.nombre)
                                            .font(.headline.bold())
                                            .foregroundStyle(Color(hex: "#6A1B9A"))
                                        Text(punto.qrCode)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(24)
                            }
                            .scaleEffect(aparecio ? 1 : 0.8)
                            .opacity(aparecio ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1), value: aparecio)
                        }
                        .padding(.horizontal, 32)

                        // Instrucciones
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(titulo: "Instrucciones",
                                          icono: "info.circle.fill",
                                          color: Color(hex: "#6A1B9A"))

                            VStack(spacing: 0) {
                                InstruccionRow(numero: "1", texto: "Imprime este código en tamaño A5 o mayor")
                                Divider().padding(.horizontal, 16)
                                InstruccionRow(numero: "2", texto: "Pégalo en tu contenedor de reciclaje o en la pared cercana")
                                Divider().padding(.horizontal, 16)
                                InstruccionRow(numero: "3", texto: "Los ciudadanos lo escanean con Nexia para verificar su depósito")
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        }
                        .padding(.horizontal, 20)

                        // Imprimir
                        Button {
                            imprimirQR()
                        } label: {
                            HStack {
                                Image(systemName: "printer.fill")
                                Text("Imprimir código QR")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#AB47BC"), Color(hex: "#6A1B9A")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color(hex: "#6A1B9A").opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .onAppear {
                withAnimation { aparecio = true }
            }
        }
    }

    private func generarQR(desde texto: String) -> Image {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(texto.utf8)
        filter.correctionLevel = "M"
        if let outputImage = filter.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return Image(cgImage, scale: 1, label: Text("QR Code"))
            }
        }
        return Image(systemName: "qrcode")
    }

    private func generarQRUIImage(desde texto: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(texto.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let escalada = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext()
        guard let cgImage = context.createCGImage(escalada, from: escalada.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func imprimirQR() {
        guard let imagen = generarQRUIImage(desde: punto.qrCode) else { return }
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "QR — \(punto.nombre)"
        info.orientation = .portrait

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = imagen
        controller.present(animated: true, completionHandler: nil)
    }
}

// MARK: - Header

struct QRHeader: View {
    let punto: PuntoAcopio

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#4A148C"), Color(hex: "#6A1B9A"), Color(hex: "#7B1FA2")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 130, y: -30)
            Circle().fill(.white.opacity(0.04)).frame(width: 140).offset(x: -70, y: 25)

            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mi código QR")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Label(punto.nombre, systemImage: "mappin.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "qrcode")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 24)
        }
    }
}

struct InstruccionRow: View {
    let numero: String
    let texto: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#F3E5F5"))
                    .frame(width: 36, height: 36)
                Text(numero)
                    .font(.headline.bold())
                    .foregroundStyle(Color(hex: "#6A1B9A"))
            }
            Text(texto)
                .font(.subheadline)
            Spacer()
        }
        .padding(16)
    }
}

#Preview {
    QREstaticoView()
}
