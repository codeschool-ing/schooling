---
title: How a plugin call works
version: 1
---

**A Capacitor plugin is an npm package with three implementations of one TypeScript interface**: one
in Java or Kotlin for Android, one in Swift for iOS, and one in JavaScript for the web. Your code
imports the interface and calls it; Capacitor picks the implementation for the platform the app is
running on. This lesson adds five official plugins to the planner, each for one thing a phone gives
an app and a page does not have, or has only partly.

| plugin | what the planner does with it |
|---|---|
| `@capacitor/preferences` | keeps the plan, so a reload no longer loses it |
| `@capacitor/filesystem` | writes the plan to a file |
| `@capacitor/local-notifications` | reminds you on the morning of a session |
| `@capacitor/geolocation` | says where you are studying |
| `@capacitor/camera` | takes a photo of your notes |

They install like any package, each pinned at the version this course used, and `npx cap sync`
puts their native halves into both projects:

```
ana@dev:~/planner$ npm install -E @capacitor/preferences@8.0.1 @capacitor/filesystem@8.1.5 @capacitor/local-notifications@8.3.1 @capacitor/geolocation@8.2.4 @capacitor/camera@8.2.6

added 6 packages, and audited 126 packages in 813ms

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npx cap sync
✔ Copying web assets from dist to android/app/src/main/assets/public in 7.32ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 2.87ms
✔ copy android in 24.23ms
✔ Updating Android plugins in 2.04ms
[info] Found 5 Capacitor plugins for android:
       @capacitor/camera@8.2.6
       @capacitor/filesystem@8.1.5
       @capacitor/geolocation@8.2.4
       @capacitor/local-notifications@8.3.1
       @capacitor/preferences@8.0.1
✔ update android in 46.23ms
✔ Copying web assets from dist to ios/App/App/public in 6.59ms
✔ Creating capacitor.config.json in ios/App/App in 370.51μs
✔ copy ios in 23.03ms
✔ Updating iOS plugins in 1.71ms
[info] All Capacitor plugins have a Package.swift file and will be included in Package.swift
[info] Writing Package.swift
[info] Found 5 Capacitor plugins for ios:
       @capacitor/camera@8.2.6
       @capacitor/filesystem@8.1.5
       @capacitor/geolocation@8.2.4
       @capacitor/local-notifications@8.3.1
       @capacitor/preferences@8.0.1
✔ update ios in 20.40ms
✔ copy web in 5.40ms
✔ update web in 6.02ms
[info] Sync finished in 0.162s
```

That last part is `cap update` at work: **the five plugins are now in the Android and iOS projects**,
listed in `capacitor.plugins.json` and in the Gradle and Swift package files that sync owns. Nothing
else needs doing for the native side to find them.

## Asking first

A phone asks the person before an app may use the camera, the location or notifications, and so does
a browser. Every plugin that needs it has the same two calls, `checkPermissions()` and
`requestPermissions()`, and its answer is one of three words: **`granted`**, **`denied`**, or
**`prompt`**, which means nobody has been asked yet. Some plugins ask on their own the first time they
are called, as the geolocation one does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l04-permission\" aria-label=\"What happens the first time the planner asks for the location. The call goes to the plugin, which checks the permission. If it was never asked, the system shows its dialog with the sentence from Info.plist or the system's own text on Android. A yes is remembered and the position comes back; a no is remembered too, and later calls fail at once without asking again, until the person changes it in the system settings.\"><defs><marker id=\"l04-permission-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"88.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">your code calls</text><text x=\"95.0\" y=\"101.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">getCurrentPosition()</text><rect x=\"200\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"88.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the plugin checks</text><text x=\"275.0\" y=\"101.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the permission</text><rect x=\"380\" y=\"70\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"88.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">never asked:</text><text x=\"450.0\" y=\"101.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the system asks</text><rect x=\"550\" y=\"20\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"38.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">granted: the position</text><text x=\"625.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">comes back</text><rect x=\"550\" y=\"120\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"138.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">denied: the call fails,</text><text x=\"625.0\" y=\"151.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">and fails again later</text><path d=\"M170 95 L200 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-permission-ah-paper-dim)\"></path><path d=\"M350 95 L380 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-permission-ah-paper-dim)\"></path><path d=\"M520 85 L550 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-permission-ah-paper-dim)\"></path><path d=\"M520 105 L550 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-permission-ah-paper-dim)\"></path><text x=\"625\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">only the system's settings undo a no</text></svg>", "caption": "The dialog is the system's, shown once. What your app controls is when it asks, and what it does with a no."}
```

**The dialog is the system's, and it is shown once.** After a no, a later request fails at once
without asking again, on Android after the second no and on iOS after the first. So the question to
design is when the app asks, which should be at the moment the person can see why, and what it does
with a refusal, which should be to keep working without that feature.

## The web implementation, and what it is not

On the web, each plugin calls the browser's own interface: `localStorage`, the Notifications API,
`navigator.geolocation`, a file picker. That is why the rest of this lesson runs in Chromium with
`look.mjs`, and every transcript is a real run. **It is also where this lesson stops being evidence of
what a phone does.** The web Filesystem keeps its files in the browser's IndexedDB, not in a folder; a
web notification needs the tab to be open; a web camera is a file picker. The permission rules,
storage limits and background behaviour on a phone are the system's, and lesson 6 is about the
distance between the two.
