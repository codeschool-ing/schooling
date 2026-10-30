---
title: Updates over the air
version: 1
---

**An Expo app can download a new JavaScript bundle and use it the next time it opens**, without a new
version in the store. This works because most of an app is JavaScript and assets, which the app loads at
start, and the native part only has to be the same. **`expo-updates`** is the library that does it: on
launch it asks an update server whether a newer bundle exists for this app, downloads it, and runs it on
the next start.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l09-updates\" aria-label=\"How an update over the air reaches an installed app. The store build contains the native code and bundle 1, with runtime version 1.0.0. The update server holds bundle 2, also for runtime 1.0.0, and bundle 3, built for runtime 1.1.0. On launch the app asks the server, downloads bundle 2 and runs it on the next launch. Bundle 3 is not taken, because its runtime version is different: it needs native code the installed app does not have, and reaches people only with a new store build.\"><defs><marker id=\"l09-updates-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-updates-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-updates-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the store build:</text><text x=\"120.0\" y=\"104.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">native code + bundle 1</text><text x=\"120\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">runtime 1.0.0</text><rect x=\"440\" y=\"20\" width=\"260\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"570\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the update server</text><rect x=\"470\" y=\"52\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bundle 2</text><text x=\"570.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">runtime 1.0.0</text><rect x=\"470\" y=\"136\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"152.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bundle 3</text><text x=\"570.0\" y=\"165.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">runtime 1.1.0</text><path d=\"M220 88 L470 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-updates-ah-paper-dim)\"></path><text x=\"330\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">on launch: anything new for 1.0.0?</text><path d=\"M470 82 L222 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-updates-ah-phosphor)\"></path><text x=\"330\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">taken, runs on the next launch</text><path d=\"M470 159 L222 118\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l09-updates-ah-amber)\"></path><text x=\"330\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">not taken: needs native code it lacks</text></svg>", "caption": "An update changes the JavaScript and the assets. The runtime version is the promise that the native code underneath is the same."}
```

Install it, and pin it:

```
ana@dev:~/planner-native$ npx expo install expo-updates > /dev/null
Dependency validation is unreliable in offline-mode
ana@dev:~/planner-native$ npm install -E expo-updates@58.0.18 > /dev/null
ana@dev:~/planner-native$ grep expo-updates package.json
    "expo-updates": "58.0.18",
```

## What an update is

There is nothing mysterious in it. **An update is what `npx expo export` writes for a platform**: the
bundle, compiled to Hermes bytecode, and the assets it uses. Export the planner for Android:

```
ana@dev:~/planner-native$ npx expo export --platform android > /dev/null
ana@dev:~/planner-native$ ls dist dist/_expo/static/js/android
dist:
_expo
assets
metadata.json

dist/_expo/static/js/android:
entry-e597ee604262eb10534a99c0f050340d.hbc
ana@dev:~/planner-native$ file dist/_expo/static/js/android/*.hbc
dist/_expo/static/js/android/entry-e597ee604262eb10534a99c0f050340d.hbc: Hermes JavaScript bytecode, version 99
ana@dev:~/planner-native$ node -p "const m = require('./dist/metadata.json').fileMetadata.android; m.assets.length + ' assets, and ' + m.bundle"
26 assets, and _expo/static/js/android/entry-e597ee604262eb10534a99c0f050340d.hbc
```

**One file of Hermes bytecode and the images it uses**, named by their content, and a `metadata.json`
listing them, which is what an update server serves and the app downloads. On Expo's own service,
`eas update` runs this export and uploads the result; a team can also run its own server that speaks the
same protocol. *`eas update` was not run for this course, for the same reason as EAS Build.*

## The runtime version

**An update is only safe for an app whose native code it was built against.** A bundle that calls a
native module the installed app does not have stops the app the moment it reaches that call. So every
build and every update carries a **runtime version**, and the app only takes an update whose runtime
version is the same as its own. The simplest policy ties it to the app's version:

```
ana@dev:~/planner-native$ grep -E "\"version\"|runtimeVersion" app.json
    "version": "1.0.0",
    "runtimeVersion": { "policy": "appVersion" },
```

With `"policy": "appVersion"`, every update built while `version` is `1.0.0` reaches only builds of
`1.0.0`. **Change native code and you must change the version**, and ship a store build; JavaScript-only
changes go out as updates to the version already installed. Expo also has a `fingerprint` policy, which
computes the runtime version from the native code itself, so forgetting to raise it is no longer
possible.

Commit the lesson:

```
ana@dev:~/planner-native$ git add . && git commit -q -m "An identity, generated native projects and updates" && git log --oneline -1
fc85f21 An identity, generated native projects and updates
```
