import Foundation
import AppKit

public final class UnmountWatcher: @unchecked Sendable {
    public static let shared = UnmountWatcher()
    
    private var observer: NSObjectProtocol?
    private let volumeManager = VolumeManager()
    private let fileSweeper = FileSweeper()
    
    public var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    public var onAutoCleanCompleted: ((String, SweepResult) -> Void)?

    private init() {}

    public func startMonitoring() {
        guard observer == nil else { return }

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willUnmountNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, self.isEnabled else { return }
            guard let volumeURL = notification.userInfo?["NSWorkspaceVolumeURLKey"] as? URL else {
                return
            }

            // Verify volume safety before sweeping
            guard self.volumeManager.isSafeTarget(url: volumeURL) else {
                return
            }

            Task {
                let items = await self.fileSweeper.scan(
                    targetURL: volumeURL,
                    enabledCategories: [.appleDebris, .crossPlatform]
                )
                let result = await self.fileSweeper.executeSweep(
                    items: items
                )
                self.onAutoCleanCompleted?(volumeURL.lastPathComponent, result)
            }
        }
    }

    public func stopMonitoring() {
        if let obs = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            observer = nil
        }
    }
}
