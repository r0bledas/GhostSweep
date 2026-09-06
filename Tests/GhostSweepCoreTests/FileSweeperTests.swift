import XCTest
@testable import GhostSweepCore

final class FileSweeperTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testScanAndSweep() async throws {
        let fm = FileManager.default

        // Create legitimate files
        let docFile = tempDirectory.appendingPathComponent("document.pdf")
        fm.createFile(atPath: docFile.path, contents: "Hello World".data(using: .utf8))

        // Create junk files
        let dsStore = tempDirectory.appendingPathComponent(".DS_Store")
        fm.createFile(atPath: dsStore.path, contents: "junk".data(using: .utf8))

        let appleDouble = tempDirectory.appendingPathComponent("._document.pdf")
        fm.createFile(atPath: appleDouble.path, contents: "junk".data(using: .utf8))

        let thumbsDb = tempDirectory.appendingPathComponent("Thumbs.db")
        fm.createFile(atPath: thumbsDb.path, contents: "junk".data(using: .utf8))

        // Create junk trash directory
        let trashDir = tempDirectory.appendingPathComponent(".Trashes")
        try fm.createDirectory(at: trashDir, withIntermediateDirectories: true)

        let sweeper = FileSweeper()
        let items = await sweeper.scan(
            targetURL: tempDirectory,
            enabledCategories: [.appleDebris, .crossPlatform]
        )

        XCTAssertEqual(items.count, 4, "Should find 4 residue items")
        XCTAssertTrue(items.contains(where: { $0.filename == ".DS_Store" }))
        XCTAssertTrue(items.contains(where: { $0.filename == "._document.pdf" }))
        XCTAssertTrue(items.contains(where: { $0.filename == "Thumbs.db" }))
        XCTAssertTrue(items.contains(where: { $0.filename == ".Trashes" }))

        // Execute sweep
        let result = await sweeper.executeSweep(items: items)
        XCTAssertEqual(result.itemsDeleted, 4)

        // Legitimate file must still exist
        XCTAssertTrue(fm.fileExists(atPath: docFile.path))

        // Junk files must be gone
        XCTAssertFalse(fm.fileExists(atPath: dsStore.path))
        XCTAssertFalse(fm.fileExists(atPath: appleDouble.path))
        XCTAssertFalse(fm.fileExists(atPath: thumbsDb.path))
        XCTAssertFalse(fm.fileExists(atPath: trashDir.path))
    }

    func testImmunizationFilesAreNeverSwept() async throws {
        let fm = FileManager.default

        // 1. Create .metadata_never_index
        let spotlightMarker = tempDirectory.appendingPathComponent(".metadata_never_index")
        fm.createFile(atPath: spotlightMarker.path, contents: Data())

        // 2. Create .Trashes as an immunization file (not directory)
        let trashShield = tempDirectory.appendingPathComponent(".Trashes")
        fm.createFile(atPath: trashShield.path, contents: Data())

        // 3. Create .fseventsd/no_log
        let fsEventsDir = tempDirectory.appendingPathComponent(".fseventsd")
        try fm.createDirectory(at: fsEventsDir, withIntermediateDirectories: true)
        let noLog = fsEventsDir.appendingPathComponent("no_log")
        fm.createFile(atPath: noLog.path, contents: Data())

        // Also create real junk to ensure it can be found
        let dsStore = tempDirectory.appendingPathComponent(".DS_Store")
        fm.createFile(atPath: dsStore.path, contents: "junk".data(using: .utf8))

        let sweeper = FileSweeper()
        let items = await sweeper.scan(
            targetURL: tempDirectory,
            enabledCategories: [.appleDebris, .crossPlatform, .developer]
        )

        // ONLY .DS_Store should be found! The 3 immunization files must be ignored!
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.filename, ".DS_Store")

        // Execute sweep
        let result = await sweeper.executeSweep(items: items)
        XCTAssertEqual(result.itemsDeleted, 1)

        // Immunization files MUST still exist untouched!
        XCTAssertTrue(fm.fileExists(atPath: spotlightMarker.path), ".metadata_never_index must not be deleted")
        XCTAssertTrue(fm.fileExists(atPath: trashShield.path), ".Trashes shield must not be deleted")
        XCTAssertTrue(fm.fileExists(atPath: noLog.path), ".fseventsd/no_log must not be deleted")

        // Only junk is removed
        XCTAssertFalse(fm.fileExists(atPath: dsStore.path))
    }
}
