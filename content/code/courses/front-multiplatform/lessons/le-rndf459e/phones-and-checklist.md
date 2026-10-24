---
title: The phone packages, and a checklist before any of them
version: 1
---

**The Android and iOS packages are built by the platforms' own tools, and none of them ran on the
recording machine**: Gradle needs the Android SDK, which it could not download, and an `.ipa` needs Xcode.
What follows is the steps from Capacitor's and Google's documentation, marked as not run, so that you know
what to expect on your own computer.

## Android: an APK to try, an AAB to publish

Capacitor's CLI can drive Gradle for you. **`npx cap build android`** runs the release build of the
`android/` project and signs it with a key you give it, which lesson 14 creates:

```sh
npm run build && npx cap sync android
npx cap build android --androidreleasetype AAB \
  --keystorepath ~/keys/planner-upload.jks --keystorealias upload
```

*Not run.* The same build from Android Studio is **Build, Generate Signed App Bundle or APK**, and from a
terminal inside `android/` it is `./gradlew bundleRelease` for an AAB and `./gradlew assembleRelease` for an
APK, with the signing settings in `android/app/build.gradle`. The results land under
`android/app/build/outputs/`, in `bundle/release/` and `apk/release/`.

**Build the AAB for Google Play and an APK for everyone else**: a tester you send a file to, or your own
site. Play accepts only bundles for new apps, and builds from each one the APKs that phones download.

## iOS: an archive, from Xcode

On a Mac, `npx cap open ios` opens the project of lesson 3 in Xcode. **Product, Archive** builds the app
for devices and keeps it in Xcode's Organizer, and from there **Distribute App** signs it and either uploads
it to App Store Connect, for TestFlight and the App Store, or exports an `.ipa` for a company's own
distribution. *Not run, for the reason lesson 1 gave.* Capacitor's CLI can do the same from a terminal on a
Mac, with `npx cap build ios`, given the signing settings of lesson 14.

## A checklist before any package

A package is the code as it was the moment it was built, so the checks belong before the build, not after
someone has installed it. The planner's checklist, in the order a release goes:

| check | how | caught here |
|---|---|---|
| the site is freshly built | `npm run build`, and read its last line | lesson 1: a failed build leaves the old `dist/` |
| the phone projects have that site | `npx cap sync` | lesson 2: a project with yesterday's `dist/` |
| **no `server.url` and no `cleartext`** | the `grep` below | lesson 2: an app that is a page on your network |
| one version everywhere | lesson 15 | `package.json`, `tauri.conf.json`, Android and iOS |
| the icon is the app's own | look at the package | this lesson |
| only the app's files are packed | `npx asar list`, or the package's file list | this lesson |
| the permissions are the ones the app uses | `AndroidManifest.xml` and `Info.plist` | lesson 4 |

**The third row is the one lesson 2 promised.** Live reload works by putting a `server.url` in Capacitor's
configuration, and an app built with it set opens an address on your network instead of the app it
carries. `cap sync` copies the configuration into each native project, so the search covers all three
places:

```
ana@dev:~/planner$ grep -n "url\|cleartext" capacitor.config.ts android/app/src/main/assets/capacitor.config.json ios/App/App/capacitor.config.json; echo "grep exit status: $?"
grep exit status: 1
```

**No line printed, and `grep` exited with 1, which is its way of saying it found nothing**: the
configuration that ships has no `server.url`. A 0 there would mean a line was found and printed above it,
and the release stops until it is gone. A check you run by hand is a check you forget on the evening it
matters, so a project that releases often puts this line in a script, or in CI, and lets it fail the build.
