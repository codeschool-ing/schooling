---
title: What you practise here, and what you read
version: 1
---

**This course runs on your computer from the first lesson to the last, and it needs no phone, no
Mac and no Android SDK.** That is a decision rather than a shortcut. Storage, an outbox, a retry, a
cursor and a conflict are the same problems on Android, on iOS and in React Native, and the course
comes after the track's fork, so you arrive having built an app on one of the three. Showing the
ideas in that one platform's code would leave two thirds of the students reading somebody else's
language.

So the work is split in two, and it is better to know where the line falls now than in lesson 16.

| what | how you meet it |
|---|---|
| the planner's storage, sync and conflicts | **practised**: TypeScript run by Node.js 22, with SQLite through `better-sqlite3` and a small server you write in lesson 8 |
| Kotlin, Swift and React Native listings | **read**: short, side by side, quoted from each platform's documentation |
| lesson 16, background work | **mostly read**: WorkManager, `BGTaskScheduler` and Expo's background task exist only on a device |
| lesson 19, the keystore and biometrics | **half read**: the encryption runs in Node; the hardware that guards the key is on the phone |
| lesson 20, the store forms | **read**: Google Play's Data safety form and Apple's privacy details, dated |

**If you have the tools for your platform, use them.** Every platform listing in this course is
small enough to drop into the app you built before the fork: the Android Studio project, the Xcode
project or the Expo project. Nothing in the course depends on your doing so.

## What this course could not run

The course was recorded on a Linux computer that could not reach Google's download server and was
not a Mac. **So no Android or iOS app was built or run here**, and each platform listing is marked
where it appears, with the documentation it comes from. You will know which code you are reading
as evidence and which as a description.

Every command in a transcript was run, and its output is pasted as it came back. Where a program
prints a date, it is a date in October 2026 that the program was given, so your run prints the
same line on any day.
