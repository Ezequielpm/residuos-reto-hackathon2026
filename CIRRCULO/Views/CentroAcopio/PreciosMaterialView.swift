import SwiftUI

struct PreciosMaterialView: View {
    @State private var centro = MockDataService.shared.centrosAcopio[0]
    @State private var preciosEditados: [TipoResiduo: String] = [:]
    @State private var modoEdicion = false

    var body: some View {
        NavigationStack {
            List {
                Section("Precios actuales (MXN/kg)") {
                    ForEach(Array(centro.preciosMaterial.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { tipo in
                        HStack {
                            Text(tipo.rawValue)
                                .font(.subheadline)
                            Spacer()
                            if modoEdicion {
                                HStack {
                                    Text("$")
                                    TextField("0.00", text: Binding(
                                        get: {
                                            preciosEditados[tipo] ?? String(format: "%.2f", centro.preciosMaterial[tipo] ?? 0)
                                        },
                                        set: { preciosEditados[tipo] = $0 }
                                    ))
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 70)
                                }
                                .foregroundStyle(Color(hex: "#BF360C"))
                            } else {
                                Text("$\(String(format: "%.2f", centro.preciosMaterial[tipo] ?? 0))")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color(hex: "#BF360C"))
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Última actualización")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(Date(), style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Precios de Materiales")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(modoEdicion ? "Guardar" : "Editar") {
                        if modoEdicion {
                            // Aplicar cambios
                            for (tipo, valorStr) in preciosEditados {
                                if let valor = Double(valorStr) {
                                    centro.preciosMaterial[tipo] = valor
                                }
                            }
                            preciosEditados = [:]
                        }
                        modoEdicion.toggle()
                    }
                    .bold(modoEdicion)
                }
            }
        }
    }
}

#Preview {
    PreciosMaterialView()
}
