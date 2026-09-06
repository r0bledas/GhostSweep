import Foundation
import CoreServices
import Darwin

public final class LiveShieldWatcher: @unchecked Sendable {
    public static let shared = LiveShieldWatcher()

    private var eventStream: FSEventStreamRef?
    private var watchedPaths: [String] = []
    private let volumeManager = VolumeManager()

    public var isWatching: Bool {
        eventStream != nil
    }

    public var onResidueIntercepted: ((String, String) -> Void)?

    private init() {}

    public func startLiveShield(for paths: [String]) {
        stopLiveShield()

        let safePaths = paths.filter {
            volumeManager.isSafeTarget(url: URL(fileURLWithPath: $0))
        }

        guard !safePaths.isEmpty else { return }
        self.watchedPaths = safePaths

        let cfPaths = safePaths as CFArray
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            guard let clientInfo = clientCallBackInfo else { return }
            let watcher = Unmanaged<LiveShieldWatcher>.fromOpaque(clientInfo).takeUnretainedValue()

            let pathsPointer = eventPaths.assumingMemoryBound(to: UnsafePointer<CChar>.self)
            for i in 0..<numEvents {
                let path = String(cString: pathsPointer[i])
                watcher.inspectAndVaporize(at: path)
            }
        }

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            cfPaths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.05, // 50ms latency for near-instant vaporizing
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        ) else {
            return
        }

        self.eventStream = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
    }

    public func stopLiveShield() {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
            watchedPaths = []
        }
    }

    private func inspectAndVaporize(at path: String) {
        let url = URL(fileURLWithPath: path)
        let filename = url.lastPathComponent

        // Check if file is residue
        let isResidue = filename == ".DS_Store" ||
                        filename.hasPrefix("._") ||
                        filename.lowercased() == "thumbs.db" ||
                        filename.lowercased() == "desktop.ini"

        if isResidue {
            if unlink(url.path) == 0 {
                onResidueIntercepted?(filename, path)
            } else {
                try? FileManager.default.removeItem(at: url)
                onResidueIntercepted?(filename, path)
            }
        }
    }
}
