---
title: What an update is
version: 1
---

**A React Native app is two programs**: the native shell, Kotlin and Swift and every library's native
code, compiled into the build the store delivered; and the JavaScript bundle, which the shell loads and
runs. The store has to deliver the first. **The second is a file**, and a file can be replaced from a
server without a store in between. That is an over-the-air update.

`expo-updates` is the library that does it: at launch it asks an update server whether there is a newer
bundle for this build, downloads it, and runs it, at the next launch or at once, as configured. Install it:

```
ana@dev:~/planner$ npx expo install expo-updates
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 1 SDK 58.0.0 compatible native module using npm
> npm install

added 4 packages, and audited 1133 packages in 7s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

**What it downloads is exactly what `npx expo export` writes.** Export the planner for Android and look at
the description of the export, `metadata.json`:

```
ana@dev:~/planner$ npx expo export --platform android > /dev/null 2>&1
ana@dev:~/planner$ node -p "const m = require(\"./dist/metadata.json\").fileMetadata.android; [m.bundle, m.assets.length + \" assets\"].join(\"\\n\")"
_expo/static/js/android/index-b2458e330c5f77ad4ff827060629eb78.hbc
18 assets
ana@dev:~/planner$ du -sh dist
4.2M	dist
```

**An update is one Hermes bundle and the pictures it uses**, a few megabytes in all, named by their
content's hash, so a phone downloads only the files it does not already have. Publishing an update is
uploading these files with a description of which builds they are for; that description is the subject of
the section after next.

Look at what is not there: no Kotlin, no Swift, no `AndroidManifest.xml`, no `Info.plist`, no permission,
no icon. **Nothing native can arrive this way**, because the native side is compiled into the build, and the
build is what the store signed and delivered.
