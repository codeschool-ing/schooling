---
title: The runtime version, and the fingerprint
version: 1
---

**Every build has a runtime version, and an update is published for one.** A phone downloads only updates
whose runtime version is its own, so a bundle that needs a native library reaches only the builds that
contain it. The question is how to choose the runtime version so that it changes exactly when the native side
does:

- **`appVersion`** uses `version` from `app.json`. Simple, and it relies on people raising the version
  whenever a native change happens, which is the kind of thing people forget.
- **`fingerprint`** computes a hash of everything native: the libraries with native code and their versions,
  `app.json`'s native settings, local modules such as lesson 17's, the generated folders' inputs. It changes
  when the native side changes, and only then.

The planner uses the fingerprint. In `app.json`, inside `"expo"`, add:

```json
"runtimeVersion": { "policy": "fingerprint" }
```

`@expo/fingerprint`, which Expo already installed, computes the same hash from the command line. To see its
changes, save this little reader of its comparisons as `changed.mjs`:

```javascript
// changed.mjs: read fingerprint:diff's answer and print one line per native source that changed.
//
//   npx @expo/fingerprint fingerprint:diff A.json B.json | node changed.mjs
import { text } from "node:stream/consumers";

for (const d of JSON.parse(await text(process.stdin))) {
  const s = d.afterSource ?? d.addedSource ?? d.beforeSource ?? d.removedSource ?? d.source;
  console.log(d.op.padEnd(8), s.type.padEnd(9), s.filePath ?? s.id ?? s.name);
}
```

Then compute the fingerprint, change the wording of the note at the foot of the *Courses* tab in
`src/PlanScreen.tsx` to *the planner counts its weeks from Monday*, and compute it again:

```
ana@dev:~/planner$ grep -A2 runtimeVersion app.json
    "runtimeVersion": {
      "policy": "fingerprint"
    }
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:generate > before.json
ana@dev:~/planner$ node -p "require(\"./before.json\").hash"
32541c36c38a038d87ab6d075d07d1f70462e18d
ana@dev:~/planner$ grep -n "counts its weeks" src/PlanScreen.tsx
45:        Your phone's calendar starts the week on {DAYS[WeekStart.firstWeekday()]}; the planner counts its weeks from Monday.
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:generate > after-js.json
ana@dev:~/planner$ node -p "require(\"./after-js.json\").hash"
32541c36c38a038d87ab6d075d07d1f70462e18d
```

**The same hash: text is JavaScript, so a build made before the change can take the change as an update.**
Now a library with native code, `expo-haptics`, which makes the phone vibrate, and the hash again:

```
ana@dev:~/planner$ npx expo install expo-haptics > /dev/null 2>&1
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:generate > after-native.json
ana@dev:~/planner$ node -p "require(\"./after-native.json\").hash"
067bc58992dd2a05bec9c345c035fdb767a3f369
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:diff before.json after-native.json | node changed.mjs
changed  contents  expoAutolinkingConfig:android
changed  contents  expoAutolinkingConfig:ios
added    package   node_modules/expo-haptics/package.json
ana@dev:~/planner$ npm uninstall expo-haptics > /dev/null 2>&1
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:generate | node -p "JSON.parse(require(\"fs\").readFileSync(0)).hash"
32541c36c38a038d87ab6d075d07d1f70462e18d
```

**A different hash, and the comparison says why**: the list of native modules autolinking will link changed
on both platforms, and a package with native code was added. An update made after this change would carry
the new runtime version, and no build made before it would download it. Then `expo-haptics` goes again, the
planner never used it, and **the hash is the first one again**: the fingerprint describes what the native side
*is*, not what happened to it.

```
ana@dev:~/planner$ npx jest weekStart --forceExit 2>&1 | grep -E "Tests:"
Tests:       1 passed, 1 total
```
