---
title: A phone, an emulator, a simulator
version: 1
---

**Three places run the native app, and each needs something this course's recording computer did not
have.** What follows is taught from Expo's and the platforms' documentation. *None of it was run for
this course*, and none of it is needed to finish it; it is how you see the planner as a phone draws
it, when you have the means.

## A phone with Expo Go

The cheapest of the three. Install **Expo Go** from the App Store or Google Play, put the phone on the
same Wi-Fi as the computer, and start the development server:

```sh
npx expo start
```

It prints a QR code in the terminal. On Android, scan it from inside Expo Go; on an iPhone, with the
camera app, which offers to open it in Expo Go. The phone downloads the bundle from your computer, as
the `curl` in the Metro section did, and the planner appears with real native views. Save a file and
the phone updates.

**When the phone cannot reach the computer**, which is common on office, school and hotel networks
that keep devices apart, `npx expo start --tunnel` routes the connection through a public relay
instead. It is slower, and it sends your bundle through a third party's server, which is worth
knowing before using it on code you may not share.

The planner runs in Expo Go until lesson 17, where it gains a native module of its own. From then on
it needs the development build of the last section.

## An Android emulator

**An emulator is an Android phone running as a program**, and it needs hardware virtualisation: KVM on
Linux, the Windows Hypervisor Platform on Windows, the Hypervisor framework on a Mac. Android Studio's
*Device Manager* creates one: choose a phone, choose a system image (a download of its own, several
gigabytes), and start it. Then, in the terminal where `npx expo start` runs, press **`a`**: Expo
installs Expo Go on the emulator, or your development build if `expo-dev-client` is installed, and
opens the app. `npx expo run:android` does the build, the install and the start in one go.

A system image for the processor of your computer runs at near native speed; an ARM image on an Intel
computer, or the reverse, runs translated and slowly. Choose the one Device Manager recommends.

## The iOS simulator

**It needs a Mac with Xcode**, which is free from the Mac App Store and large. Open Xcode once to let it
install its components; then, with `npx expo start` running, press **`i`**, and Expo opens the
simulator, installs Expo Go in it and opens the app. `npx expo run:ios` builds a development build and
runs it there instead. The simulator runs the iOS app compiled for the Mac's own processor, so it is
quick, and it does not need an Apple developer account.

## A development build on a real iPhone

This one needs **signing**. iOS refuses to install an app that is not signed by an Apple identity that
the phone trusts. A free Apple account can sign a build for your own devices for seven days at a time;
the paid Apple Developer Program signs for longer and is required to publish. Lesson 20 explains
signing and the two ways of getting it done without a Mac on your desk.

## Which to use

| you have | use |
|---|---|
| a phone, any computer | Expo Go, until lesson 17; then a development build (Android: this lesson; iPhone: lesson 20) |
| no phone, a computer with virtualisation | the Android emulator |
| a Mac | the iOS simulator, and the Android emulator beside it |
| none of these | the browser and the tests, which is how this course was recorded |
