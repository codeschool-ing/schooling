---
title: What you practise here, what you read, and what costs money
version: 1
---

**This course is about everything that happens after the build succeeds**: signing it, listing it
in two stores, getting it through review, releasing it a few per cent at a time, reading what
crashed, and deciding whether anybody came back. It comes after the track's fork, so you arrive
having built an app in Kotlin, in Swift or in React Native. Wherever the three differ, the course
shows all three side by side, briefly, and its own runnable examples are platform-free.

**Both stores charge before you can practise their half of it, and that is said here, before the
course asks you for anything.** A Google Play developer account has a one-off registration fee,
and Apple's developer program costs 99 US dollars a year, or the local price where Apple sets
one. Lesson 3 is about exactly those accounts. Nothing in this course requires you to open one:
every exercise and every transcript works without an account, a card or a phone.

## The line, lesson by lesson

| lesson | what you do on your computer | what you read |
|---|---|---|
| 1, Android signing | **practised**: a keystore, a signed APK, an app bundle and the re-signing Play does | the Play Console screens |
| 2, iOS signing | **half**: a script that warns before a certificate expires | Xcode, certificates and profiles, all on a Mac |
| 3 to 7, the stores | **half**: a listing, a privacy inventory and a pre-submission check, as files and scripts | the consoles, review and the testing tracks |
| 8 and 9, rollout and versions | **practised**: a staged rollout simulated, and version numbers checked | the rollout controls |
| 10 and 11, CI and Fastlane | **half**: signing inside a pipeline, and Fastlane's lanes on Linux | the hosted Mac and the iOS half |
| 12 to 15, crashes and performance | **practised**: a crash reporter, a minified stack trace made readable, a watchdog, field percentiles | Crashlytics, Sentry and the stores' dashboards |
| 16 and 17, analytics | **practised**: events, a funnel and retention in SQLite | the analytics products |
| 18 to 20, size and versions in the wild | **practised**: an app bundle measured, remote config, a flag and a contract test | the store pages |

The iOS half is read throughout. Signing an iPhone app, running Xcode and opening the simulator
need a Mac, and the Mac is not optional: Apple's build tools run only on macOS. If you have one,
every Swift listing in the course drops into the app you built before the fork. Nothing in the
course depends on your having one.

## What this course could not run

The course was recorded on a Linux computer. It installed the Android build tools, and built,
signed, verified and measured Android packages with them. **It had no Mac, no Android emulator and
no phone.** So no iOS build was signed, no app was installed on any device, and no store console
was opened. Every such step is quoted from the platform's own documentation, with the month it
was read, and marked where it appears.

**The store rules in this course were read in October 2026, and they change without notice.**
Fees, review rules, privacy forms and size limits move every year. Where a lesson quotes a number
from a store's documentation, it says so, and the link in your console is the version that counts.

Every command in a transcript was run, and its output is pasted as it came back.
