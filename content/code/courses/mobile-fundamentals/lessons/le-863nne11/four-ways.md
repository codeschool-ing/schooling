---
title: Four ways to build one app
version: 1
---

**There are four ways to put the same app on Android and on iPhone, and they differ in how much of
the program is written once.** The common picture is a converter: you write the app in one place and
a tool turns it into two native apps. Nothing does that. Each approach decides instead which parts
run on both phones unchanged and which parts are written separately for each one.

| approach | what you write | what draws the screen | what is written once |
|---|---|---|---|
| native, per platform | Kotlin with Jetpack Compose; Swift with SwiftUI | the platform's own views | nothing: there are two apps |
| multiplatform UI | React Native: JavaScript or TypeScript. Flutter: Dart | React Native: the platform's views. Flutter: its own engine | the screens and the logic |
| shared logic | Kotlin Multiplatform, plus each platform's screens | the platform's views, or Compose Multiplatform | the logic |
| web wrapper | HTML, CSS and JavaScript, inside Capacitor or Cordova | a WebView, which is a browser engine | everything, as a website |

## Native, per platform

**Two apps, in two languages, by two sets of tools.** The Android app is Kotlin, with screens in
Jetpack Compose and built in Android Studio. The iOS app is Swift, with screens in SwiftUI and built
in Xcode. Nothing passes between them except the design and the server they both talk to. Every
rule in the planner, such as which week a session falls in, is written twice, and a bug fixed in one
is still waiting in the other. In exchange, each app uses its platform's newest feature the day it
ships, and nothing stands between the code and the system.

## Multiplatform UI: React Native and Flutter

**One codebase, screens included, for both phones.** React Native is written in JavaScript or
TypeScript with React, and Flutter in Dart, a language from Google, like Flutter itself. Both put the whole app in one
project and build an Android package and an iOS package from it. They are grouped together because
of what they share, which is the screens, and they are opposites in how those screens reach the
glass: React Native asks the platform for its own views, and Flutter paints every pixel itself. The
next section is about that difference.

## Shared logic only: Kotlin Multiplatform

**The rules are written once in Kotlin, and the screens stay native.** Kotlin Multiplatform, from
JetBrains, compiles the same Kotlin code for Android and for iOS. A team writes the planner's data,
its sums and its network calls once, and still draws the Android screens in Compose and the iOS
screens in SwiftUI. Teams that want to share the screens as well can add Compose Multiplatform,
JetBrains' toolkit that runs Compose screens on iOS too, which moves this approach towards the
previous one.

## Web wrappers, and the PWA

**A wrapper is a native app whose whole screen is a web page.** Capacitor, and Cordova before it,
take a website, put it inside an Android project and an iOS project, and show it in a WebView, the
browser engine the system lends to apps. It goes to the stores like any app, and plugins give the
page the camera or the file system. A **progressive web app** is less again: a website the browser
can install on the home screen, with no app package and no store of its own. It is the cheapest way
in, and it reaches only what the browser allows.

## Where this course goes next

The track's fork after this course offers three of these. **Android with Kotlin** and **iOS with
Swift** are the native route, one platform each. **Multiplatform with React Native** is the one
multiplatform UI the track teaches. Flutter and Kotlin Multiplatform are not a route here, and the
`react-native` course looks at both in its lesson 22. Wrappers are the subject of
`front-multiplatform`, which takes Capacitor from its lesson 2 to its lesson 6. Lesson 3 of this
course is how to choose between them.
