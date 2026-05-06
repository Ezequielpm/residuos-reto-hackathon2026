import SwiftUI
import SwiftData

@main
struct NexiaApp: App {
    @State private var mostrarLaunch = true
    @State private var auth = AuthManager.shared
    @StateObject private var store = AppDataStore()

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .opacity(mostrarLaunch ? 0 : 1)

                if mostrarLaunch {
                    LaunchView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            mostrarLaunch = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .environment(auth)
            .environmentObject(store)
        }
        .modelContainer(for: Usuario.self)
    }
}

// MARK: - Root View (decide Login vs App)

struct RootView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if auth.estaAutenticado {
                ProfileSelectorView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            auth.configurar(modelContext: modelContext)
        }
    }
}
