---
title: What this course runs, and what it only reads
version: 1
---

**Most of this course runs on an ordinary computer with no phone attached.** React Native's
components, state, navigation, lists, forms, data fetching and animations are JavaScript, and they
run in two places that need nothing but Node.js. One is **tests**, with Jest, which renders your
components without a screen and lets you press their buttons. The other is a **browser**, because Expo
builds the same app for the web, drawn with HTML standing in for the native views. Every transcript
in those lessons was recorded that way, on a Linux computer, and you can repeat each one on yours.

**Some of it needs a device, and a few parts need a Mac.** This course says which, here, so that
nobody discovers the wall halfway through a lesson.

## Lesson by lesson

| lessons | what you practise on a computer | what needs more |
|---|---|---|
| 1 to 11 | everything: the project, components, styles, lists, navigation, state, data, forms | a phone with Expo Go, if you want to see the native views |
| 12 | animations, in tests and in the browser | how smooth they feel is judged on a device |
| 13 | permissions as configuration; picking an image in the browser | the camera itself |
| 14 | storage in the browser and in tests | the secure store, which uses the phone's keychain |
| 15 | location in the browser, with a position you set | maps, and location in the background |
| 16 | what the app does with a notification | delivering a push notification to a phone |
| 17 | a Kotlin native module, built into an Android app | the Swift half, which needs Xcode |
| 18 and 19 | logs, errors, source maps, bundle size | the debugger attached to an app on a device |
| 20 | an Android release build, signed with your own key | building in Expo's cloud, and anything for iOS |
| 21 | what an update contains, and when one is safe | publishing it, which needs an Expo account |
| 22 | reading | — |

**The Android builds in lessons 3, 17, 18 and 20 need the Android SDK**, which runs on Linux,
Windows and macOS. They produce an app file and examine it. **Installing that file on an emulator
or a phone was not done when this course was recorded**: the computer had no hardware
virtualisation for an emulator and no phone attached. Where a lesson reaches that step it says so,
and gives the command you would run with a device connected.

## Marked where it happens

Inside a lesson, anything that was **not run** is written in italics and says so, like this: *the
iOS simulator was not run*. It is taught from the platform's own documentation, with no
transcript and no screenshot, because a transcript of something that never ran would be invented.
Everything shown in a terminal block was run, on the computer this course was recorded on, and
printed exactly what you see.

## The Mac question

**You do not need a Mac to finish this course.** You need one, or a paid cloud build, to put an iOS
app on an iPhone: Xcode is the only tool that builds one, Apple licenses it for macOS alone, and
the iOS simulator comes with it. Lesson 20 is about the second route — Expo's build service runs
Xcode on Expo's Macs — and what it costs. Everything this course teaches about iOS that does not
need Xcode, it teaches: the configuration Expo writes for it, the permissions it asks for, the rules
its store applies.

## Services this course does not depend on

Expo runs paid cloud services: builds (EAS Build), updates (EAS Update) and submissions to the
stores (EAS Submit). Lessons 20 and 21 explain them and what they cost on the day each lesson says,
and **neither lesson requires you to sign up**: each teaches the free, local alternative first. The
stores are the other cost, and the `mobile-delivery` course is about them.
