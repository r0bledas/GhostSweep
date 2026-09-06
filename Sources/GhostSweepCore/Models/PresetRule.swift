import Foundation

public enum PresetCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case appleDebris = "appleDebris"
    case crossPlatform = "crossPlatform"
    case developer = "developer"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .appleDebris:
            return "Apple System Debris"
        case .crossPlatform:
            return "Cross-Platform Junk"
        case .developer:
            return "Developer Artifacts"
        }
    }

    public var subtitle: String {
        switch self {
        case .appleDebris:
            return ".DS_Store, AppleDouble (._*), .Spotlight-V100, .TemporaryItems"
        case .crossPlatform:
            return "Thumbs.db, desktop.ini, $RECYCLE.BIN, .directory"
        case .developer:
            return "node_modules, .git, .cache, .build, target, __pycache__"
        }
    }

    public var systemImage: String {
        switch self {
        case .appleDebris:
            return "apple.logo"
        case .crossPlatform:
            return "laptopcomputer.and.arrow.down"
        case .developer:
            return "curlybraces"
        }
    }

    public var defaultEnabled: Bool {
        switch self {
        case .appleDebris, .crossPlatform:
            return true
        case .developer:
            return false
        }
    }
}

public struct PresetRuleMatcher: Sendable {
    public static func match(
        filename: String,
        url: URL,
        isDirectory: Bool,
        enabledCategories: Set<PresetCategory>
    ) -> PresetCategory? {
        // --- 1. IMMUNIZATION PROTECTION GUARDS ---
        // Never treat immunization markers or shields as junk!
        if filename == ".metadata_never_index" || filename == "no_log" {
            return nil
        }

        // If .Trashes is a file (not a directory), it is the immunization lock!
        if filename == ".Trashes" && !isDirectory {
            return nil
        }

        // If .fseventsd contains no_log, it is an immunized directory!
        if filename == ".fseventsd" && isDirectory {
            let noLogPath = url.appendingPathComponent("no_log").path
            if FileManager.default.fileExists(atPath: noLogPath) {
                return nil
            }
        }

        // --- 2. APPLE DEBRIS ---
        if enabledCategories.contains(.appleDebris) {
            if filename == ".DS_Store" ||
               (filename == ".Trashes" && isDirectory) ||
               filename == ".Spotlight-V100" ||
               (filename == ".fseventsd" && isDirectory) ||
               filename == ".TemporaryItems" ||
               filename.hasPrefix("._") {
                return .appleDebris
            }
        }

        // --- 3. CROSS-PLATFORM JUNK ---
        if enabledCategories.contains(.crossPlatform) {
            let lower = filename.lowercased()
            if lower == "thumbs.db" ||
               lower == "desktop.ini" ||
               lower == "$recycle.bin" ||
               lower == ".directory" ||
               lower == "ehthumbs.db" ||
               lower == "ehthumbs_vista.db" {
                return .crossPlatform
            }
        }

        // --- 4. DEVELOPER ARTIFACTS ---
        if enabledCategories.contains(.developer) {
            let lower = filename.lowercased()
            if isDirectory {
                if lower == "node_modules" ||
                   lower == ".build" ||
                   lower == "target" ||
                   lower == ".cache" ||
                   lower == "__pycache__" ||
                   lower == ".pytest_cache" ||
                   lower == ".git" {
                    return .developer
                }
            }
        }

        return nil
    }
}
