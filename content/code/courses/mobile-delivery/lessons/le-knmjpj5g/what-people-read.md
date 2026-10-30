---
title: What people read in a version
version: 1
---

**Semantic versioning, MAJOR.MINOR.PATCH, was written for libraries, where the reader is another
program; an app's reader is a person, and a person reads less into it.** For a library, a new major
version promises that something will break. A person seeing *2.0* in a store expects something big
and new; seeing *1.5.3* they expect nothing in particular. The numbers still help, as long as the
team uses them consistently.

## A convention for an app

| part | raised when | what a person should take from it |
|---|---|---|
| major | the app changes in a way people will notice: a redesign, a new model of what it does | read the notes |
| minor | a release adds something | something new is in it |
| patch | a release only fixes | the same app, working better |

Many teams version by date instead, `2026.10`, or simply count; both are fine, and the store does not
care. **What matters is that the name is unique and meaningful to support**: when somebody writes
"it crashes on 1.5.0", the team has to know exactly which build that is, and lesson 12's crash reports
group by the same name.

## The words beside the number

The number is read in a glance; the **release notes** are what explain it. Apple's *What's New* and
Google's release notes, lesson 4's fields, are where a person learns what changed.

- **Say what changed for the person, not for the code.** *"Sessions now sync between your phone and
  tablet"* rather than *"Refactored the sync engine"*.
- **"Bug fixes and performance improvements" says nothing.** It is the most common release note in
  both stores and tells nobody whether to update.
- **The notes are translated**, like every other field of the listing, and lesson 11's Fastlane sends
  them from files beside the listing of lesson 4.

## The version inside the app

The app should show its own version name and build number somewhere a person can find them, an
About screen or the foot of Settings, so a support conversation can start from the exact build.
Each platform reads its own numbers at run time:

| | how the app reads its version |
|---|---|
| Android | `packageManager.getPackageInfo(packageName, 0).versionName` |
| iOS | `Bundle.main.infoDictionary?["CFBundleShortVersionString"]` |
| React Native, Expo | `Application.nativeApplicationVersion` from `expo-application` |
