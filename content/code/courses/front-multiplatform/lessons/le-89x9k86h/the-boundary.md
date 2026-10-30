---
title: The part that needs a Mac, said now
version: 1
---

**Two lessons of this course need a Mac, and it is better to know that now than at lesson 14.**
Apple's tools for building an iOS app, Xcode and its compilers, run on macOS and nowhere else, and so
does the signing that puts an app on an iPhone. Everything else in the course runs on Linux, Windows
or a Mac.

| lesson | what it needs beyond your computer |
|---|---|
| 3, the iOS half | a Mac with Xcode, to open and run the iOS project Capacitor generated |
| 14, the Apple half | a Mac with Xcode, and a paid membership of the Apple Developer Program |
| 3, 4 and 5, the Android half | Android Studio, its SDK and an emulator, or an Android phone with a cable |
| 7 to 9 | optionally an Android or iOS phone with the Expo Go app; the browser does for the rest |
| 13 and 14, the stores | an account with Google Play and, for iOS, the membership above |
| everything else | Node.js 22, git and a browser, which you already have |

**Without a Mac you can still do every lesson.** You read the iOS halves of lessons 3 and 14 as
material, not as practice: what the Xcode project contains, which files you edit, what a signing
identity is and why the store asks for one. The Android halves cover the same ideas with tools you
can run. Expo's cloud build service, which lesson 9 describes, builds iOS apps on Apple machines it
rents, and is one way people without a Mac publish to the App Store. It needs an Expo account, and
the free plan has a monthly limit Expo sets.

**The store accounts cost money and are optional.** Lesson 14 shows what each store asks for and
where the money goes, and lesson 16's project can be released as a desktop installer and an Android
package you hand out yourself, without any store at all.

## What this course could not run

The course was recorded on a Linux computer, and a few steps could not be run there. **Each one is
marked where it appears**, with the documentation it comes from, so you know which output you are
reading as evidence and which as a description:

- **nothing from Xcode**, for the reason above;
- **no Android build, emulator or APK**: the recording machine could not reach Google's download
  server, so Android Studio and the Android SDK were never installed on it. Lesson 3 shows the steps
  from Google's documentation, and every Android file the course quotes is one Capacitor generated;
- **no store upload and no Expo cloud build**, which need accounts and a person to accept their terms.

Every other command in a transcript was run, and its output is pasted as it came back.
