import SwiftUI

struct EntregaView: View {
    @EnvironmentObject var store: AppDataStore
    @State private var kgIngresados: [TipoResiduo: String] = [:]
    @State private var centroSeleccionado: CentroAcopio?
    @State private var entregaConfirmada = false
    @State private var solicitudCargadaId: UUID?

    /// Solicitud activa de este pepenador (reclamada o en ruta)
    private var solicitudActiva: SolicitudRecoleccion? {
        let userId = store.currentUserId
        return store.solicitudes.first { sol in
            (sol.estado == .reclamada || sol.estado == .enRuta) && sol.reclamadaPor == userId
        }
    }

    private var totalIngresos: Double {
        kgIngresados.reduce(0.0) { acc, entry in
            guard let kg = Double(entry.value), let centro = centroSeleccionado else { return acc }
            return acc + kg * (centro.preciosMaterial[entry.key] ?? entry.key.valorMercado)
        }
    }

    private var materialesOrdenados: [TipoResiduo] {
        kgIngresados.keys.sorted { $0.rawValue < $1.rawValue }
    }

    private var materialesReales: [TipoResiduo: Double] {
        var result: [TipoResiduo: Double] = [:]
        for (tipo, str) in kgIngresados {
            if let kg = Double(str), kg > 0 { result[tipo] = kg }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if entregaConfirmada {
                    ConfirmacionEntregaView(
                        ingresos: totalIngresos,
                        centro: centroSeleccionado?.nombre ?? "Centro de acopio"
                    )
                } else if let solicitud = solicitudActiva {
                    contenidoConSolicitud(solicitud)
                } else {
                    estadoVacio
                }
            }
        }
    }

    // MARK: - Estado vacio

    private var estadoVacio: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "shippingbox.and.arrow.backward.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(.systemGray3))
            Text("Sin recolección activa")
                .font(.title3.bold())
            Text("Acepta una solicitud desde el mapa\no desde una alerta para comenzar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Contenido con solicitud activa

    @ViewBuilder
    private func contenidoConSolicitud(_ solicitud: SolicitudRecoleccion) -> some View {
        if solicitud.estado == .reclamada {
            // PASO 1: Ir a recoger
            pasoRecoger(solicitud)
        } else {
            // PASO 2: Entregar en centro
            pasoEntregar(solicitud)
        }
    }

    // MARK: - Paso 1: Ir a recoger

    private func pasoRecoger(_ solicitud: SolicitudRecoleccion) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                PasoHeader(
                    paso: 1,
                    titulo: "Recoger material",
                    subtitulo: solicitud.puntoAcopio.nombre,
                    color1: "#BF360C", color2: "#E65100", color3: "#F4511E"
                )

                VStack(spacing: 20) {
                    // Info del punto
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(titulo: "Punto de recolección",
                                      icono: "mappin.circle.fill",
                                      color: Color(hex: "#E65100"))

                        VStack(spacing: 12) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "#FFF3E0"))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color(hex: "#E65100"))
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(solicitud.puntoAcopio.nombre)
                                        .font(.headline)
                                    Text(solicitud.puntoAcopio.direccion)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }

                            // Materiales
                            HStack(spacing: 8) {
                                ForEach(solicitud.materialesPrincipales.prefix(3), id: \.self) { tipo in
                                    Text(tipo.rawValue)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: "#FFF3E0"))
                                        .foregroundStyle(Color(hex: "#E65100"))
                                        .clipShape(Capsule())
                                }
                                Spacer()
                            }

                            // Stats
                            HStack {
                                Label("\(String(format: "%.0f", solicitud.kgEstimados)) kg", systemImage: "scalemass.fill")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("$\(String(format: "%.0f", solicitud.valorEstimado)) MXN")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color(hex: "#E65100"))
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                    }
                    .padding(.horizontal, 20)

                    // Boton ruta
                    Link(destination: URL(string: "maps://?daddr=\(solicitud.puntoAcopio.latitud),\(solicitud.puntoAcopio.longitud)")!) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            Text("Abrir ruta al punto")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .foregroundStyle(Color(hex: "#E65100"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)

                    // Boton confirmar recogida
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            store.marcarEnRuta(solicitud.id)
                            cargarMateriales(solicitud)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Ya recogí el material")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FF8F00"), Color(hex: "#E65100")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#E65100").opacity(0.35), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .padding(.top, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
    }

    // MARK: - Paso 2: Entregar en centro

    private func pasoEntregar(_ solicitud: SolicitudRecoleccion) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                PasoHeader(
                    paso: 2,
                    titulo: "Entregar material",
                    subtitulo: centroSeleccionado != nil
                        ? "Destino: \(centroSeleccionado!.nombre)"
                        : "Selecciona un centro de acopio",
                    color1: "#1B5E20", color2: "#2E7D32", color3: "#43A047"
                )

                VStack(spacing: 20) {
                    // Material recogido (editable)
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(titulo: "Material recogido",
                                      icono: "shippingbox.fill",
                                      color: Color(hex: "#2E7D32"))

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

                    // Seleccion de centro
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(titulo: "Entregar en",
                                      icono: "building.2.fill",
                                      color: Color(hex: "#2E7D32"))

                        VStack(spacing: 0) {
                            ForEach(store.centrosAcopio) { centro in
                                let estaSeleccionado: Bool = centroSeleccionado?.id == centro.id
                                CentroSelectorRow(
                                    centro: centro,
                                    seleccionado: estaSeleccionado
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        centroSeleccionado = centro
                                    }
                                }

                                if centro.id != store.centrosAcopio.last?.id {
                                    Divider().padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)

                        // Boton como llegar al centro
                        if let centro = centroSeleccionado {
                            Link(destination: URL(string: "maps://?daddr=\(centro.latitud),\(centro.longitud)")!) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                    Text("Cómo llegar a \(centro.nombre)")
                                        .font(.subheadline.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray6))
                                .foregroundStyle(Color(hex: "#2E7D32"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Resumen de ingresos
                    if centroSeleccionado != nil {
                        VStack(spacing: 4) {
                            Text("Ingresos estimados")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.0f", totalIngresos)) MXN")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(Color(hex: "#2E7D32"))
                        }
                        .padding(.top, 4)
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Boton confirmar entrega
                    if centroSeleccionado != nil {
                        Button {
                            if let centro = centroSeleccionado {
                                store.confirmarEntrega(
                                    materiales: materialesReales,
                                    centroId: centro.id,
                                    puntoOrigenNombre: solicitud.puntoAcopio.nombre
                                )
                            }
                            withAnimation(.spring()) { entregaConfirmada = true }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Confirmar entrega")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#43A047"), Color(hex: "#2E7D32")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color(hex: "#2E7D32").opacity(0.35), radius: 10, y: 5)
                        }
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    // MARK: - Helpers

    private func cargarMateriales(_ solicitud: SolicitudRecoleccion) {
        kgIngresados = [:]
        for tipo in solicitud.materialesPrincipales {
            let kgPorTipo = solicitud.kgEstimados / Double(solicitud.materialesPrincipales.count)
            kgIngresados[tipo] = String(format: "%.1f", kgPorTipo)
        }
    }
}

// MARK: - Header de paso

struct PasoHeader: View {
    let paso: Int
    let titulo: String
    let subtitulo: String
    let color1: String
    let color2: String
    let color3: String

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: color1), Color(hex: color2), Color(hex: color3)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 130, y: -30)
            Circle().fill(.white.opacity(0.04)).frame(width: 140).offset(x: -70, y: 25)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("PASO \(paso)")
                                .font(.caption.bold())
                                .tracking(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.2))
                                .clipShape(Capsule())
                            // Indicador de pasos
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 6, height: 6)
                                Circle()
                                    .fill(.white.opacity(paso >= 2 ? 1 : 0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .foregroundStyle(.white)

                        Text(titulo)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(subtitulo)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: paso == 1 ? "truck.box.fill" : "building.2.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Rows

struct KgInputRow: View {
    let tipo: TipoResiduo
    @Binding var texto: String
    let precio: Double

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
                    .fill(seleccionado ? Color(hex: "#E8F5E9") : Color(.systemGray6))
                    .frame(width: 42, height: 42)
                Image(systemName: "building.2")
                    .font(.system(size: 18))
                    .foregroundStyle(seleccionado ? Color(hex: "#2E7D32") : Color(.systemGray3))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(centro.nombre)
                    .font(.subheadline.bold())
                    .foregroundStyle(seleccionado ? Color(hex: "#2E7D32") : .primary)
                Text(centro.direccion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if seleccionado {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(hex: "#2E7D32"))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3), value: seleccionado)
    }
}

// MARK: - Confirmacion

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
        .environmentObject(AppDataStore())
}
