---
title: Two numbers, for two readers
version: 1
---

**A mobile release carries two version numbers, and the mistake is to think one of them is a copy of
the other.** One is a name for people; the other is a counter for machines. They are set in
different places, checked by different rules, and they fail in different ways.

| | for people | for machines |
|---|---|---|
| Android | `versionName`, such as `1.5.0` | `versionCode`, a positive integer |
| iOS | `CFBundleShortVersionString`, such as `1.5.0` | `CFBundleVersion`, the build number |
| React Native, with Expo | `version` in `app.json` | `android.versionCode` and `ios.buildNumber` in `app.json` |

**The name is shown and never compared.** The store page says *Version 1.5.0*, the app's About
screen says it, a support e-mail quotes it. Android does not look at it at all when deciding about an
update; it can be any text.

**The code is compared and never shown.** Android decides that a package is an update, and not a
downgrade, by its `versionCode` alone. Apple's build number identifies one upload among the builds of
a version, and it is what TestFlight lists.

## Where each one is set

```kotlin
// build.gradle.kts: both numbers live in the app module's defaultConfig
android {
    defaultConfig {
        versionCode = 1050003
        versionName = "1.5.0"
    }
}
```

```swift
// The Xcode target's build settings set both, and Info.plist reads them:
//   MARKETING_VERSION = 1.5.0          -> CFBundleShortVersionString
//   CURRENT_PROJECT_VERSION = 1050003  -> CFBundleVersion
```

```json
{
  "expo": {
    "version": "1.5.0",
    "android": { "versionCode": 1050003 },
    "ios": { "buildNumber": "1050003" }
  }
}
```

*The three listings are written from each platform's documentation and were not built here.* The
manifest of lesson 1 set `android:versionCode` and `android:versionName` directly, and `aapt2`
compiled them into the APK: that is where Gradle's two lines end up.
