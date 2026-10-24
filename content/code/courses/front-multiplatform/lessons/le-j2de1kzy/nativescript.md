---
title: NativeScript, the platform's interfaces from JavaScript
version: 1
---

**NativeScript runs your JavaScript, like React Native, and draws with the platform's own views, like
React Native.** Where it differs is how far it lets the JavaScript reach. Every class of Android's and
iOS's own interfaces is available from JavaScript by its native name, so a line of TypeScript can create
an Android `TextView` or call an iOS framework directly, without a plugin written in Kotlin or Swift in
between.

The screens are described in an XML of NativeScript's own, or written with Angular, Vue, Svelte, React or
Solid through adapters for each, which makes it the one tool here that does not ask you to change
framework. The planner's rules would come across as they did to React Native, as TypeScript with no DOM.

*NativeScript was not installed for this course. Its command-line tool builds for Android with the
Android SDK and for iOS with Xcode, neither of which the recording machine had, and unlike Expo it has no
web target to look at instead. What this section says comes from NativeScript's documentation.*

## Where it fits

**It is the right tool when the app's core is platform features**, and a team wants to reach them without
writing native code, or when a team already lives in one of the frameworks it supports. Its community is
much smaller than React Native's or Flutter's, which matters for the libraries you can find and the
answers you can search for, and that is the honest reason it is the least used of the three.

## And the native languages themselves

Kotlin for Android and Swift for iOS remain the reference that every tool here is measured against: the
platform's own language, its own interface toolkits, Jetpack Compose and SwiftUI, and everything new on
the day it is released. **Kotlin Multiplatform** shares Kotlin code, and with Compose Multiplatform also
the screens, across Android and iOS. None of them reuses anything of a web app, which is why this course,
for web developers, ends its tour here.
