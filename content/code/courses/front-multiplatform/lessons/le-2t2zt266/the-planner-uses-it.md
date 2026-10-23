---
title: The planner uses it
version: 1
---

**The planner installs the plugin from its folder, the way it would install it from the registry.**
`npm install ../keep-awake` writes a `file:` dependency, which links the folder rather than copying it,
so a rebuild of the plugin reaches the planner without installing again:

```
ana@dev:~/planner$ npm install -E ../keep-awake

added 1 package, and audited 128 packages in 477ms

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ grep keep-awake package.json
    "capacitor-keep-awake": "file:../keep-awake"
ana@dev:~/planner$ npx cap sync android | grep -A7 "plugins for android"
[info] Found 6 Capacitor plugins for android:
       @capacitor/camera@8.2.6
       @capacitor/filesystem@8.1.5
       @capacitor/geolocation@8.2.4
       @capacitor/local-notifications@8.3.1
       @capacitor/preferences@8.0.1
       capacitor-keep-awake@0.0.1
✔ update android in 62.71ms
```

**The sixth plugin is in the list**, found by the same `cap sync` that found the official five, from
the `capacitor` key of its `package.json`. On the iOS side, sync wrote it into `Package.swift` the same
way. Nothing tells Capacitor that this one is yours.

## Three small edits

In `src/device.ts`, import the plugin below the camera's import:

```typescript
import { KeepAwake } from "capacitor-keep-awake";
```

and add one function at the end of the file:

```typescript
export async function keepScreenOn(on: boolean): Promise<string> {
  if (on) await KeepAwake.keepAwake();
  else await KeepAwake.allowSleep();
  return on ? "the screen stays on" : "the screen may sleep again";
}
```

In `src/view.ts`, the list of device actions gains two words, in the `Actions` type:

```typescript
  device: (what: "export" | "where" | "photo" | "remind" | "awake" | "sleep", session?: string) => void;
```

and the course screen two buttons, after the photo one:

```typescript
  root.append(list, form, button("Photo of my notes", () => act.device("photo")),
    button("Keep the screen on", () => act.device("awake")), button("Let the screen sleep", () => act.device("sleep")), said);
```

In `src/main.ts`, import `keepScreenOn` beside the other device functions, add the same two words to
the signature of `device()`, and one line after the photo's:

```typescript
    if (what === "awake" || what === "sleep") say(await keepScreenOn(what === "awake"));
```

Build, and try it in the browser, first as a page that has not been given permission, then with it:

```
ana@dev:~/planner$ npm run build | tail -n 2

✓ built in 223ms
```

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Statistics --click 'Keep the screen on' --wait 300 | tail -n 1
  - status: "awake failed: Wake Lock permission request denied"
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Statistics --grant screen-wake-lock --click 'Keep the screen on' --wait 300 | tail -n 1
  - status: the screen stays on
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Statistics --grant screen-wake-lock --click 'Keep the screen on' --click 'Let the screen sleep' --wait 300 | tail -n 1
  - status: the screen may sleep again
```

**The refusal is the browser's, word for word**, and the planner reports it as it reports any
failure. Headless Chromium refuses a wake lock unless it is granted, the way a phone refuses when the
app is not on the screen. With it granted, the lock is taken and released, and the status line says
which. On a phone, the same two buttons reach the Kotlin or the Swift class instead, and there is no
question to answer at all: keeping the screen on needs no permission on either system.

Commit the planner:

```
ana@dev:~/planner$ git add . && git commit -q -m "Keep the screen on during a session" && git log --oneline -1
7a7313d Keep the screen on during a session
```

## Publishing it, or not

The plugin now works for the planner from a folder beside it. For anybody else, it would be
published to npm with `npm publish`, after a real version number, a README that says which platforms
it supports, and tests on each one. Lesson 15 is about version numbers. **Most plugins written for one
app never need publishing**, and staying in a folder of the app's repository, or in a monorepo beside
it, is a perfectly good home for one.
