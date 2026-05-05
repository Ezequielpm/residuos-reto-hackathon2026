import SwiftUI

struct EquipoView: View {
    @State private var empleados = MockDataService.shared.empleados
    @State private var mostrandoAgregar = false
    @State private var nuevoNombre = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        StatItem(valor: "\(empleados.count)", label: "empleados")
                        Divider().frame(height: 36)
                        StatItem(valor: "\(empleados.reduce(0) { $0 + $1.escaneosMes })", label: "escaneos mes")
                        Divider().frame(height: 36)
                        StatItem(valor: "\(String(format: "%.0f", empleados.reduce(0) { $0 + $1.kgRegistradosMes })) kg", label: "registrados")
                    }
                    .padding(.vertical, 8)
                }

                Section("Miembros del equipo") {
                    ForEach(empleados) { empleado in
                        EmpleadoRow(empleado: empleado)
                    }
                }
            }
            .navigationTitle("Equipo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrandoAgregar = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $mostrandoAgregar) {
                AgregarEmpleadoSheet(nombre: $nuevoNombre) {
                    if !nuevoNombre.trimmingCharacters(in: .whitespaces).isEmpty {
                        empleados.append(Empleado(
                            id: UUID(),
                            nombre: nuevoNombre,
                            escaneosMes: 0,
                            kgRegistradosMes: 0
                        ))
                        nuevoNombre = ""
                    }
                    mostrandoAgregar = false
                }
            }
        }
    }
}

struct EmpleadoRow: View {
    let empleado: Empleado

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#E3F2FD"))
                    .frame(width: 44, height: 44)
                Text(String(empleado.nombre.prefix(1)))
                    .font(.headline)
                    .foregroundStyle(Color(hex: "#1565C0"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(empleado.nombre)
                    .font(.subheadline.bold())
                Text("\(empleado.escaneosMes) escaneos · \(String(format: "%.1f", empleado.kgRegistradosMes)) kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

struct AgregarEmpleadoSheet: View {
    @Binding var nombre: String
    let onAgregar: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos del empleado") {
                    TextField("Nombre completo", text: $nombre)
                }
            }
            .navigationTitle("Agregar empleado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { onAgregar() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Agregar") { onAgregar() }
                        .bold()
                        .disabled(nombre.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    EquipoView()
}
