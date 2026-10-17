import Combine
import Foundation
import WatchConnectivity

/// Keeps the timetable and homework the iPhone last sent.
///
/// The phone pushes them as a WatchConnectivity "application context", which
/// the system holds until the watch app runs, so a launch right after the
/// phone synced still finds fresh data. A copy is also written to disk, so the
/// lists stay readable when the phone is out of reach.
final class WatchStore: NSObject, ObservableObject {
    static let shared = WatchStore()

    /// The last payload received from the iPhone, `nil` before the first sync.
    @Published private(set) var payload: WatchPayload? = nil

    /// True while a debug build shows `SampleData` in place of a real sync.
    @Published private(set) var isDemo = false

    private let fileURL: URL

    private override init() {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("payload.json")

        super.init()

        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(WatchPayload.self, from: data) {
            payload = saved
        }

        #if DEBUG
        if payload == nil {
            payload = SampleData.payload()
            isDemo = true
        }
        #endif

        activateSession()
    }

    /// The line shown under the lists: when the data came from, or that it is
    /// a demo.
    var syncLabel: String? {
        if isDemo {
            return Strings.demo
        }
        return payload.map { Strings.updated($0.sentDate) }
    }

    private func activateSession() {
        guard WCSession.isSupported() else {
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func apply(_ data: Data) {
        guard let decoded = try? JSONDecoder().decode(WatchPayload.self, from: data) else {
            return
        }
        try? data.write(to: fileURL, options: .atomic)

        DispatchQueue.main.async { [weak self] in
            self?.isDemo = false
            self?.payload = decoded
        }
    }
}

extension WatchStore: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else {
            return
        }
        // The phone may have sent something while this app was not running.
        if let data = session.receivedApplicationContext["payload"] as? Data {
            apply(data)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["payload"] as? Data {
            apply(data)
        }
    }
}
