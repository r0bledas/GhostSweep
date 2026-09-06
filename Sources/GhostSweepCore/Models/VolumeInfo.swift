import Foundation

public struct VolumeInfo: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let url: URL
    public let mountPoint: String
    public let fileSystemType: String
    public let totalBytes: Int64
    public let availableBytes: Int64
    public let isRemovable: Bool
    public let isEjectable: Bool
    public let isInternal: Bool
    public let isSafeToClean: Bool
    public let isCustomFolder: Bool

    public init(
        id: String,
        name: String,
        url: URL,
        mountPoint: String,
        fileSystemType: String = "Unknown",
        totalBytes: Int64 = 0,
        availableBytes: Int64 = 0,
        isRemovable: Bool = true,
        isEjectable: Bool = true,
        isInternal: Bool = false,
        isSafeToClean: Bool = true,
        isCustomFolder: Bool = false
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.mountPoint = mountPoint
        self.fileSystemType = fileSystemType
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.isRemovable = isRemovable
        self.isEjectable = isEjectable
        self.isInternal = isInternal
        self.isSafeToClean = isSafeToClean
        self.isCustomFolder = isCustomFolder
    }

    public var usedBytes: Int64 {
        max(0, totalBytes - availableBytes)
    }

    public var usagePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    public var formattedCapacity: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: usedBytes)) used of \(formatter.string(fromByteCount: totalBytes))"
    }

    public var formattedAvailableCapacity: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: availableBytes)
    }

    public var formattedTotalCapacity: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
}
