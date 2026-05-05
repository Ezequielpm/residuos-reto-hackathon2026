import SwiftUI

struct EquipoView: View {
    @ObservedObject var vm: EmpresaViewModel
    @State private var mostrandoAgregar = false
    @State private var nuevoNombre = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        StatItem(valor: "\(vm.empleados.count)", label: "empleados")
                        Divider().frame(height: 36)
                        StatItem(valor: "\(vm.empleados.reduce(0) { $0 + $1.escaneosMes })", label: "escaneos mes")
                        Divider().frame(height: 36)
                        StatItem(valor: "\(String(format: "%.0f", vm.empleados.reduce(0.0) { $0 + $1.kgRegistradosMes })) kg",
                                 label: "registrados")
                    }
                    .padding(.vertical, 8)
                }

                Section("Miembros del equipo") {
                    ForEach(vm.empleados) { empleado in
                        EmpleadoRow(empleado: empleado)
                    }
                }
            }
            .navigationTitle("Equipo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrandoAgregar = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $mostrandoAgregar) {
                AgregarEmpleadoSheet(nombre: $nuevoNombre) {
                    let nombre = nuevoNombre.trimmingCharacters(in: .whitespaces)
                    if !nombre.isEmpty {
                        vm.empleados.append(Empleado(
                            id: UUID(), nombre: nombre,
                            escaneosMes: 0, kgRegistradosMes: 0
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
                Text(empleado.nombre).font(.subheadline.bold())
                Text("\(empleado.escaneosMes) escaneos · \(String(format: "%.1f", empleado.kgRegistradosMes)) kg")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

struct StatItem: View {
    let valor: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(valor).font(.headline.bold()).foregroundStyle(Color(hex: "#1565C0"))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
