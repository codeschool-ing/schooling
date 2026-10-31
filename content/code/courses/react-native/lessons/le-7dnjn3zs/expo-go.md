---
title: Expo Go, and the wall it hits
version: 1
---

**Expo Go is a native app that already contains every library of one Expo SDK.** You install it from
the App Store or Google Play, start the development server on your computer, and point Expo Go at it.
It downloads your JavaScript and runs it inside itself. Nothing is compiled on your computer, no
Android SDK or Xcode is needed, and a change you save appears on the phone a second later.

*Expo Go on a phone was not run for this course*, because the computer it was recorded on had no
phone near it. Lesson 3 gives the steps, from Expo's documentation, and every lesson runs in a browser
as well.

## Why it is so quick

The slow part of building a mobile app is the native build: Gradle or Xcode compiling and packaging
everything. Expo Go has done that already, once, for everybody, with every native module of the SDK
compiled in. Your project then only adds what Hermes can run, JavaScript, and that is what the
development server sends. **Expo Go is a pre-built host and your app is a guest in it.**

## Where it stops

The same fact draws its limits, and they are not arbitrary:

- **Only the native code it was built with exists.** A library that is not part of the Expo SDK and
  carries native code, a payment SDK for instance, cannot run in Expo Go, because its Kotlin and Swift
  were never compiled into it. Pure JavaScript libraries work, because they arrive with your bundle.
- **Your app's native configuration does not apply.** Its name, its icon, its identifier and its
  permission texts are Expo Go's, not yours. A config plugin like the one two sections on changes
  nothing there.
- **One SDK version at a time.** The Expo Go in the stores follows the newest SDK. A project left on
  an older one may not open in it, and the fix is to upgrade the project rather than the app.
- **Some services need your own identity.** Push notifications sent to Expo Go arrive as Expo Go's;
  lesson 16 explains why a real app needs its own.

## The development build: your own Expo Go

The answer to every item on that list is the same: **build your own host**. A development build is
your app, compiled with its own native code and configuration, plus the library `expo-dev-client`,
which gives it Expo Go's ability to load JavaScript from the development server. You build it once,
install it on the phone or the emulator, and then work exactly as with Expo Go, until you add
another native library and build it again.

| | Expo Go | development build |
|---|---|---|
| native modules | the SDK's, fixed | whatever the project includes |
| your name, icon, permissions | no | yes |
| needs a native build | never | once, then after each native change |
| who builds it | Expo, already done | you, locally (lesson 3) or in Expo's cloud (lesson 20) |

**Start in Expo Go and leave it the day you need something it does not contain.** For a team that
already knows it will need a native library, that day is the first one, and the planner in this
course reaches it in lesson 17.
