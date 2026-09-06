import Foundation
import SwiftUI
import GhostSweepCore

@MainActor
public final class AppViewModel: ObservableObject {
    @Published public var mountedVolumes: [VolumeInfo] = []
    @Published public var selectedVolume: VolumeInfo?
    @Published public var customFolderURL: URL?
    
    @Published public var scannedItems: [ScannedItem] = []
    @Published public var isScanning: Bool = false
    @Published public var isSweeping: Bool = false
    @Published public var currentStatus: String = "Ready"
    @Published public var lastResult: SweepResult?
    @Published public var showResultSheet: Bool = false
    
    // Prevention & Shield Status
    @Published public var immunizationStatus: ImmunizationStatus?
    @Published public var systemShieldStatus: SystemShieldStatus?
    @Published public var hasFullDiskAccess: Bool = PermissionManager.hasFullDiskAccess
    @Published public var launchAtLoginEnabled: Bool = false

    // Preset Toggles
    @AppStorage("enableAppleDebris") public var enableAppleDebris: Bool = true
    @AppStorage("enableCrossPlatform") public var enableCrossPlatform: Bool = true
    @AppStorage("enableDeveloper") public var enableDeveloper: Bool = false
    @AppStorage("showNotificationsEnabled") public var showNotificationsEnabled: Bool = true {
        didSet {
            if showNotificationsEnabled {
                NotificationManager.shared.requestAuthorization()
            }
        }
    }
    @AppStorage("autoCleanOnFinderEject") public var autoCleanOnFinderEject: Bool = false {
        didSet {
            UnmountWatcher.shared.isEnabled = autoCleanOnFinderEject
        }
    }
    @AppStorage("liveShieldEnabled") public var liveShieldEnabled: Bool = true {
        didSet {
            updateLiveShield()
        }
    }

    private let volumeManager = VolumeManager()
    private let fileSweeper = FileSweeper()
    private let diskEjector = DiskEjector()
    private let driveImmunizer = DriveImmunizer.shared
    private let systemShield = SystemShield()

    public init() {
        self.launchAtLoginEnabled = LaunchAtLoginManager.shared.isEnabled
        if showNotificationsEnabled {
            NotificationManager.shared.requestAuthorization()
        }

        UnmountWatcher.shared.isEnabled = autoCleanOnFinderEject
        UnmountWatcher.shared.onAutoCleanCompleted = { [weak self] name, result in
            Task { @MainActor in
                self?.lastResult = result
                self?.currentStatus = "Auto-cleaned '\(name)': \(result.itemsDeleted) items swept"
                if self?.showNotificationsEnabled == true && result.itemsDeleted > 0 {
                    NotificationManager.shared.sendNotification(
                        title: "GhostSweep Auto-Clean",
                        body: "Swept \(result.itemsDeleted) item(s) from '\(name)' (\(result.formattedReclaimedSize) reclaimed)."
                    )
                }
            }
        }

        LiveShieldWatcher.shared.onResidueIntercepted = { [weak self] filename, path in
            Task { @MainActor in
                self?.currentStatus = "Active Shield: Intercepted \(filename) in real-time"
                if self?.showNotificationsEnabled == true {
                    NotificationManager.shared.sendNotification(
                        title: "Active Sentry Intercepted",
                        body: "Vaporized '\(filename)' before macOS could persist it."
                    )
                }
            }
        }

        refreshVolumes()
        refreshSystemShieldStatus()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshVolumes()
            }
        }
    }

    public func toggleLaunchAtLogin() {
        LaunchAtLoginManager.shared.isEnabled.toggle()
        self.launchAtLoginEnabled = LaunchAtLoginManager.shared.isEnabled
    }

    public var activeCategories: Set<PresetCategory> {
        var set: Set<PresetCategory> = []
        if enableAppleDebris { set.insert(.appleDebris) }
        if enableCrossPlatform { set.insert(.crossPlatform) }
        if enableDeveloper { set.insert(.developer) }
        return set
    }

    public var currentTargetURL: URL? {
        if let custom = customFolderURL {
            return custom
        }
        return selectedVolume?.url
    }

    public var selectedItemsCount: Int {
        scannedItems.filter { $0.isSelected }.count
    }

    public var selectedItemsSize: Int64 {
        scannedItems.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }

    public var formattedSelectedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: selectedItemsSize)
    }

    public func refreshVolumes() {
        self.hasFullDiskAccess = PermissionManager.hasFullDiskAccess
        self.mountedVolumes = volumeManager.getMountedVolumes()
        if selectedVolume == nil, let first = mountedVolumes.first {
            selectVolume(first)
        } else if let sel = selectedVolume {
            checkImmunizationStatus(for: sel.url)
        }
        updateLiveShield()
    }

    public func openFullDiskAccessSettings() {
        PermissionManager.openSettings()
    }

    public func selectVolume(_ volume: VolumeInfo) {
        self.selectedVolume = volume
        self.customFolderURL = nil
        self.scannedItems = []
        self.lastResult = nil
        self.currentStatus = "Selected \(volume.name)"
        checkImmunizationStatus(for: volume.url)
        startScan()
    }

    public func selectCustomFolder(_ url: URL) {
        guard volumeManager.isSafeTarget(url: url) else {
            self.currentStatus = "Cannot select internal system directory"
            return
        }
        self.customFolderURL = url
        self.selectedVolume = nil
        self.scannedItems = []
        self.lastResult = nil
        self.currentStatus = "Selected folder '\(url.lastPathComponent)'"
        checkImmunizationStatus(for: url)
        startScan()
    }

    public func checkImmunizationStatus(for url: URL) {
        self.immunizationStatus = driveImmunizer.checkStatus(volumeURL: url)
    }

    public func refreshSystemShieldStatus() {
        self.systemShieldStatus = systemShield.getStatus()
    }

    public func applySystemShieldSettings() {
        systemShield.applySystemShields(disableUSB: true, disableNetwork: true)
        refreshSystemShieldStatus()
        currentStatus = "System Shield Applied: macOS will not write .DS_Store to USB drives"
    }

    public func toggleImmunization() {
        guard let url = currentTargetURL else { return }
        Task {
            do {
                if let status = immunizationStatus, status.hasSpotlightShield || status.hasTrashShield {
                    // Already immunized, remove it
                    self.immunizationStatus = try await driveImmunizer.removeImmunization(volumeURL: url)
                    self.currentStatus = "Shield markers removed from \(url.lastPathComponent)"
                } else {
                    // Immunize
                    self.immunizationStatus = try await driveImmunizer.immunize(volumeURL: url)
                    self.currentStatus = "\(url.lastPathComponent) is now immunized against hidden residue"
                }
            } catch {
                self.currentStatus = "Immunize error: \(error.localizedDescription)"
            }
        }
    }

    public func updateLiveShield() {
        if liveShieldEnabled {
            let paths = mountedVolumes.map { $0.mountPoint }
            LiveShieldWatcher.shared.startLiveShield(for: paths)
        } else {
            LiveShieldWatcher.shared.stopLiveShield()
        }
    }

    public func startScan() {
        guard let target = currentTargetURL else { return }
        isScanning = true
        currentStatus = "Scanning \(target.lastPathComponent)..."

        Task {
            let items = await fileSweeper.scan(
                targetURL: target,
                enabledCategories: activeCategories,
                onProgress: { [weak self] item in
                    Task { @MainActor in
                        self?.currentStatus = "Inspecting \(item)..."
                    }
                }
            )

            self.scannedItems = items
            self.isScanning = false
            self.currentStatus = items.isEmpty ? "Clean! No residue files found." : "Found \(items.count) item(s)"
            self.checkImmunizationStatus(for: target)
        }
    }

    public func toggleItemSelection(id: UUID) {
        if let idx = scannedItems.firstIndex(where: { $0.id == id }) {
            scannedItems[idx].isSelected.toggle()
        }
    }

    public func toggleCategory(category: PresetCategory, isSelected: Bool) {
        for i in 0..<scannedItems.count {
            if scannedItems[i].category == category {
                scannedItems[i].isSelected = isSelected
            }
        }
    }

    public func selectAll(_ select: Bool) {
        for i in 0..<scannedItems.count {
            scannedItems[i].isSelected = select
        }
    }

    public func executeSweep() {
        isSweeping = true
        currentStatus = "Sweeping selected items..."

        Task {
            let result = await fileSweeper.executeSweep(
                items: scannedItems
            )

            self.lastResult = result
            self.isSweeping = false
            self.showResultSheet = true
            self.currentStatus = "Swept \(result.itemsDeleted) items (\(result.formattedReclaimedSize))"
            self.startScan()
        }
    }

    public func ejectCurrentVolume() {
        guard let vol = selectedVolume else { return }
        Task {
            do {
                try await diskEjector.eject(volumeURL: vol.url)
                self.refreshVolumes()
                self.currentStatus = "\(vol.name) ejected safely."
            } catch {
                self.currentStatus = "Eject error: \(error.localizedDescription)"
            }
        }
    }

    public func cleanAllVolumes() async -> (totalDeleted: Int, totalReclaimed: Int64) {
        guard !isSweeping else { return (0, 0) }
        isSweeping = true
        currentStatus = "Sweeping all mounted drives..."

        var totalDeleted = 0
        var totalReclaimed: Int64 = 0

        for volume in mountedVolumes {
            let items = await fileSweeper.scan(
                targetURL: volume.url,
                enabledCategories: activeCategories
            )
            let result = await fileSweeper.executeSweep(items: items)
            totalDeleted += result.itemsDeleted
            totalReclaimed += result.bytesReclaimed
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let formattedSize = formatter.string(fromByteCount: totalReclaimed)

        self.isSweeping = false
        self.currentStatus = "Cleaned all drives: \(totalDeleted) items swept (\(formattedSize))"

        if showNotificationsEnabled && totalDeleted > 0 {
            NotificationManager.shared.sendNotification(
                title: "GhostSweep Clean All",
                body: "Swept \(totalDeleted) item(s) across all drives (\(formattedSize) reclaimed)."
            )
        }

        refreshVolumes()
        return (totalDeleted, totalReclaimed)
    }

    public func executeCleanAll() {
        Task {
            _ = await cleanAllVolumes()
        }
    }
}
