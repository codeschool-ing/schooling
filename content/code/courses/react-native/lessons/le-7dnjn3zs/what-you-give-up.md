---
title: What Expo costs you
version: 1
---

**Expo's costs are real, and none of them is the one people fear.** The fear is a cage: an app that
cannot have native code, or cannot leave. Neither is true any more, as the last two sections showed.
What Expo does cost is narrower, and worth naming before a team commits to it.

## Its release schedule becomes yours

**An Expo SDK is released a few times a year, each for one React Native version.** Upgrading React
Native means upgrading the SDK, and every `expo-` library moves with it. That is usually the
easier path, because the libraries were tested together; but you cannot take a React Native release
the week it comes out, and you cannot hold one Expo library back while upgrading the rest. A team
that needs a fix in React Native itself waits for the SDK that contains it, or patches the package
in the meantime.

## Its conventions shape the project

Prebuild works because the native folders are generated, and that only holds while **nobody edits
them by hand**. Every native change has to be a config plugin. For a change a library already
covers, that costs nothing. For an unusual one, a custom Gradle task or an Xcode build phase, it is
more work than editing the file would have been, and somebody on the team has to learn to write
plugins rather than Gradle.

## The paid services are convenient and optional

Builds in the cloud, over-the-air updates and store submissions are EAS, and they have a free
allowance and paid plans beyond it. The open-source half of Expo does not need them, and each has a
local alternative:

| EAS service | the local alternative | lesson |
|---|---|---|
| EAS Build | Gradle on your computer for Android; Xcode on a Mac for iOS | 3 and 20 |
| EAS Update | a server of your own that speaks Expo's update protocol | 21 |
| EAS Submit | uploading in the stores' own consoles | 20 |

**The one that is hard to replace is EAS Build for iOS without a Mac**, because the alternative is a
Mac. Lesson 20 is about that case.

## The size of the app

An Expo project includes `expo` and its module system, which a bare app may not need. Lesson 19
measures what the planner's bundle contains, that part included. For most apps it is not the part
that matters; for an app that must fit a strict size limit, it is measured rather than assumed.

## What is not a cost

**Leaving.** `npx expo prebuild` writes the folders; committing them and removing them from
`.gitignore` is the whole migration to a bare project, and the Expo libraries keep working in it.
A team that decides in a year that it wants to own its native projects pays one commit. That is the
property that makes starting with Expo a cheap decision rather than a permanent one.
