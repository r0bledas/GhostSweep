import XCTest
@testable import GhostSweepCore

final class RulePresetsTests: XCTestCase {
    let dummyURL = URL(fileURLWithPath: "/tmp/dummy")

    func testAppleDebrisMatching() {
        let categories: Set<PresetCategory> = [.appleDebris]

        XCTAssertEqual(PresetRuleMatcher.match(filename: ".DS_Store", url: dummyURL, isDirectory: false, enabledCategories: categories), .appleDebris)
        XCTAssertEqual(PresetRuleMatcher.match(filename: "._my_photo.jpg", url: dummyURL, isDirectory: false, enabledCategories: categories), .appleDebris)
        XCTAssertEqual(PresetRuleMatcher.match(filename: ".Trashes", url: dummyURL, isDirectory: true, enabledCategories: categories), .appleDebris)
        XCTAssertEqual(PresetRuleMatcher.match(filename: ".Spotlight-V100", url: dummyURL, isDirectory: true, enabledCategories: categories), .appleDebris)
        XCTAssertEqual(PresetRuleMatcher.match(filename: ".TemporaryItems", url: dummyURL, isDirectory: true, enabledCategories: categories), .appleDebris)

        // Normal files should not match
        XCTAssertNil(PresetRuleMatcher.match(filename: "my_photo.jpg", url: dummyURL, isDirectory: false, enabledCategories: categories))
        XCTAssertNil(PresetRuleMatcher.match(filename: "notes.txt", url: dummyURL, isDirectory: false, enabledCategories: categories))
    }

    func testImmunizationProtectionGuards() {
        let categories: Set<PresetCategory> = [.appleDebris, .crossPlatform, .developer]

        // 1. .metadata_never_index must NEVER match
        XCTAssertNil(PresetRuleMatcher.match(filename: ".metadata_never_index", url: dummyURL, isDirectory: false, enabledCategories: categories))

        // 2. .Trashes as a file (the shield) must NEVER match
        XCTAssertNil(PresetRuleMatcher.match(filename: ".Trashes", url: dummyURL, isDirectory: false, enabledCategories: categories))

        // 3. no_log must NEVER match
        XCTAssertNil(PresetRuleMatcher.match(filename: "no_log", url: dummyURL, isDirectory: false, enabledCategories: categories))
    }

    func testCrossPlatformMatching() {
        let categories: Set<PresetCategory> = [.crossPlatform]

        XCTAssertEqual(PresetRuleMatcher.match(filename: "Thumbs.db", url: dummyURL, isDirectory: false, enabledCategories: categories), .crossPlatform)
        XCTAssertEqual(PresetRuleMatcher.match(filename: "thumbs.db", url: dummyURL, isDirectory: false, enabledCategories: categories), .crossPlatform)
        XCTAssertEqual(PresetRuleMatcher.match(filename: "desktop.ini", url: dummyURL, isDirectory: false, enabledCategories: categories), .crossPlatform)
        XCTAssertEqual(PresetRuleMatcher.match(filename: "$RECYCLE.BIN", url: dummyURL, isDirectory: true, enabledCategories: categories), .crossPlatform)

        XCTAssertNil(PresetRuleMatcher.match(filename: "Thumbs.png", url: dummyURL, isDirectory: false, enabledCategories: categories))
    }

    func testDeveloperArtifactsMatching() {
        let categories: Set<PresetCategory> = [.developer]

        XCTAssertEqual(PresetRuleMatcher.match(filename: "node_modules", url: dummyURL, isDirectory: true, enabledCategories: categories), .developer)
        XCTAssertEqual(PresetRuleMatcher.match(filename: ".git", url: dummyURL, isDirectory: true, enabledCategories: categories), .developer)
        XCTAssertEqual(PresetRuleMatcher.match(filename: "__pycache__", url: dummyURL, isDirectory: true, enabledCategories: categories), .developer)
        XCTAssertEqual(PresetRuleMatcher.match(filename: ".build", url: dummyURL, isDirectory: true, enabledCategories: categories), .developer)

        XCTAssertNil(PresetRuleMatcher.match(filename: "node_modules", url: dummyURL, isDirectory: false, enabledCategories: categories))
    }
}
