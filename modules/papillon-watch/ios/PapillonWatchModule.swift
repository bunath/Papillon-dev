import ExpoModulesCore
import WatchConnectivity

public class PapillonWatchModule: Module {
  public func definition() -> ModuleDefinition {
    Name("PapillonWatch")

    Constants([
      "isSupported": WCSession.isSupported()
    ])

    // The session has to be active before the first payload can go out.
    OnCreate {
      PapillonWatchBridge.shared.activate()
    }

    AsyncFunction("getStatus") { () -> [String: Bool] in
      return PapillonWatchBridge.shared.status()
    }

    AsyncFunction("send") { (json: String) -> Bool in
      return PapillonWatchBridge.shared.send(json)
    }
  }
}
