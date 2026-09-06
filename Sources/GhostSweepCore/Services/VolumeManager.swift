import Foundation

public struct VolumeManager: Sendable {
    public init() {}

    private static let protectedPaths: Set<String> = [
        "/",
        "/System",
        "/System/Volumes/Data",
        "/System/Volumes/Preboot",
        "/System/Volumes/Recovery",
        "/System/Volumes/VM",
        "/System/Volumes/Update",
        "/bin",
        "/sbin",
        "/usr",
        "/var",
        "/private/var",
        "/etc",
        "/private/etc",
        "/Library",
        "/Applications"
    ]

    public func isSafeTarget(url: URL) -> Bool {
        let path = (try? url.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath) ?? url.standardized.path
        
        // Root filesystem is always rejected
        if path == "/" {
            return false
        }

        // Allow any valid external drive in /Volumes/ (except Macintosh HD)
        if path.hasPrefix("/Volumes/") {
            let volumeName = url.lastPathComponent
            if volumeName.localizedCaseInsensitiveContains("Macintosh HD") {
                return false
            }
            return true
        }

        // Allow user home directories and user temporary folders
        if path.hasPrefix("/Users/") ||
           path.hasPrefix("/var/folders/") ||
           path.hasPrefix("/private/var/folders/") ||
           path.hasPrefix("/tmp/") ||
           path.hasPrefix("/private/tmp/") {
            return true
        }

        // Exact protected path match
        if Self.protectedPaths.contains(path) {
            return false
        }

        // Direct child or prefix of root system areas
        if path.hasPrefix("/System/") ||
           path.hasPrefix("/usr/") ||
           path.hasPrefix("/bin/") ||
           path.hasPrefix("/sbin/") ||
           path.hasPrefix("/Library/") ||
           path.hasPrefix("/private/var/") ||
           path.hasPrefix("/var/") {
            return false
        }

        return true
    }

    public func getMountedVolumes() -> [VolumeInfo] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            .volumeIsInternalKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeLocalizedFormatDescriptionKey
        ]

        guard let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else {
            return []
        }

        var results: [VolumeInfo] = []

        for url in urls {
            let path = url.path
            // Skip root filesystem directly
            if path == "/" || path.hasPrefix("/System/Volumes") {
                continue
            }

            guard let values = try? url.resourceValues(forKeys: Set(keys)) else {
                continue
            }

            let name = values.volumeName ?? url.lastPathComponent
            let isRemovable = values.volumeIsRemovable ?? false
            let isEjectable = values.volumeIsEjectable ?? false
            let isInternal = values.volumeIsInternal ?? true
            let format = values.volumeLocalizedFormatDescription ?? "Volume"
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let available = Int64(values.volumeAvailableCapacity ?? 0)

            let safe = isSafeTarget(url: url)

            // Only include external/ejectable/removable drives or explicitly mounted items in /Volumes
            if isRemovable || isEjectable || !isInternal || path.hasPrefix("/Volumes/") {
                // Ensure we don't include Macintosh HD even if symlinked under /Volumes
                if name.localizedCaseInsensitiveContains("Macintosh HD") && isInternal {
                    continue
                }

                results.append(VolumeInfo(
                    id: path,
                    name: name,
                    url: url,
                    mountPoint: path,
                    fileSystemType: format,
                    totalBytes: total,
                    availableBytes: available,
                    isRemovable: isRemovable,
                    isEjectable: isEjectable,
                    isInternal: isInternal,
                    isSafeToClean: safe,
                    isCustomFolder: false
                ))
            }
        }

        return results
    }
}
