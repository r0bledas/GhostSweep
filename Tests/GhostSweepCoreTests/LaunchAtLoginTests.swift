import XCTest
@testable import GhostSweepCore

final class LaunchAtLoginTests: XCTestCase {
    func testLaunchAtLoginAvailability() {
        let manager = LaunchAtLoginManager.shared
        XCTAssertTrue(manager.isAvailable)
        // Check reading status doesn't crash
        _ = manager.isEnabled
    }

    func testNotificationManagerSingleton() {
        let manager = NotificationManager.shared
        XCTAssertNotNil(manager)
    }
}
