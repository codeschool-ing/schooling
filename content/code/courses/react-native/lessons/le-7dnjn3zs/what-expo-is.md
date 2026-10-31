---
title: What Expo is, and what it is not
version: 1
---

**Expo is not a different framework.** An Expo app is a React Native app: the same `View`, the same
`Text`, the same React, the same Hermes running the same bytecode. What Expo adds is everything
around React Native that a team would otherwise assemble by hand, and since 2024 React Native's own
documentation recommends starting a new app with it.

The name covers several things that are worth keeping apart, because each one can be taken or left
on its own:

| part | what it is | costs money? |
|---|---|---|
| **the SDK** | a set of libraries, `expo-camera`, `expo-sqlite`, `expo-location` among more than eighty, released together and tested against one React Native version | no |
| **the CLI** | `npx expo`: starts the development server, installs matching versions, exports, generates the native projects | no |
| **Expo Go** | an app from the stores that runs your project on a phone without building it | no |
| **prebuild** | generates the `android/` and `ios/` folders from your configuration | no |
| **EAS** | Expo Application Services: builds in Expo's cloud, over-the-air updates, store submissions | a free allowance, then paid plans |

**The first four are open source and run on your computer.** EAS is a company's paid service, and
nothing in the first four depends on it. Lessons 20 and 21 cover EAS, what it costs and the local
alternative to each part of it.

## One SDK, one React Native

**An Expo SDK release is built for exactly one React Native version.** SDK 58, which this course uses,
pairs with React Native 0.88. Every library in the SDK is tested against that version and against
the others in the same release. That is the main thing Expo saves you from: finding out which
version of a camera library works with which version of a navigation library and which version of
React Native, one crash at a time.

`npx expo install` is how you use that. Asked for a package, it looks up the version that belongs to
your SDK and installs that one, rather than the newest. For a package that is not part of the SDK,
it installs the newest, like `npm install` would. Lesson 3 uses it for every library the planner
needs.

## What "managed" used to mean

Older material divides Expo projects into **managed** and **bare**, or talks about **ejecting**. Those
words describe Expo before 2021. A managed project then could not contain native code at all, and
ejecting meant converting it, once and for good, into a plain React Native project with its native
folders written out. **Neither restriction exists any more.** An Expo project today can contain any
native code, its own or a library's; lessons 2 and 17 show how. If you meet *eject* in an article,
it is describing a step nobody takes now.

## What Expo does not do

It does not hide the native platforms. Permissions, app identifiers, signing keys and store rules are
the same for an Expo app as for any other, and lessons 13, 20 and 21 deal with them directly. It
does not make an app run on a platform React Native does not support. And it does not remove the
need for a Mac to build for iOS: it moves the Mac, either to your desk or to Expo's cloud.
