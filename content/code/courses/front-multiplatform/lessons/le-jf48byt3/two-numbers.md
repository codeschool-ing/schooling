---
title: Two numbers, and four places they live
version: 1
---

**Every release carries a version, and on a phone it carries two.** One is for people: `0.2.0`, `1.4.1`, the
number a store page shows and a bug report quotes. The other is for the system: a whole number that must grow
with every build a store receives, and that decides which build is newer.

| system | for people | for the system |
|---|---|---|
| npm, Electron, Tauri | `version` in `package.json` or `tauri.conf.json` | the same string |
| Android | `versionName`, any text | `versionCode`, a whole number that only grows |
| iOS | `CFBundleShortVersionString`, Xcode's **Version**, `MARKETING_VERSION` | `CFBundleVersion`, Xcode's **Build**, `CURRENT_PROJECT_VERSION` |

**The number for people follows semantic versioning**, three numbers, `MAJOR.MINOR.PATCH`: the patch moves for a
fix, the minor for something new that breaks nothing, and the major for a change that does break something,
such as a file format the old version cannot read. A person reading `1.4.1 → 1.5.0` should be able to guess
what kind of update it is.

**The number for the system is unforgiving.** Google Play refuses a bundle whose `versionCode` is not higher
than every one it has seen for the app, and App Store Connect refuses a build number it already has for that
version. Neither number can be reused or go back, even for a build that was rejected and never reached anybody.

Lesson 9 met these for Expo. The planner has them in four files, written by four tools, and they already
disagree:

```
ana@dev:~/planner$ grep -n "\"version\"" package.json src-tauri/tauri.conf.json
package.json:4:  "version": "0.1.0",
src-tauri/tauri.conf.json:4:  "version": "0.1.0",
ana@dev:~/planner$ grep -n "versionCode\|versionName" android/app/build.gradle
10:        versionCode 1
11:        versionName "1.0"
ana@dev:~/planner$ grep -n "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" ios/App/App.xcodeproj/project.pbxproj
303:				CURRENT_PROJECT_VERSION = 1;
310:				MARKETING_VERSION = 1.0;
325:				CURRENT_PROJECT_VERSION = 1;
332:				MARKETING_VERSION = 1.0;
```

**Four places, two different versions.** `package.json` says `0.1.0`, because lesson 13 set it; so does Tauri,
which `tauri init` wrote. The Android project says `1.0` and the iOS project `1.0`, both from Capacitor's
template, with a build number of 1. A release made now would be `0.1.0` on the desktop and `1.0` on the phones,
for the same code. The next section gives the version one home.
