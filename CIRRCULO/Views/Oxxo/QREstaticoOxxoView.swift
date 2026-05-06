import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct QREstaticoOxxoView: View {
    @EnvironmentObject var store: AppDataStore
    private var punto: PuntoAcopio { store.puntosAcopio[store.miOxxoIndex] }
    @State private var aparecio = false

    private var qrImage: Image {
        generarQR(desde: punto.qrCode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    QROxxoHeader(punto: punto)

                    VStack(spacing: 28) {
                        // Imagen de la tienda
                        if let imagenAsset = punto.imagenAsset {
                            Image(imagenAsset)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 140)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 32)
                        }

                        // QR Card
                        VStack(spacing: 20) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.white)
                                    .shadow(color: Color(hex: "#D50000").opacity(0.15), radius: 20, y: 8)

                                VStack(spacing: 16) {
                                    qrImage
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 220, height: 220)

                                    VStack(spacing: 4) {
                                        Text(punto.nombre)
                                            .font(.headline.bold())
                                            .foregroundStyle(Color(hex: "#D50000"))
                                        Text("Punto de Acopio Aliado")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
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
                                          color: Color(hex: "#D50000"))

                            VStack(spacing: 0) {
                                OxxoInstruccionRow(numero: "1", texto: "Imprime este QR y pégalo junto al contenedor de reciclaje de tu tienda")
                                Divider().padding(.horizontal, 16)
                                OxxoInstruccionRow(numero: "2", texto: "Los ciudadanos escanean el QR con CIRRCULO al depositar sus materiales")
                                Divider().padding(.horizontal, 16)
                                OxxoInstruccionRow(numero: "3", texto: "Los depósitos se registran automáticamente en tu panel")
                                Divider().padding(.horizontal, 16)
                                OxxoInstruccionRow(numero: "4", texto: "Cuando el contenedor esté lleno, solicita un recolector desde tu panel")
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
                                    colors: [Color(hex: "#FF5252"), Color(hex: "#D50000")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color(hex: "#D50000").opacity(0.3), radius: 8, y: 4)
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

struct QROxxoHeader: View {
    let punto: PuntoAcopio

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#B71C1C"), Color(hex: "#D50000"), Color(hex: "#FF1744")],
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
                        Label(punto.nombre, systemImage: "storefront.fill")
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

struct OxxoInstruccionRow: View {
    let numero: String
    let texto: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FFEBEE"))
                    .frame(width: 36, height: 36)
                Text(numero)
                    .font(.headline.bold())
                    .foregroundStyle(Color(hex: "#D50000"))
            }
            Text(texto)
                .font(.subheadline)
            Spacer()
        }
        .padding(16)
    }
}

#Preview {
    QREstaticoOxxoView()
        .environmentObject(AppDataStore())
}
