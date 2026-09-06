import Foundation
import AppKit
import Darwin

public struct PermissionManager: Sendable {
    public static var hasFullDiskAccess: Bool {
        let testPath = ("~/Library/Safari/Bookmarks.plist" as NSString).expandingTildeInPath
        let fd = Darwin.open(testPath, O_RDONLY)
        if fd >= 0 {
            Darwin.close(fd)
            return true
        }
        let tccPath = "/Library/Application Support/com.apple.TCC/TCC.db"
        let tccFd = Darwin.open(tccPath, O_RDONLY)
        if tccFd >= 0 {
            Darwin.close(tccFd)
            return true
        }
        return false
    }

    public static func openSettings() {
        // Reveal GhostSweep.app in Finder so user can drag it directly into Full Disk Access list
        let appBundleURL = Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([appBundleURL])

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
