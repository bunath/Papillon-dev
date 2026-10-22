import { requireOptionalNativeModule } from "expo";

export interface WatchStatus {
  /** The device can talk to a watch at all (an iPhone, not an iPad). */
  supported: boolean;
  /** An Apple Watch is paired with this iPhone. */
  paired: boolean;
  /** The Papillon watch app is installed on that watch. */
  installed: boolean;
  /** The WatchConnectivity session is up. */
  activated: boolean;
}

interface PapillonWatchNativeModule {
  isSupported: boolean;
  getStatus: () => Promise<WatchStatus>;
  send: (json: string) => Promise<boolean>;
}

// Absent on Android and on any build made before the module was added, so every
// entry point below has to cope with it being null.
const NativeModule =
  requireOptionalNativeModule<PapillonWatchNativeModule>("PapillonWatch");

/** Whether this device can have a watch at all. */
export const watchIsSupported = NativeModule?.isSupported ?? false;

export async function getWatchStatus(): Promise<WatchStatus> {
  return (
    (await NativeModule?.getStatus()) ?? {
      supported: false,
      paired: false,
      installed: false,
      activated: false,
    }
  );
}

/**
 * Hands a JSON string to the watch app. Resolves `true` when it was passed to
 * the system. `false` means it is queued natively until the watch is ready,
 * or that there is no watch to send to.
 */
export async function sendToWatch(json: string): Promise<boolean> {
  return (await NativeModule?.send(json)) ?? false;
}
