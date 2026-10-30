---
title: Crashlytics and Sentry, and the symbols they need
version: 1
---

**The two crash reporters most mobile teams use are Firebase Crashlytics, which is free and part of
Google's Firebase, and Sentry, which is a paid service with a free tier and can also run on your own
servers.** Both do what the last section's forty lines did, and much more: native crashes caught by
signal handlers, freezes, grouping, alerts. Both need the same extra step to be useful, which is
**uploading the symbols of every release build**. *Neither was set up for this course; the listings
are written from each product's documentation, October 2026, and were not built.*

## Adding one

| | Crashlytics | Sentry |
|---|---|---|
| Android | the Google services and Crashlytics Gradle plugins, and the `firebase-crashlytics` library | the Sentry Gradle plugin and `io.sentry:sentry-android` |
| iOS | the `FirebaseCrashlytics` package, and a build phase that uploads dSYMs | the `Sentry` package, and `sentry-cli` uploading dSYMs |
| React Native | `@react-native-firebase/crashlytics` | `@sentry/react-native`, with a plugin for Expo |

Starting the reporter is one line in each, and it goes first, before the app's own code:

```kotlin
// PlannerApp.kt: Sentry starts before anything else in the Application
class PlannerApp : Application() {
    override fun onCreate() {
        super.onCreate()
        SentryAndroid.init(this) { it.dsn = BuildConfig.SENTRY_DSN; it.release = "planner@1.5.0+1050003" }
    }
}
```

```swift
// PlannerApp.swift: the same, in the SwiftUI app's initialiser
import Sentry
@main struct PlannerApp: App {
    init() { SentrySDK.start { $0.dsn = Secrets.sentryDSN; $0.releaseName = "planner@1.5.0+1050003" } }
    var body: some Scene { WindowGroup { WeekView() } }
}
```

```typescript
// index.ts: and in React Native, before the root component is registered
import * as Sentry from "@sentry/react-native";
Sentry.init({ dsn: process.env.EXPO_PUBLIC_SENTRY_DSN, release: "planner@1.5.0+1050003" });
```

The **release name** carries the version and the build number of lesson 9, so a report can be
matched to exactly one build, and to that build's symbols.

## Why symbols

A release build is not the code you wrote. On Android, **R8** shrinks and renames classes and methods
to save size, so `WeekViewModel.totalMinutes` becomes `a.b`. On iOS, the compiled binary has no
function names in it at all, only addresses. In React Native, the JavaScript is **minified** into
one line. A stack trace from any of them is unreadable without a file produced by **that exact
build**:

| platform | what the build produces | what it maps |
|---|---|---|
| Android | `mapping.txt`, from R8 | short names back to classes, methods and lines |
| iOS | a `.dSYM` bundle, from Xcode | addresses back to functions, files and lines |
| React Native | a **source map**, from Metro or Hermes | positions in the bundle back to the source files |

**The symbols must be uploaded from the build that shipped**, because a rebuild of the same commit
produces a different mapping. That is lesson 7's rule again: one build, kept, with everything it
produced. Both Crashlytics and Sentry do it with a build step, and a team finds out it forgot only
when the first unreadable crash arrives. Lesson 13 makes a minified trace readable by hand, so you
know what the upload is for.

## Two settings that are privacy decisions

- **Whether to attach a user identifier.** Both products let the app set one. Without it, crashes
  are counted per installation; with it, they become *Data Linked to You*, lesson 5.
- **What the breadcrumbs record.** Both record navigation and network requests automatically, and
  a URL with a person's search in it, or an e-mail in a query string, goes into every report. Both
  have a hook, `beforeSend` in Sentry, to strip it.
