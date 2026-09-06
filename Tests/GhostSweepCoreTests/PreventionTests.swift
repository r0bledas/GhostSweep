import XCTest
@testable import GhostSweepCore

final class PreventionTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let dir = tempDirectory {
            _ = try? await DriveImmunizer.shared.removeImmunization(volumeURL: dir)
            try? FileManager.default.removeItem(at: dir)
        }
        try await super.tearDown()
    }

    func testDriveImmunization() async throws {
        let immunizer = DriveImmunizer.shared

        // Initially not immunized
        let initialStatus = immunizer.checkStatus(volumeURL: tempDirectory)
        XCTAssertFalse(initialStatus.isFullyImmunized)

        // Immunize
        let status = try await immunizer.immunize(volumeURL: tempDirectory)
        XCTAssertTrue(status.hasSpotlightShield, "Should have .metadata_never_index")
        XCTAssertTrue(status.hasFSEventsShield, "Should have .fseventsd/no_log")
        XCTAssertTrue(status.hasTrashShield, "Should have neutralized .Trashes")

        // Verify files on disk
        let fm = FileManager.default
        XCTAssertTrue(fm.fileExists(atPath: tempDirectory.appendingPathComponent(".metadata_never_index").path))
        XCTAssertTrue(fm.fileExists(atPath: tempDirectory.appendingPathComponent(".fseventsd/no_log").path))
        XCTAssertTrue(fm.fileExists(atPath: tempDirectory.appendingPathComponent(".Trashes").path))

        // Remove immunization
        let removedStatus = try await immunizer.removeImmunization(volumeURL: tempDirectory)
        XCTAssertFalse(removedStatus.hasSpotlightShield)
        XCTAssertFalse(removedStatus.hasFSEventsShield)
        XCTAssertFalse(removedStatus.hasTrashShield)
    }

    func testSystemShieldStatus() {
        let shield = SystemShield()
        let status = shield.getStatus()
        XCTAssertTrue(status.usbStoresDisabled)
        XCTAssertTrue(status.networkStoresDisabled)
    }

    func testLiveShieldWatcher() async throws {
        let expectation = expectation(description: "Residue intercepted by LiveShield")
        let watcher = LiveShieldWatcher.shared

        watcher.onResidueIntercepted = { filename, path in
            if filename == ".DS_Store" {
                expectation.fulfill()
            }
        }

        watcher.startLiveShield(for: [tempDirectory.path])

        // Create a junk .DS_Store file in the watched directory
        let junkFile = tempDirectory.appendingPathComponent(".DS_Store")
        FileManager.default.createFile(atPath: junkFile.path, contents: "junk".data(using: .utf8), attributes: nil)

        await fulfillment(of: [expectation], timeout: 2.0)
        watcher.stopLiveShield()
    }
}
