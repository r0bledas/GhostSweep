import Foundation

public struct ScannedItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let path: String
    public let filename: String
    public let category: PresetCategory
    public let sizeBytes: Int64
    public let isDirectory: Bool
    public var isSelected: Bool

    public init(
        id: UUID = UUID(),
        url: URL,
        filename: String,
        category: PresetCategory,
        sizeBytes: Int64,
        isDirectory: Bool,
        isSelected: Bool = true
    ) {
        self.id = id
        self.url = url
        self.path = url.path
        self.filename = filename
        self.category = category
        self.sizeBytes = sizeBytes
        self.isDirectory = isDirectory
        self.isSelected = isSelected
    }

    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useAll]
        return formatter.string(fromByteCount: sizeBytes)
    }
}
