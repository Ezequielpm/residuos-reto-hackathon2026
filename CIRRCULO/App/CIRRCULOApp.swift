import SwiftUI

@main
struct CIRRCULOApp: App {
    @State private var mostrarLaunch = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ProfileSelectorView()
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
        }
    }
}
