import SwiftUI
import CoreImage.CIFilterBuiltins

struct QREstaticoView: View {
    @State private var punto = MockDataService.shared.puntosAcopio[0]

    private var qrImage: Image {
        generarQR(desde: punto.qrCode)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // QR grande
                qrImage
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.12), radius: 10)

                VStack(spacing: 8) {
                    Text(punto.nombre)
                        .font(.title2.bold())
                    Text(punto.direccion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("Imprime este código y pégalo en tu contenedor de reciclaje para que los ciudadanos puedan verificar sus depósitos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ShareLink(item: punto.qrCode, preview: SharePreview("QR — \(punto.nombre)")) {
                    Label("Compartir código QR", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#6A1B9A"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Mi código QR")
            .navigationBarTitleDisplayMode(.inline)
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
}

#Preview {
    QREstaticoView()
}
