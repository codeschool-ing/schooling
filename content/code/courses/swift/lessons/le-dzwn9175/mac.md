---
title: What a Mac adds
version: 1
---

Everything in this course ran on Linux. **This section is the exception: it describes, from Apple's
documentation, what a Mac adds, and none of it was run**, because the course was recorded on a
machine with no Mac and there is no way to run Apple's tools anywhere else. There is no transcript
below and no screenshot, on purpose.

## The same toolchain, and more around it

On a Mac, Swift arrives with **Xcode**, Apple's IDE, or with the smaller **Command Line Tools**. Both
put `swift` and `swiftc` on the `PATH`, and every command of this course works there as written:
`swift Hello.swift`, `swift build`, `swift test`, `swift package init`. The differences you would see
are the ones lesson 1 listed: paths, the target line of `swift --version`, which on a recent Mac starts
with `arm64-apple-macosx` rather than `x86_64-unknown-linux-gnu`, and the absence of the `FoundationNetworking`
dance of section 03.

What Xcode adds is everything that is not the language:

| on a Mac | what it does | nearest thing in this course |
|---|---|---|
| **Xcode projects** | an app's targets, schemes, bundle identifier and `Info.plist` | a package, lesson 19 |
| **the iOS simulator** | runs an iPhone app on the Mac, at a chosen device size | none: it exists only on macOS |
| **SwiftUI previews** | redraws a view in the editor as the code changes | none; lesson 16 built the mechanisms SwiftUI uses |
| **Instruments** | measures time, allocations and leaks in a running app | lesson 11's `deinit` counting |
| **the memory graph debugger** | draws the objects alive in a paused app and the references between them | lesson 11's cycle, found by reasoning |
| **signing and the App Store** | certificates, provisioning profiles, TestFlight, review | none |

## Why the wall is there

Not because of Swift. **Xcode and the Apple SDKs are licensed to run on Apple hardware**, and the
simulator and the frameworks it runs, UIKit and SwiftUI among them, are part of that SDK. No Linux
build of them exists, and none is promised. That is why the course after this one on the path,
`ios-apps`, says in its prerequisites that it needs a Mac with Xcode from its first lesson, and why
this course was designed to end before it.

Two things blur the line without removing it. Several companies rent remote Macs by the hour, and
`react-native` lesson 20 and `mobile-delivery` lesson 10 describe hosted build services that compile and sign an iOS
app without a Mac in the room. Both still run Xcode, on somebody else's Mac. What neither gives you
is a simulator on your own screen to develop against, and that is the part `ios-apps` relies on.

## What carries over unchanged

**Every concept of these twenty lessons**, which is the point of having learned them first. An iPhone
app's models are structs and enums; its screens are SwiftUI views, which are structs conforming to a
protocol, built by a result builder and holding state in property wrappers; its network calls are
`async` functions returning `Codable` values; its UI runs on the `@MainActor` of lesson 15; and its
tests are the XCTest and Swift Testing of lesson 18. Section 07 maps them one by one.
