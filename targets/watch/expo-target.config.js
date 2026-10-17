/** @type {import('@bacons/apple-targets/app.plugin').Config} */
module.exports = {
  type: "watch",
  name: "PapillonWatch",
  displayName: "Papillon",
  // Apple wants the watch app's bundle id to start with the iPhone app's.
  bundleIdentifier: ".watchkitapp",
  // iOS 17 pairs with watchOS 10, so that is the oldest version to support.
  deploymentTarget: "10.0",
  icon: "../../assets/images/icon.png",
  colors: {
    // Papillon green, the same as the splash screen.
    $accent: "#29947A",
  },
};
