import SwiftUI

struct EntregaView: View {
    @State private var centros = MockDataService.shared.centrosAcopio
    @State private var kgIngresados: [TipoResiduo: String] = [
        .aluminio: "3.2",
        .plasticoPET: "8.5",
        .carton: "12.0"
    ]
    @State private var centroSeleccionado: CentroAcopio?
    @State private var entregaConfirmada = false
    @State private var animado = false

    private var totalIngresos: Double {
        kgIngresados.reduce(0.0) { acc, entry in
            guard let kg = Double(entry.value), let centro = centroSeleccionado else { return acc }
            return acc + kg * (centro.preciosMaterial[entry.key] ?? entry.key.valorMercado)
        }
    }

    private var materialesOrdenados: [TipoResiduo] {
        kgIngresados.keys.sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        NavigationStack {
            if entregaConfirmada {
                ConfirmacionEntregaView(
                    ingresos: totalIngresos,
                    centro: centroSeleccionado?.nombre ?? "Centro de acopio"
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        EntregaHeaderCard(totalIngresos: totalIngresos, centroSeleccionado: centroSeleccionado)

                        // Material recogido
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(titulo: "Material recogido",
                                          icono: "shippingbox.fill",
                                          color: Color(hex: "#E65100"))

                            VStack(spacing: 0) {
                                ForEach(materialesOrdenados, id: \.self) { tipo in
                                    KgInputRow(
                                        tipo: tipo,
                                        texto: Binding(
                                            get: { kgIngresados[tipo] ?? "0" },
                                            set: { kgIngresados[tipo] = $0 }
                                        ),
                                        precio: centroSeleccionado?.preciosMaterial[tipo] ?? tipo.valorMercado
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

                        // Centro de acopio
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(titulo: "Centro de acopio destino",
                                          icono: "building.2.fill",
                                          color: Color(hex: "#E65100"))

                            VStack(spacing: 0) {
                                ForEach(centros) { centro in
                                    CentroSelectorRow(
                                        centro: centro,
                                        seleccionado: centroSeleccionado?.id == centro.id
                                    )
                                    .onTapGesture { centroSeleccionado = centro }

                                    if centro.id != centros.last?.id {
                                        Divider().padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        }
                        .padding(.horizontal, 20)

                        // Botón confirmar
                        if centroSeleccionado != nil {
                            Button {
                                withAnimation(.spring()) { entregaConfirmada = true }
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Confirmar entrega")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#FFA726"), Color(hex: "#E65100")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: Color(hex: "#E65100").opacity(0.35), radius: 8, y: 4)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.top, 20)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Confirmar Entrega")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// MARK: - Header Card

struct EntregaHeaderCard: View {
    let totalIngresos: Double
    let centroSeleccionado: CentroAcopio?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#E65100"), Color(hex: "#F4511E")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color(hex: "#E65100").opacity(0.3), radius: 12, y: 6)

            VStack(spacing: 8) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.8))

                Text("$\(String(format: "%.0f", totalIngresos))")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.white)

                Text(centroSeleccionado == nil
                     ? "Selecciona un centro de acopio"
                     : "Ingresos estimados en \(centroSeleccionado!.nombre)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Rows

struct KgInputRow: View {
    let tipo: TipoResiduo
    @Binding var texto: String
    let precio: Double

    private var kg: Double { Double(texto) ?? 0 }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#FFF3E0"))
                    .frame(width: 42, height: 42)
                Image(systemName: "scalemass")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "#E65100"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tipo.rawValue)
                    .font(.subheadline.bold())
                Text("$\(String(format: "%.2f", precio))/kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                TextField("0", text: $texto)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .font(.subheadline.bold())
                Text("kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }
}

struct CentroSelectorRow: View {
    let centro: CentroAcopio
    let seleccionado: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(seleccionado ? Color(hex: "#FFF3E0") : Color(.systemGray6))
                    .frame(width: 42, height: 42)
                Image(systemName: "building.2")
                    .font(.system(size: 18))
                    .foregroundStyle(seleccionado ? Color(hex: "#E65100") : Color(.systemGray3))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(centro.nombre)
                    .font(.subheadline.bold())
                    .foregroundStyle(seleccionado ? Color(hex: "#E65100") : .primary)
                Text(centro.direccion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if seleccionado {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(hex: "#E65100"))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3), value: seleccionado)
    }
}

// MARK: - Confirmación

struct ConfirmacionEntregaView: View {
    let ingresos: Double
    let centro: String
    @State private var escala: CGFloat = 0.5
    @State private var opacidad: Double = 0
    @State private var particulas = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill([Color(hex: "#FFA726"), Color(hex: "#E65100"), Color(hex: "#FF7043")][i % 3])
                        .frame(width: 10, height: 10)
                        .offset(
                            x: particulas ? cos(Double(i) * .pi / 4) * 100 : 0,
                            y: particulas ? sin(Double(i) * .pi / 4) * 100 : 0
                        )
                        .opacity(particulas ? 0 : 1)
                }

                Circle()
                    .fill(Color(hex: "#FFF3E0"))
                    .frame(width: 160, height: 160)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color(hex: "#E65100"))
            }
            .scaleEffect(escala)
            .opacity(opacidad)

            VStack(spacing: 8) {
                Text("¡Entrega registrada!")
                    .font(.title.bold())
                Text("$\(String(format: "%.0f", ingresos))")
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(Color(hex: "#E65100"))
                Text("MXN del viaje")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .opacity(opacidad)

            VStack(spacing: 8) {
                Label(centro, systemImage: "building.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("Trazabilidad registrada en el sistema", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#4CAF50"))
            }
            .opacity(opacidad)

            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                escala = 1.0
                opacidad = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                particulas = true
            }
        }
    }
}

#Preview {
    EntregaView()
}
