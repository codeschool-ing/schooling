---
title: The development loop, and where Expo Go stops
version: 1
---

**`npx expo start` is the centre of an Expo project's day.** It starts Metro, React Native's bundler,
which turns `app/` and everything it imports into one JavaScript bundle and serves it from your
computer. A phone or emulator running the app asks Metro for that bundle, runs it, and reloads it when
you save a file, the way `npm run dev` reloaded the planner in lesson 1.

What runs on the phone to ask for the bundle is the question that matters, and there are two answers:

| | **Expo Go** | **a development build** |
|---|---|---|
| what it is | an app from the stores, the same for everybody | your own app, built once with `expo-dev-client` in it |
| native code inside it | the libraries Expo ships for that SDK, and nothing else | whatever your app includes, its own native modules too |
| how you get it | install it from the store | build it, in the cloud or locally, and install it |
| good for | the first days, and an app with no native code of its own | everything after that |

**Expo Go is fixed.** It contains the native side of Expo's own libraries for one SDK version, so an
app that uses only those runs in it unchanged, and the planner does. The day your app needs a native
library Expo Go does not carry, or a native module of your own like lesson 5's plugin, Expo Go cannot
run it, because native code cannot be downloaded into an installed app. A **development build** is the
answer: your app, with Expo's developer menu in it, built once and then fed new JavaScript by Metro
exactly as Expo Go was.

*Neither was run for this course: both need a phone or an emulator, and lesson 3 says why there was
none. The rest of this lesson runs the parts of Expo that work without one.*

## The keys `npx expo start` listens to

In a terminal, Expo's development server prints a QR code and a short menu. The ones used most:

- **`a`** opens the app on an Android emulator or a connected phone, **`i`** on the iOS simulator on a
  Mac, **`w`** in a browser;
- **`r`** reloads the app, **`j`** opens the JavaScript debugger, **`m`** opens the developer menu on the
  device;
- scanning the QR code with the phone's camera, or from inside Expo Go on Android, opens the project on
  that phone, which has to be on the same network as the computer.
