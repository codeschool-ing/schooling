---
title: When you have to open them
version: 1
---

**Most days you never open the native projects.** You change the planner, build, sync and run, and the
work is all in `src/`. The native side needs you for a short list of reasons, and each one is a lesson
of this course:

| you need to | where | lesson |
|---|---|---|
| ask for a permission: camera, location, notifications | `AndroidManifest.xml`, and a key with a sentence in `Info.plist` | 4 |
| write native code, or debug a plugin's | Java or Kotlin in `android/app`, Swift in `ios/App` | 5 |
| set the icon and the launch screen | `res/mipmap-*` on Android, `Assets.xcassets` on iOS | 13 |
| sign the app for a store | a keystore in Gradle, a team and a profile in Xcode | 14 |
| raise the version | `build.gradle` on Android, the target's settings in Xcode | 15 |
| read an error the WebView never shows | Android Studio's Logcat, Xcode's console | below |

The last row is the one people forget. **A crash in native code never reaches the WebView**, so
nothing in your JavaScript can catch it or print it. Android Studio's Logcat window and Xcode's console
show the native log, where a plugin's own messages and a crash's stack trace appear. Chrome can attach
to a debuggable Android WebView at `chrome://inspect`, and Safari to an iOS one from its Develop menu,
which gives you the browser's own developer tools for the web half.

## The cost of every edit

Each change in a native folder is one more thing that has to survive the next Capacitor upgrade.
Capacitor's major versions come with an upgrade guide that lists the edits to make in each project
by hand, and a project that changed little has little to merge. **Prefer the setting in
`capacitor.config.ts`, then a plugin, then a native edit**, in that order, and when you do edit, commit
it on its own with a message saying why, so the next upgrade can find it.
