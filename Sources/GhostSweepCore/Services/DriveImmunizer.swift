import Foundation

public struct ImmunizationStatus: Sendable {
    public let hasSpotlightShield: Bool
    public let hasFSEventsShield: Bool
    public let hasTrashShield: Bool
    public let isFullyImmunized: Bool

    public init(hasSpotlightShield: Bool, hasFSEventsShield: Bool, hasTrashShield: Bool) {
        self.hasSpotlightShield = hasSpotlightShield
        self.hasFSEventsShield = hasFSEventsShield
        self.hasTrashShield = hasTrashShield
        self.isFullyImmunized = hasSpotlightShield && hasFSEventsShield && hasTrashShield
    }
}

public final class DriveImmunizer: @unchecked Sendable {
    public static let shared = DriveImmunizer()
    private let volumeManager = VolumeManager()

    public init() {}

    public func checkStatus(volumeURL: URL) -> ImmunizationStatus {
        let fm = FileManager.default
        let spotlightMarker = volumeURL.appendingPathComponent(".metadata_never_index")
        let fsEventsNoLog = volumeURL.appendingPathComponent(".fseventsd/no_log")
        let trashMarker = volumeURL.appendingPathComponent(".Trashes")

        let hasSpotlight = fm.fileExists(atPath: spotlightMarker.path)
        let hasFSEvents = fm.fileExists(atPath: fsEventsNoLog.path)

        var hasTrash = false
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: trashMarker.path, isDirectory: &isDir) {
            // Trash is shielded if it's a file rather than a directory
            hasTrash = !isDir.boolValue
        }

        return ImmunizationStatus(
            hasSpotlightShield: hasSpotlight,
            hasFSEventsShield: hasFSEvents,
            hasTrashShield: hasTrash
        )
    }

    public func immunize(volumeURL: URL) async throws -> ImmunizationStatus {
        guard volumeManager.isSafeTarget(url: volumeURL) else {
            throw NSError(
                domain: "DriveImmunizer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Safety check failed: cannot immunize system drive."]
            )
        }

        let fm = FileManager.default

        // 1. Spotlight Prevention Marker (.metadata_never_index)
        let spotlightMarker = volumeURL.appendingPathComponent(".metadata_never_index")
        if !fm.fileExists(atPath: spotlightMarker.path) {
            fm.createFile(atPath: spotlightMarker.path, contents: Data(), attributes: nil)
        }

        // Disable local Spotlight daemon for this volume
        let mdutilProcess = Process()
        mdutilProcess.executableURL = URL(fileURLWithPath: "/usr/bin/mdutil")
        mdutilProcess.arguments = ["-d", volumeURL.path]
        mdutilProcess.standardOutput = Pipe()
        mdutilProcess.standardError = Pipe()
        try? mdutilProcess.run()
        mdutilProcess.waitUntilExit()

        let mdutilOff = Process()
        mdutilOff.executableURL = URL(fileURLWithPath: "/usr/bin/mdutil")
        mdutilOff.arguments = ["-i", "off", volumeURL.path]
        mdutilOff.standardOutput = Pipe()
        mdutilOff.standardError = Pipe()
        try? mdutilOff.run()
        mdutilOff.waitUntilExit()

        // Purge existing .Spotlight-V100 directory if present
        let spotlightDir = volumeURL.appendingPathComponent(".Spotlight-V100")
        if fm.fileExists(atPath: spotlightDir.path) {
            try? fm.removeItem(at: spotlightDir)
        }

        // 2. FSEvents Daemon Logging Prevention (.fseventsd/no_log)
        let fsEventsDir = volumeURL.appendingPathComponent(".fseventsd")
        if !fm.fileExists(atPath: fsEventsDir.path) {
            try? fm.createDirectory(at: fsEventsDir, withIntermediateDirectories: true)
        }
        let noLogFile = fsEventsDir.appendingPathComponent("no_log")
        if !fm.fileExists(atPath: noLogFile.path) {
            fm.createFile(atPath: noLogFile.path, contents: Data(), attributes: nil)
        }

        // 3. Trash Shield (.Trashes neutralized as an immutable file)
        let trashPath = volumeURL.appendingPathComponent(".Trashes")
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: trashPath.path, isDirectory: &isDir) {
            if isDir.boolValue {
                try? fm.removeItem(at: trashPath)
            }
        }
        if !fm.fileExists(atPath: trashPath.path) {
            fm.createFile(atPath: trashPath.path, contents: Data(), attributes: nil)
            // Apply immutable user changeless flag (uchg)
            let chflagsProcess = Process()
            chflagsProcess.executableURL = URL(fileURLWithPath: "/usr/bin/chflags")
            chflagsProcess.arguments = ["uchg", trashPath.path]
            chflagsProcess.standardOutput = Pipe()
            chflagsProcess.standardError = Pipe()
            try? chflagsProcess.run()
            chflagsProcess.waitUntilExit()
        }

        return checkStatus(volumeURL: volumeURL)
    }

    public func removeImmunization(volumeURL: URL) async throws -> ImmunizationStatus {
        guard volumeManager.isSafeTarget(url: volumeURL) else {
            throw NSError(
                domain: "DriveImmunizer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Safety check failed."]
            )
        }

        let fm = FileManager.default
        let spotlightMarker = volumeURL.appendingPathComponent(".metadata_never_index")
        let fsEventsDir = volumeURL.appendingPathComponent(".fseventsd")
        let trashPath = volumeURL.appendingPathComponent(".Trashes")

        try? fm.removeItem(at: spotlightMarker)
        try? fm.removeItem(at: fsEventsDir)

        // Clear uchg flag before removing .Trashes
        let chflagsProcess = Process()
        chflagsProcess.executableURL = URL(fileURLWithPath: "/usr/bin/chflags")
        chflagsProcess.arguments = ["nouchg", trashPath.path]
        chflagsProcess.standardOutput = Pipe()
        chflagsProcess.standardError = Pipe()
        try? chflagsProcess.run()
        chflagsProcess.waitUntilExit()
        try? fm.removeItem(at: trashPath)

        return checkStatus(volumeURL: volumeURL)
    }
}
