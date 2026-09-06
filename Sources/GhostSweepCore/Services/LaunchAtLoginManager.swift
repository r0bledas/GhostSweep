import Foundation
import ServiceManagement

public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()

    private init() {}

    public var isAvailable: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }

    public var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            }
            return false
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        if SMAppService.mainApp.status != .enabled {
                            try SMAppService.mainApp.register()
                        }
                    } else {
                        if SMAppService.mainApp.status == .enabled {
                            try SMAppService.mainApp.unregister()
                        }
                    }
                } catch {
                    print("[LaunchAtLoginManager] Error setting launch at login (\(newValue)): \(error.localizedDescription)")
                }
            }
        }
    }

    public func toggle() throws {
        isEnabled = !isEnabled
    }
}
