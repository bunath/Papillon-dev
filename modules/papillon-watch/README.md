# papillon-watch

Sends the timetable and homework to the Apple Watch app (`targets/watch`)
through WatchConnectivity.

- JavaScript: `sendToWatch(json)` hands a JSON string over, `getWatchStatus()`
  says whether a watch is paired and has the app installed.
- Native: the string becomes the session's application context, so the watch
  always opens on the latest one, even if it was out of reach when it was sent.
- iOS only. On Android, and on an iPad, the functions do nothing.

The payload is built in `utils/watch/payload.ts` and kept up to date by
`utils/watch/useWatchSync.ios.ts`. The Swift side that reads it is
`targets/watch/Models.swift`: change one, change the other.

This is a native module, so it needs a new build:

```bash
npx expo prebuild -p ios
```
