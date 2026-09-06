import Foundation
import GhostSweepCore

@main
struct GhostSweepCLI {
    static func main() async {
        let args = CommandLine.arguments

        if args.count < 2 || args.contains("-h") || args.contains("--help") || args.contains("help") {
            printHelp()
            return
        }

        let command = args[1]

        switch command {
        case "list":
            await handleList()
        case "scan":
            await handleScan(args: Array(args.dropFirst(2)))
        case "clean":
            await handleClean(args: Array(args.dropFirst(2)))
        case "immunize":
            await handleImmunize(args: Array(args.dropFirst(2)))
        case "watch":
            await handleWatch(args: Array(args.dropFirst(2)))
        case "shield":
            await handleShield(args: Array(args.dropFirst(2)))
        default:
            print("❌ Unknown command: \(command)")
            printHelp()
        }
    }

    static func printHelp() {
        print("""
        👻 GhostSweep CLI — Clean & Prevent residue hidden files on external drives
        
        USAGE:
          ghostsweep <command> [options]

        COMMANDS:
          list                     List connected external & removable drives
          scan <path>              Preview hidden junk files found at path
          clean <path> [options]   Remove residue files from target drive or folder
          immunize <path>          Place hardware prevention markers (.metadata_never_index, no_log, .Trashes lock)
          watch <path>             Run active real-time sentry to vaporize .DS_Store & ._* instantly
          shield [--apply]         Check or apply system-wide USB .DS_Store prevention

        CLEAN OPTIONS:
          --all                    Include developer artifacts (node_modules, .git, etc.)
          --yes, -y                Skip confirmation prompt and execute immediately

        EXAMPLES:
          ghostsweep list
          ghostsweep scan /Volumes/USB_DRIVE
          ghostsweep clean /Volumes/USB_DRIVE --yes
          ghostsweep immunize /Volumes/USB_DRIVE
          ghostsweep watch /Volumes/USB_DRIVE
          ghostsweep shield --apply
        """)
    }

    static func handleList() async {
        let manager = VolumeManager()
        let volumes = manager.getMountedVolumes()

        if volumes.isEmpty {
            print("ℹ️ No removable or external drives currently mounted.")
            return
        }

        print("📦 Detected External & Removable Drives:")
        print("------------------------------------------------------------")
        for v in volumes {
            let status = v.isSafeToClean ? "✅ Safe" : "⚠️ Protected"
            print("• \(v.name) (\(v.fileSystemType)) [\(status)]")
            print("  Mount: \(v.mountPoint)")
            if v.totalBytes > 0 {
                print("  Space: \(v.formattedCapacity)")
            }
            print("")
        }
    }

    static func handleScan(args: [String]) async {
        guard let path = args.first(where: { !$0.hasPrefix("-") }) else {
            print("❌ Error: Missing path to scan. Usage: ghostsweep scan <path>")
            return
        }

        let targetURL = URL(fileURLWithPath: path).standardized
        let manager = VolumeManager()

        guard manager.isSafeTarget(url: targetURL) else {
            print("❌ Safety Refusal: '\(targetURL.path)' is an internal macOS system location.")
            return
        }

        var categories: Set<PresetCategory> = [.appleDebris, .crossPlatform]
        if args.contains("--all") {
            categories.insert(.developer)
        }

        print("🔍 Scanning '\(targetURL.path)' for residue files...")
        let sweeper = FileSweeper()
        let items = await sweeper.scan(targetURL: targetURL, enabledCategories: categories)

        if items.isEmpty {
            print("✨ Clean! No ghost or residue files found.")
            return
        }

        print("\nFound \(items.count) item(s):")
        print("------------------------------------------------------------")

        var totalSize: Int64 = 0
        let grouped = Dictionary(grouping: items, by: { $0.category })

        for (cat, groupItems) in grouped {
            print("\n[\(cat.displayName)]")
            for item in groupItems.prefix(15) {
                let icon = item.isDirectory ? "📁" : "📄"
                print("  \(icon) \(item.filename) (\(item.formattedSize)) - \(item.path)")
            }
            if groupItems.count > 15 {
                print("  ... and \(groupItems.count - 15) more")
            }
            let catTotal = groupItems.reduce(0) { $0 + $1.sizeBytes }
            totalSize += catTotal
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        print("\n------------------------------------------------------------")
        print("📊 Total potential space to reclaim: \(formatter.string(fromByteCount: totalSize))")
    }

    static func handleClean(args: [String]) async {
        guard let path = args.first(where: { !$0.hasPrefix("-") }) else {
            print("❌ Error: Missing path to clean. Usage: ghostsweep clean <path> [options]")
            return
        }

        let targetURL = URL(fileURLWithPath: path).standardized
        let manager = VolumeManager()

        guard manager.isSafeTarget(url: targetURL) else {
            print("❌ Safety Refusal: '\(targetURL.path)' is an internal macOS system location.")
            return
        }

        let autoConfirm = args.contains("-y") || args.contains("--yes")

        var categories: Set<PresetCategory> = [.appleDebris, .crossPlatform]
        if args.contains("--all") {
            categories.insert(.developer)
        }

        print("🔍 Scanning '\(targetURL.path)'...")
        let sweeper = FileSweeper()
        let items = await sweeper.scan(targetURL: targetURL, enabledCategories: categories)

        if items.isEmpty {
            print("✨ Nothing to clean! Drive is already clean.")
            return
        }

        let totalSize = items.reduce(0) { $0 + $1.sizeBytes }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file

        print("Found \(items.count) item(s) occupying \(formatter.string(fromByteCount: totalSize)).")

        if !autoConfirm {
            print("Proceed with deletion? [y/N]: ", terminator: "")
            guard let response = readLine(), response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "y" else {
                print("Cancelled.")
                return
            }
        }

        print("🧹 Sweeping...")
        let result = await sweeper.executeSweep(
            items: items
        )

        print("✅ Swept \(result.itemsDeleted) item(s), reclaimed \(result.formattedReclaimedSize)!")

        if !result.errors.isEmpty {
            print("⚠️ Notices during sweep:")
            for err in result.errors {
                print("  - \(err)")
            }
        }
    }

    static func handleImmunize(args: [String]) async {
        guard let path = args.first else {
            print("❌ Error: Missing path. Usage: ghostsweep immunize <path>")
            return
        }

        let targetURL = URL(fileURLWithPath: path).standardized
        let manager = VolumeManager()
        guard manager.isSafeTarget(url: targetURL) else {
            print("❌ Safety Refusal: Cannot immunize system root or internal drives.")
            return
        }

        print("🛡️ Immunizing '\(targetURL.path)'...")
        do {
            let status = try await DriveImmunizer.shared.immunize(volumeURL: targetURL)
            print("✅ Drive immunization completed successfully!")
            print("  • Spotlight Indexing: \(status.hasSpotlightShield ? "Blocked (.metadata_never_index)" : "Failed")")
            print("  • FSEvents Logging:   \(status.hasFSEventsShield ? "Blocked (.fseventsd/no_log)" : "Failed")")
            print("  • Trash Accumulation: \(status.hasTrashShield ? "Neutralized (.Trashes locked)" : "Failed")")
            print("Macs will now avoid writing residue metadata to this drive.")
        } catch {
            print("❌ Immunization failed: \(error.localizedDescription)")
        }
    }

    static func handleWatch(args: [String]) async {
        guard let path = args.first else {
            print("❌ Error: Missing path. Usage: ghostsweep watch <path>")
            return
        }

        let targetURL = URL(fileURLWithPath: path).standardized
        let manager = VolumeManager()
        guard manager.isSafeTarget(url: targetURL) else {
            print("❌ Safety Refusal: Cannot watch system directories.")
            return
        }

        print("🛡️ Starting Active Real-Time Sentry on '\(targetURL.path)'...")
        print("Any .DS_Store, AppleDouble (._*), or Thumbs.db created will be vaporized instantly.")
        print("Press Ctrl+C to stop.")

        LiveShieldWatcher.shared.onResidueIntercepted = { filename, filePath in
            let timestamp = ISO8601DateFormatter().string(from: Date())
            print("[\(timestamp)] ⚡ Vaporized: \(filename) at \(filePath)")
        }

        LiveShieldWatcher.shared.startLiveShield(for: [targetURL.path])

        // Keep running until user terminates
        dispatchMain()
    }

    static func handleShield(args: [String]) async {
        let systemShield = SystemShield()

        if args.contains("--apply") || args.contains("-a") {
            print("🛡️ Applying macOS system-wide USB prevention settings...")
            systemShield.applySystemShields(disableUSB: true, disableNetwork: true)
            print("✅ Applied: macOS Finder will no longer write .DS_Store files to USB or Network drives.")
        } else {
            let status = systemShield.getStatus()
            print("🛡️ macOS System-Wide Shield Status:")
            print("  • DSDontWriteUSBStores:     \(status.usbStoresDisabled ? "✅ ACTIVE (Blocked)" : "❌ Disabled")")
            print("  • DSDontWriteNetworkStores: \(status.networkStoresDisabled ? "✅ ACTIVE (Blocked)" : "❌ Disabled")")
            if !status.isFullyShielded {
                print("\nRun 'ghostsweep shield --apply' to activate protection.")
            }
        }
    }
}

