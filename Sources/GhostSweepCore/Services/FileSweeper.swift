import Foundation
import Darwin

public struct SweepResult: Sendable {
    public let itemsDeleted: Int
    public let bytesReclaimed: Int64
    public let errors: [String]

    public init(itemsDeleted: Int, bytesReclaimed: Int64, errors: [String] = []) {
        self.itemsDeleted = itemsDeleted
        self.bytesReclaimed = bytesReclaimed
        self.errors = errors
    }

    public var formattedReclaimedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytesReclaimed)
    }
}

public final class FileSweeper: @unchecked Sendable {
    public init() {}

    public func scan(
        targetURL: URL,
        enabledCategories: Set<PresetCategory>,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async -> [ScannedItem] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var results: [ScannedItem] = []
                self.scanDirectory(
                    at: targetURL,
                    enabledCategories: enabledCategories,
                    results: &results,
                    onProgress: onProgress
                )
                continuation.resume(returning: results)
            }
        }
    }

    private func scanDirectory(
        at url: URL,
        enabledCategories: Set<PresetCategory>,
        results: inout [ScannedItem],
        onProgress: (@Sendable (String) -> Void)?
    ) {
        guard let dir = opendir(url.path) else { return }
        defer { closedir(dir) }

        while let entry = readdir(dir) {
            let filename = withUnsafePointer(to: &entry.pointee.d_name) { ptr in
                String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
            }

            if filename == "." || filename == ".." {
                continue
            }

            let itemURL = url.appendingPathComponent(filename)
            let isDir: Bool
            if entry.pointee.d_type == DT_DIR {
                isDir = true
            } else if entry.pointee.d_type == DT_UNKNOWN {
                var statBuf = stat()
                if lstat(itemURL.path, &statBuf) == 0 {
                    isDir = (statBuf.st_mode & S_IFMT) == S_IFDIR
                } else {
                    isDir = false
                }
            } else {
                isDir = false
            }

            // Check if matches a junk preset (immunization files are guaranteed ignored)
            if let matchedCategory = PresetRuleMatcher.match(
                filename: filename,
                url: itemURL,
                isDirectory: isDir,
                enabledCategories: enabledCategories
            ) {
                let size = self.calculateSize(of: itemURL, isDirectory: isDir)
                let item = ScannedItem(
                    url: itemURL,
                    filename: filename,
                    category: matchedCategory,
                    sizeBytes: size,
                    isDirectory: isDir,
                    isSelected: true
                )
                results.append(item)
                onProgress?(filename)
                continue
            }

            if isDir {
                scanDirectory(
                    at: itemURL,
                    enabledCategories: enabledCategories,
                    results: &results,
                    onProgress: onProgress
                )
            }
        }
    }

    public func executeSweep(
        items: [ScannedItem]
    ) async -> SweepResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let fileManager = FileManager.default
                var deletedCount = 0
                var reclaimedBytes: Int64 = 0
                var errors: [String] = []

                for item in items where item.isSelected {
                    do {
                        if fileManager.fileExists(atPath: item.url.path) {
                            try fileManager.removeItem(at: item.url)
                            deletedCount += 1
                            reclaimedBytes += item.sizeBytes
                        } else {
                            if unlink(item.url.path) == 0 || rmdir(item.url.path) == 0 {
                                deletedCount += 1
                                reclaimedBytes += item.sizeBytes
                            }
                        }
                    } catch {
                        if unlink(item.url.path) == 0 || rmdir(item.url.path) == 0 {
                            deletedCount += 1
                            reclaimedBytes += item.sizeBytes
                        } else {
                            if item.filename == ".Spotlight-V100" {
                                errors.append(".Spotlight-V100 is protected by macOS. Grant Full Disk Access to GhostSweep in System Settings to allow deletion.")
                            } else {
                                errors.append("Failed to delete \(item.filename): \(error.localizedDescription)")
                            }
                        }
                    }
                }

                let result = SweepResult(
                    itemsDeleted: deletedCount,
                    bytesReclaimed: reclaimedBytes,
                    errors: errors
                )
                continuation.resume(returning: result)
            }
        }
    }

    private func calculateSize(of url: URL, isDirectory: Bool) -> Int64 {
        var statBuf = stat()
        if !isDirectory {
            if lstat(url.path, &statBuf) == 0 {
                return Int64(statBuf.st_size)
            }
            return 0
        }

        guard let dir = opendir(url.path) else { return 0 }
        defer { closedir(dir) }

        var totalSize: Int64 = 0
        while let entry = readdir(dir) {
            let name = withUnsafePointer(to: &entry.pointee.d_name) { ptr in
                String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
            }
            if name == "." || name == ".." {
                continue
            }
            let subURL = url.appendingPathComponent(name)
            let isSubDir = entry.pointee.d_type == DT_DIR
            totalSize += calculateSize(of: subURL, isDirectory: isSubDir)
        }
        return totalSize
    }
}
