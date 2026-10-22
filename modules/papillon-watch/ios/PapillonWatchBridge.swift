import Foundation
import WatchConnectivity

/// The iPhone half of the link to the watch app.
///
/// JavaScript hands over a JSON string, which goes out as the session's
/// application context. The system keeps only the newest context and delivers
/// it whenever the watch app next runs, so the watch always opens on the latest
/// timetable and nothing piles up while it is out of reach.
final class PapillonWatchBridge: NSObject, WCSessionDelegate {
  static let shared = PapillonWatchBridge()

  // Everything that touches `pending` runs on this queue.
  private let queue = DispatchQueue(label: "xyz.getpapillon.watch-bridge")
  private var pending: Data?

  private var session: WCSession? {
    WCSession.isSupported() ? WCSession.default : nil
  }

  func activate() {
    guard let session = session else {
      return
    }
    session.delegate = self
    if session.activationState != .activated {
      session.activate()
    }
  }

  /// What JavaScript can know about the watch right now.
  func status() -> [String: Bool] {
    guard let session = session else {
      return ["supported": false, "paired": false, "installed": false, "activated": false]
    }
    return [
      "supported": true,
      "paired": session.isPaired,
      "installed": session.isWatchAppInstalled,
      "activated": session.activationState == .activated,
    ]
  }

  /// Hands `json` to the watch. Returns true when it was passed to the system.
  /// When the session is not ready (still activating, no watch paired, watch
  /// app not installed yet) the payload is kept and sent as soon as it is, so
  /// a `false` here never needs a retry from the caller.
  func send(_ json: String) -> Bool {
    guard let data = json.data(using: .utf8) else {
      return false
    }
    return queue.sync { () -> Bool in
      pending = data
      return flush()
    }
  }

  // Must be called on `queue`.
  private func flush() -> Bool {
    guard
      let session = session,
      session.activationState == .activated,
      session.isPaired,
      session.isWatchAppInstalled,
      let data = pending
    else {
      return false
    }

    do {
      try session.updateApplicationContext(["payload": data])
      pending = nil
      return true
    } catch {
      return false
    }
  }

  // MARK: - WCSessionDelegate

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    queue.async { _ = self.flush() }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    // The user switched to another watch: activate again to follow it.
    session.activate()
  }

  func sessionWatchStateDidChange(_ session: WCSession) {
    // Paired, or the watch app just got installed: send what was waiting.
    queue.async { _ = self.flush() }
  }
}
