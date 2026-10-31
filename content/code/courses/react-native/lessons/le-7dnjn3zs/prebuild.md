---
title: Prebuild: native folders generated from one file
version: 1
---

**In an Expo project the native folders are output, not source.** They are written by a command,
`npx expo prebuild`, from `app.json` and the libraries installed, and they can be deleted and written
again at any time. Expo calls this **Continuous Native Generation**. It is the answer to the three
costs of the bare project, and the best way to understand it is to watch it.

## A project with no native folders

Make a second project, this time from Expo's template, and let it install:

```
ana@dev:~$ npx create-expo-app@5.0.0 try-expo --template blank-typescript@sdk-58 > /dev/null 2>&1
ana@dev:~$ cd try-expo
ana@dev:~/try-expo$ ls
AGENTS.md
App.tsx
LICENSE
app.json
assets
index.ts
node_modules
package-lock.json
package.json
tsconfig.json
ana@dev:~/try-expo$ tail -3 .gitignore
# generated native folders
/ios
/android
```

There is no `android/` and no `ios/`, and the template's `.gitignore` says what to do when they
appear: leave them out of git. **What is committed is the description; what is generated is not.**

## Generating them

`npx expo prebuild` reads the configuration and writes both projects. `--no-install` skips running
CocoaPods, which only exists on a Mac; the folders are written anyway:

```
ana@dev:~/try-expo$ npx expo prebuild --no-install > /dev/null 2>&1
ana@dev:~/try-expo$ ls android ios
android:
app
build.gradle
gradle
gradle.properties
gradlew
gradlew.bat
settings.gradle

ios:
Podfile
Podfile.properties.json
tryexpo
tryexpo.xcodeproj
ana@dev:~/try-expo$ grep applicationId android/app/build.gradle
        applicationId 'com.anonymous.tryexpo'
```

They have the same shape as the bare project's, because the template behind them is React Native's
own with Expo's additions. The Android identifier, `com.anonymous.tryexpo`, is a placeholder made from
the project's name: nobody has said what this app is called in a store yet.

## Changing the description, not the output

**Every Android app is identified by a package name**, written like a reversed domain, and the stores
use it as the app's identity for good. In a bare project you would edit `build.gradle`. Here you
write it in `app.json`, inside the `"android"` object, beside what the template put there:

```json
"package": "org.example.planner"
```

Then generate again. `--clean` deletes the folders first, so nothing written last time survives:

```
ana@dev:~/try-expo$ grep -n package app.json
21:      "package": "org.example.planner"
ana@dev:~/try-expo$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/try-expo$ grep applicationId android/app/build.gradle
        applicationId 'org.example.planner'
```

The identifier in the Gradle file now says `org.example.planner`, and nobody edited that file. The
same works for the iOS bundle identifier (`"ios": { "bundleIdentifier": … }`), the app's name, its
icon, its version, its orientation, and the permissions of lesson 13: **one file, both platforms**.

## What this buys, and the rule it needs

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l02-cng\" aria-label=\"Continuous Native Generation. app.json, the installed libraries and your config plugins are committed to git. npx expo prebuild reads them and writes the android and ios folders, which git ignores. Editing a generated folder by hand is lost at the next prebuild --clean.\"><defs><marker id=\"l02-cng-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">committed to git</text><rect x=\"30\" y=\"36\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app.json</text><rect x=\"30\" y=\"80\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"95.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">installed libraries</text><text x=\"110.0\" y=\"108.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">and their plugins</text><rect x=\"30\" y=\"134\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">your plugins</text><rect x=\"260\" y=\"80\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">npx expo prebuild</text><path d=\"M190 53 L260 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><path d=\"M190 102 L260 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><path d=\"M190 151 L260 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">generated, ignored by git</text><rect x=\"520\" y=\"50\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"600.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">android/</text><rect x=\"520\" y=\"114\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"600.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ios/</text><path d=\"M440 95 L520 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><path d=\"M440 110 L520 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><text x=\"560\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">an edit made here by hand is gone after prebuild --clean</text></svg>", "caption": "The description is source; the native projects are output, written again whenever the description changes."}
```

The three costs of the bare project change shape:

- **A configuration change is one edit**, in JSON, and both platforms receive it.
- **An upgrade regenerates the folders** from the new template, so there is no diff to apply by hand.
  Your changes live in `app.json` and in plugins, which survive the regeneration because they are
  applied during it.
- **A library with native setup** ships a config plugin that does that setup during prebuild, so
  installing it and generating again is the whole job.

The price is one rule, and it is strict: **never edit a generated folder by hand.** The next `prebuild
--clean` deletes the edit without a word, and the build after it works, minus whatever the edit did.
When a change has to reach the native project, it is written as a config plugin, which is the next
section. A team that wants to edit the native folders directly can stop generating them and commit
them; that is a bare project again, and an Expo project can become one at any time.
