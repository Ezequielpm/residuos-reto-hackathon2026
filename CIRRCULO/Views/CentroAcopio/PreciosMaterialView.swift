import SwiftUI

struct PreciosMaterialView: View {
    @EnvironmentObject var store: AppDataStore
    private var centro: CentroAcopio { store.centrosAcopio[store.miCentroAcopioIndex] }
    @State private var preciosEditados: [TipoResiduo: String] = [:]
    @State private var modoEdicion = false
    @State private var guardado = false

    private var materialesOrdenados: [TipoResiduo] {
        centro.preciosMaterial.keys.sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    PreciosHeader(centro: centro)

                    VStack(spacing: 20) {
                        // Precios
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SectionHeader(titulo: "Precios actuales (MXN/kg)",
                                              icono: "tag.fill",
                                              color: Color(hex: "#AD1457"))
                                Spacer()
                                Button(modoEdicion ? "Guardar" : "Editar") {
                                    if modoEdicion {
                                        for (tipo, valorStr) in preciosEditados {
                                            if let valor = Double(valorStr) {
                                                store.centrosAcopio[store.miCentroAcopioIndex].preciosMaterial[tipo] = valor
                                            }
                                        }
                                        preciosEditados = [:]
                                        withAnimation { guardado = true }
                                        Task {
                                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                                            await MainActor.run { withAnimation { guardado = false } }
                                        }
                                    }
                                    withAnimation(.spring()) { modoEdicion.toggle() }
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(modoEdicion ? Color(hex: "#4CAF50") : Color(hex: "#AD1457"))
                                .padding(.trailing, 20)
                            }

                            if guardado {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Precios actualizados")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(Color(hex: "#4CAF50"))
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "#E8F5E9"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            VStack(spacing: 0) {
                                ForEach(materialesOrdenados, id: \.self) { tipo in
                                    PrecioRow(
                                        tipo: tipo,
                                        precio: centro.preciosMaterial[tipo] ?? 0,
                                        modoEdicion: modoEdicion,
                                        textoBound: Binding(
                                            get: { preciosEditados[tipo] ?? String(format: "%.2f", centro.preciosMaterial[tipo] ?? 0) },
                                            set: { preciosEditados[tipo] = $0 }
                                        )
                                    )

                                    if tipo != materialesOrdenados.last {
                                        Divider().padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        }
                        .padding(.horizontal, 20)

                        // Última actualización
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text("Última actualización: ")
                                .foregroundStyle(.secondary)
                            + Text(Date(), style: .date)
                        }
                        .font(.caption)
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
        }
    }
}

// MARK: - Header

struct PreciosHeader: View {
    let centro: CentroAcopio

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#880E4F"), Color(hex: "#AD1457"), Color(hex: "#C2185B")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 130, y: -30)
            Circle().fill(.white.opacity(0.04)).frame(width: 140).offset(x: -70, y: 25)

            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Precios de Compra")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(centro.nombre)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "tag.circle.fill")
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

struct PrecioRow: View {
    let tipo: TipoResiduo
    let precio: Double
    let modoEdicion: Bool
    @Binding var textoBound: String

    private var colorContenedor: Color {
        switch tipo.contenedor {
        case .verde:   return Color(hex: "#4CAF50")
        case .gris:    return Color(hex: "#607D8B")
        case .naranja: return Color(hex: "#FF5722")
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorContenedor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Circle()
                    .fill(colorContenedor)
                    .frame(width: 10, height: 10)
            }

            Text(tipo.rawValue)
                .font(.subheadline)

            Spacer()

            if modoEdicion {
                HStack(spacing: 4) {
                    Text("$")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("0.00", text: $textoBound)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 64)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "#AD1457"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#FCE4EC"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text("$\(String(format: "%.2f", precio))")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "#AD1457"))
            }
        }
        .padding(16)
    }
}

#Preview {
    PreciosMaterialView()
}
