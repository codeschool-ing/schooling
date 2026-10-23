---
title: Build, then sync, every time
version: 1
---

**The native projects hold a copy of `dist/`, not a link to it.** Every change to the planner reaches
the phone in two steps, and they always come in the same order: `npm run build` writes `dist/`, and
`npx cap sync` copies it into both projects. Leave out the first and you copy an old build; leave out
the second and the projects keep the one before.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" data-fig=\"l02-loop\" aria-label=\"The loop that puts a change on the phone. You edit src, npm run build writes dist, npx cap sync copies dist into android and ios, and the native build makes the app. Skipping the build copies an old dist; skipping the sync leaves the projects with the copy before.\"><defs><marker id=\"l02-loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"155\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"97.5\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">edit</text><text x=\"97.5\" y=\"62.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">src/</text><rect x=\"195\" y=\"30\" width=\"155\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"272.5\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">npm run build</text><text x=\"272.5\" y=\"62.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">writes dist/</text><rect x=\"370\" y=\"30\" width=\"155\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"447.5\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">npx cap sync</text><text x=\"447.5\" y=\"62.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copies into android/, ios/</text><rect x=\"545\" y=\"30\" width=\"155\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"622.5\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the native build</text><text x=\"622.5\" y=\"62.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Android Studio, Xcode</text><path d=\"M175 56 L195 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-loop-ah-paper-dim)\"></path><path d=\"M350 56 L370 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-loop-ah-paper-dim)\"></path><path d=\"M525 56 L545 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-loop-ah-paper-dim)\"></path><text x=\"272\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--amber)\">skip it: an old dist/ is copied</text><text x=\"447\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--amber)\">skip it: the projects keep the last copy</text></svg>", "caption": "Two steps between your code and the phone, always in this order."}
```

## Where the copy goes

```
ana@dev:~/planner$ ls android/app/src/main/assets android/app/src/main/assets/public
android/app/src/main/assets:
capacitor.config.json
capacitor.plugins.json
public

android/app/src/main/assets/public:
assets
cordova.js
cordova_plugins.js
courses.json
index.html
ana@dev:~/planner$ cat android/app/src/main/assets/capacitor.config.json
{
	"appId": "com.example.studyplanner",
	"appName": "Study planner",
	"webDir": "dist"
}
```

`public/` is `dist/` as it was at the last sync, with two small files Capacitor adds for Cordova
plugins. Beside it are two files Capacitor writes for the native side: **`capacitor.config.json` is
`capacitor.config.ts` turned into JSON**, because neither Java nor Swift reads TypeScript, and
`capacitor.plugins.json` lists the plugins the app was synced with.

**None of these is in git.** Capacitor's own `.gitignore` files leave them out, because they are
copies made from things that are in git:

```
ana@dev:~/planner$ git check-ignore -v android/app/src/main/assets/public ios/App/App/public
android/.gitignore:96:app/src/main/assets/public	android/app/src/main/assets/public
ios/.gitignore:4:App/App/public	ios/App/App/public
```

## The copy that was not refreshed

This is the mistake everybody makes once. Change a word in `src/view.ts`, sync without building,
and look at what the Android project now holds:

```
ana@dev:~/planner$ grep -oE "(Back to|All) courses" android/app/src/main/assets/public/assets/*.js
All courses
ana@dev:~/planner$ sed -i 's/All courses/Back to courses/' src/view.ts
ana@dev:~/planner$ npx cap sync android
✔ Copying web assets from dist to android/app/src/main/assets/public in 6.43ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 906.90μs
✔ copy android in 16.14ms
✔ Updating Android plugins in 1.31ms
✔ update android in 23.93ms
[info] Sync finished in 0.05s
ana@dev:~/planner$ grep -oE "(Back to|All) courses" android/app/src/main/assets/public/assets/*.js
All courses
```

**`cap sync` did everything it says it did**, and the Android project still says "All courses",
because it copied `dist/`, and `dist/` was built before the change. Nothing warned, and on a phone the
app would simply look as if the edit had been lost. Build first:

```
ana@dev:~/planner$ npm run build && npx cap sync android

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 6 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                0.32 kB │ gzip: 0.23 kB
dist/assets/index-BEhkw5vf.js  2.90 kB │ gzip: 1.34 kB

✓ built in 103ms
✔ Copying web assets from dist to android/app/src/main/assets/public in 7.35ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 1.04ms
✔ copy android in 18.31ms
✔ Updating Android plugins in 1.06ms
✔ update android in 18.60ms
[info] Sync finished in 0.045s
ana@dev:~/planner$ grep -oE "(Back to|All) courses" android/app/src/main/assets/public/assets/*.js
Back to courses
```

`sync` is two commands in one: **`cap copy`** puts `dist/` and the configuration into the projects,
and **`cap update`** installs the native side of any plugin added to `package.json` since the last
time. Copy alone is enough for a change to your web code. Sync is the habit worth having, because it
is also right on the day you add a plugin.

Here the edit was put back, built and synced again, so the planner stays as lesson 1 wrote it. Then
the whole of this lesson goes into one commit, the native projects included:

```
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -q -m "Capacitor, and the Android and iOS projects"
ana@dev:~/planner$ git log --oneline
5ae7d06 Capacitor, and the Android and iOS projects
f608061 Look at the planner from the terminal
558b1c0 The study planner, as lesson 1 gives it
```
