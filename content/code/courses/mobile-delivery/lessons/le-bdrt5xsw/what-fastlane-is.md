---
title: What Fastlane is
version: 1
---

**Fastlane is a command-line tool that runs the steps of a mobile release from one file, in the
same order, on any machine.** It is open source, written in Ruby, and has an **action** for nearly
everything a release does: build with Gradle or Xcode, take screenshots, sign, upload a build,
upload the listing, post a message. A **lane** is a named sequence of actions, written in a file
called `Fastfile`.

## The actions this course meets

| action | what it does | platform | the lesson it replaces by hand |
|---|---|---|---|
| `gradle` | runs a Gradle task, such as `bundleRelease` | Android | lesson 1's build |
| `build_app`, also called `gym` | archives and exports an iOS build with Xcode | iOS | lesson 2's signing |
| `match` | fetches the team's certificates and profiles from an encrypted repository | iOS | lesson 2 |
| `upload_to_play_store`, also called `supply` | uploads a bundle, the listing and release notes to a track | Android | lessons 4 and 7 |
| `upload_to_app_store`, also called `deliver` | uploads the listing, screenshots and a build for review | iOS | lessons 4 and 6 |
| `upload_to_testflight`, also called `pilot` | uploads a build to TestFlight and manages testers | iOS | lesson 7 |
| `capture_android_screenshots`, `capture_ios_screenshots` | screenshots from UI tests, per device and language | both | lesson 4 |
| `sh` | runs any shell command | both | everything else |

## Why a team uses it rather than a shell script

A release could be a shell script, and the pipeline of lesson 10 is mostly one. Fastlane earns its
place in three ways: its **store actions** speak the stores' APIs, which a shell script would have
to call by hand; its **listing layout**, one folder per language and one file per field, is the
format both upload actions read; and its **lanes** run the same on a laptop and in a pipeline, so
the release a person can run is the release CI runs.

## On the three platforms

A Kotlin team uses the Android half, a Swift team the iOS half, and a React Native team both, in one
`Fastfile` with a `platform :android` block and a `platform :ios` block. Expo projects often use
**EAS Submit** instead for the upload step, which does the same job as `supply` and `deliver` from
Expo's servers; Fastlane remains the common choice for everything around it.
