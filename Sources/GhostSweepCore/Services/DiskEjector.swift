import Foundation

public struct DiskEjector: Sendable {
    public init() {}

    public func eject(volumeURL: URL) async throws {
        let path = volumeURL.path
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
                process.arguments = ["eject", path]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    if process.terminationStatus == 0 {
                        continuation.resume()
                    } else {
                        // If eject failed (some drives only support unmount), try unmount
                        let unmountProcess = Process()
                        unmountProcess.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
                        unmountProcess.arguments = ["unmount", path]
                        try unmountProcess.run()
                        unmountProcess.waitUntilExit()

                        if unmountProcess.terminationStatus == 0 {
                            continuation.resume()
                        } else {
                            let data = pipe.fileHandleForReading.readDataToEndOfFile()
                            let errOutput = String(data: data, encoding: .utf8) ?? "Unknown diskutil error"
                            continuation.resume(throwing: NSError(
                                domain: "DiskEjector",
                                code: Int(process.terminationStatus),
                                userInfo: [NSLocalizedDescriptionKey: errOutput]
                            ))
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
