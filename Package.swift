// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GhostSweep",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GhostSweepCore",
            targets: ["GhostSweepCore"]
        ),
        .executable(
            name: "ghostsweep",
            targets: ["GhostSweepCLI"]
        ),
        .executable(
            name: "GhostSweepApp",
            targets: ["GhostSweepApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GhostSweepCore",
            dependencies: [],
            path: "Sources/GhostSweepCore"
        ),
        .executableTarget(
            name: "GhostSweepCLI",
            dependencies: ["GhostSweepCore"],
            path: "Sources/GhostSweepCLI"
        ),
        .executableTarget(
            name: "GhostSweepApp",
            dependencies: ["GhostSweepCore"],
            path: "Sources/GhostSweepApp"
        ),
        .testTarget(
            name: "GhostSweepCoreTests",
            dependencies: ["GhostSweepCore"],
            path: "Tests/GhostSweepCoreTests"
        )
    ]
)
