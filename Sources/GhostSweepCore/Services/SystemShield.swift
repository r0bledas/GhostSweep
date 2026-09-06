import Foundation

public struct SystemShieldStatus: Sendable {
    public let usbStoresDisabled: Bool
    public let networkStoresDisabled: Bool
    public var isFullyShielded: Bool {
        usbStoresDisabled && networkStoresDisabled
    }

    public init(usbStoresDisabled: Bool, networkStoresDisabled: Bool) {
        self.usbStoresDisabled = usbStoresDisabled
        self.networkStoresDisabled = networkStoresDisabled
    }
}

public struct SystemShield: Sendable {
    public init() {}

    private static let domain = "com.apple.desktopservices"
    private static let usbKey = "DSDontWriteUSBStores"
    private static let netKey = "DSDontWriteNetworkStores"

    public func getStatus() -> SystemShieldStatus {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", Self.domain]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        let usbDisabled = output.contains("\(Self.usbKey) = 1") || output.contains("\(Self.usbKey) = true")
        let netDisabled = output.contains("\(Self.netKey) = 1") || output.contains("\(Self.netKey) = true")

        return SystemShieldStatus(
            usbStoresDisabled: usbDisabled,
            networkStoresDisabled: netDisabled
        )
    }

    public func applySystemShields(disableUSB: Bool = true, disableNetwork: Bool = true) {
        if disableUSB {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
            proc.arguments = ["write", Self.domain, Self.usbKey, "-bool", "true"]
            try? proc.run()
            proc.waitUntilExit()
        }

        if disableNetwork {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
            proc.arguments = ["write", Self.domain, Self.netKey, "-bool", "true"]
            try? proc.run()
            proc.waitUntilExit()
        }
    }
}
