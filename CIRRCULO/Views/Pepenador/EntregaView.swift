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

    private var totalIngresos: Double {
        kgIngresados.reduce(0.0) { acc, entry in
            guard let kg = Double(entry.value), let centro = centroSeleccionado else { return acc }
            return acc + kg * (centro.preciosMaterial[entry.key] ?? entry.key.valorMercado)
        }
    }

    var body: some View {
        NavigationStack {
            if entregaConfirmada {
                ConfirmacionEntregaView(
                    ingresos: totalIngresos,
                    centro: centroSeleccionado?.nombre ?? "Centro de acopio"
                )
            } else {
                Form {
                    Section("Material recogido") {
                        ForEach(Array(kgIngresados.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { tipo in
                            HStack {
                                Text(tipo.rawValue)
                                    .font(.subheadline)
                                Spacer()
                                TextField("kg", text: Binding(
                                    get: { kgIngresados[tipo] ?? "0" },
                                    set: { kgIngresados[tipo] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                                Text("kg")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("Centro de acopio destino") {
                        ForEach(centros) { centro in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(centro.nombre)
                                        .font(.subheadline.bold())
                                    Text(centro.direccion)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if centroSeleccionado?.id == centro.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(hex: "#F9A825"))
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { centroSeleccionado = centro }
                        }
                    }

                    if centroSeleccionado != nil {
                        Section("Ingresos estimados") {
                            HStack {
                                Text("Total del viaje")
                                    .font(.headline)
                                Spacer()
                                Text("$\(String(format: "%.0f", totalIngresos)) MXN")
                                    .font(.title3.bold())
                                    .foregroundStyle(Color(hex: "#F9A825"))
                            }
                        }

                        Section {
                            Button {
                                withAnimation { entregaConfirmada = true }
                            } label: {
                                Text("Confirmar entrega")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundStyle(.white)
                            }
                            .listRowBackground(Color(hex: "#F9A825"))
                        }
                    }
                }
                .navigationTitle("Confirmar Entrega")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct ConfirmacionEntregaView: View {
    let ingresos: Double
    let centro: String

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color(hex: "#F9A825"))

            Text("¡Entrega registrada!")
                .font(.title.bold())

            VStack(spacing: 8) {
                Text("$\(String(format: "%.0f", ingresos))")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color(hex: "#F9A825"))
                Text("MXN del viaje")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Label(centro, systemImage: "shippingbox.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Trazabilidad registrada en el sistema")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    EntregaView()
}
