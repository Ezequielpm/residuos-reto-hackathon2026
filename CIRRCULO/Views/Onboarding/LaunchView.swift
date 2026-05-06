import SwiftUI

/// Splash screen animado que se muestra al iniciar la app antes de ProfileSelectorView
struct LaunchView: View {
    @State private var escala: CGFloat = 0.6
    @State private var opacidad: Double = 0
    @State private var rotacion: Double = -30
    @State private var listo = false

    let onTerminado: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#1B5E20").ignoresSafeArea()

            VStack(spacing: 20) {
                // Ícono animado
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "arrow.3.trianglepath")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(rotacion))
                }
                .scaleEffect(escala)

                VStack(spacing: 6) {
                    Text("Nexia")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(.white)
                        .tracking(4)

                    Text("Economía Circular en México")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .opacity(opacidad)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                escala = 1.0
                rotacion = 0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                opacidad = 1.0
            }
            // Navegar a ProfileSelector tras 1.8 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    listo = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onTerminado()
                }
            }
        }
    }
}

#Preview {
    LaunchView(onTerminado: {})
}
