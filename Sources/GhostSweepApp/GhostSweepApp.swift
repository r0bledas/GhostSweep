import SwiftUI
import AppKit
import GhostSweepCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static weak var shared: AppDelegate?
    weak var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.regular)
    }

    func registerMainWindow(_ window: NSWindow) {
        self.mainWindow = window
        window.delegate = self
        NSApp.setActivationPolicy(.regular)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    func showMainWindow(fallback: (() -> Void)? = nil) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            fallback?()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }
}

struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onWindow(window)
            }
        }
    }
}

@main
struct GhostSweepApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = AppViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("GhostSweep", id: "main") {
            MainWindowView(viewModel: viewModel)
                .background(WindowAccessor { window in
                    appDelegate.registerMainWindow(window)
                })
        }
        .windowResizability(.contentMinSize)

        MenuBarExtra("GhostSweep", systemImage: "sparkles") {
            MenuBarExtraView(viewModel: viewModel) {
                appDelegate.showMainWindow {
                    openWindow(id: "main")
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
