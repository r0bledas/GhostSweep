import XCTest
@testable import GhostSweepCore

final class VolumeManagerTests: XCTestCase {
    func testProtectedPathsAreRejected() {
        let manager = VolumeManager()

        XCTAssertFalse(manager.isSafeTarget(url: URL(fileURLWithPath: "/")))
        XCTAssertFalse(manager.isSafeTarget(url: URL(fileURLWithPath: "/System")))
        XCTAssertFalse(manager.isSafeTarget(url: URL(fileURLWithPath: "/System/Volumes/Data")))
        XCTAssertFalse(manager.isSafeTarget(url: URL(fileURLWithPath: "/usr/bin")))
        XCTAssertFalse(manager.isSafeTarget(url: URL(fileURLWithPath: "/bin")))
        XCTAssertFalse(manager.isSafeTarget(url: URL(fileURLWithPath: "/var")))
        XCTAssertFalse(manager.isSafeTarget(url: URL(fileURLWithPath: "/etc")))
    }

    func testExternalAndCustomPathsAreAllowed() {
        let manager = VolumeManager()
        let tempDir = FileManager.default.temporaryDirectory
        XCTAssertTrue(manager.isSafeTarget(url: tempDir))

        let usbURL = URL(fileURLWithPath: "/Volumes/SANDISK_USB")
        XCTAssertTrue(manager.isSafeTarget(url: usbURL))
    }
}
