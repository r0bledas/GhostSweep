import SwiftUI
import AppKit
import GhostSweepCore

@main
struct GhostSweepApp: App {
    @StateObject private var viewModel = AppViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("GhostSweep", id: "main") {
            MainWindowView(viewModel: viewModel)
        }
        .windowResizability(.contentMinSize)

        MenuBarExtra("GhostSweep", systemImage: "sparkles") {
            MenuBarExtraView(viewModel: viewModel) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
