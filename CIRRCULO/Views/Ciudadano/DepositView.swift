import SwiftUI
import AVFoundation

struct DepositView: View {
    @State private var materialesTicket: [TipoResiduo: Double] = [
        .plasticoPET: 1.0,
        .carton: 2.5,
        .aluminio: 0.3
    ]
    @State private var modoVerificacion = false
    @State private var mostrarMapa = false
    @State private var depositoVerificado = false

    private var totalPuntos: Int {
        materialesTicket.reduce(0) { $0 + Int($1.value * Double($1.key.puntosPorKg)) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if depositoVerificado {
                        CelebracionView(puntos: totalPuntos)
                    } else if modoVerificacion {
                        VerificacionQRView(onVerificado: {
                            withAnimation(.spring()) { depositoVerificado = true }
                        })
                    } else {
                        TicketView(
                            materiales: materialesTicket,
                            totalPuntos: totalPuntos,
                            onIrADepositar: { mostrarMapa = true }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Depositar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $mostrarMapa) {
                MapaAcopioView()
            }
            .toolbar {
                if !depositoVerificado && !modoVerificacion {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Verificar QR") {
                            modoVerificacion = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Ticket View

struct TicketView: View {
    let materiales: [TipoResiduo: Double]
    let totalPuntos: Int
    let onIrADepositar: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header ticket
            VStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "#388E3C"))
                Text("Tu ticket de reciclaje")
                    .font(.title2.bold())
                Text("Materiales escaneados en esta sesión")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            // Lista de materiales
            VStack(spacing: 0) {
                ForEach(Array(materiales.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { tipo in
                    HStack {
                        Circle()
                            .fill(colorContenedor(tipo.contenedor))
                            .frame(width: 10, height: 10)
                        Text(tipo.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text("\(materiales[tipo]!, specifier: "%.1f") kg")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("+\(Int((materiales[tipo] ?? 0) * Double(tipo.puntosPorKg))) pts")
                            .font(.caption.bold())
                            .foregroundStyle(Color(hex: "#388E3C"))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)

                    if tipo != materiales.keys.sorted(by: { $0.rawValue < $1.rawValue }).last {
                        Divider().padding(.horizontal)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 6)

            // Total puntos
            HStack {
                Text("Total estimado")
                    .font(.headline)
                Spacer()
                Text("\(totalPuntos) puntos")
                    .font(.title3.bold())
                    .foregroundStyle(Color(hex: "#388E3C"))
            }
            .padding()
            .background(Color(hex: "#E8F5E9"))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Botón
            Button(action: onIrADepositar) {
                Label("Ver puntos de acopio cercanos", systemImage: "map.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#388E3C"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func colorContenedor(_ c: ContenedorNADF) -> Color {
        switch c {
        case .verde:   return Color(hex: "#4CAF50")
        case .gris:    return Color(hex: "#607D8B")
        case .naranja: return Color(hex: "#FF5722")
        }
    }
}

// MARK: - Verificación QR

struct VerificacionQRView: View {
    let onVerificado: () -> Void
    @State private var simulandoEscaneo = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(Color(hex: "#388E3C"))

            Text("Escanea el QR del punto de acopio")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("El código QR está pegado en el contenedor del local donde vas a depositar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Simulación para el hackathon
            Button {
                simulandoEscaneo = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    await MainActor.run { onVerificado() }
                }
            } label: {
                if simulandoEscaneo {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Label("Simular escaneo de QR (demo)", systemImage: "qrcode")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#388E3C"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .disabled(simulandoEscaneo)
        }
        .padding()
    }
}

// MARK: - Celebración

struct CelebracionView: View {
    let puntos: Int
    @State private var animando = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 140, height: 140)
                    .scaleEffect(animando ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animando)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color(hex: "#388E3C"))
            }

            Text("¡Depósito verificado!")
                .font(.title.bold())
                .foregroundStyle(Color(hex: "#1B5E20"))

            VStack(spacing: 8) {
                Text("+\(puntos)")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Color(hex: "#388E3C"))
                Text("puntos ganados")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text("Gracias por contribuir a la economía circular de México")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .onAppear { animando = true }
    }
}

#Preview {
    DepositView()
}
