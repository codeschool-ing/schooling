---
title: Two platforms, two owners
version: 1
---

**A phone runs one of two operating systems, and who owns each one explains most of the
differences you will meet.** Android is made by Google and given away: its source is published as
the Android Open Source Project, and hundreds of manufacturers build phones on it, from the cheapest
handset in a market stall to a folding tablet. iOS is made by Apple for the iPhone, and only Apple
makes iPhones. One company writes the system, designs the hardware and runs the only store most
users will ever see.

The common picture is that the two are rivals doing the same job in different colours. The job is
the same, and so are most of the rules this course teaches. **The ownership is not**, and it decides
three things a developer feels every week:

| | Android | iOS |
|---|---|---|
| who makes the devices | many manufacturers, at every price | Apple alone |
| how the system is updated | the manufacturer decides when, and for how long | Apple ships each release to every supported iPhone at once |
| where apps come from | Google Play, other stores, and a file the user installs | the App Store; in the European Union, also the alternative marketplaces Apple allowed from 2024 |

**Updates are the one with the longest reach.** When Apple releases a new iOS, most iPhones that
can take it receive it the same day. An Android release reaches a phone when its manufacturer
adapts it, and some phones never get it at all. So an Android app supports a range of system
versions at once, and declares the oldest it will run on as its *minimum SDK*; an iOS app supports a
shorter range and drops old versions sooner. The `android-apps` course sets that number in its
lesson 1, and `ios-apps` sets the iOS one in its own lesson 1.

**The languages follow the owners.** Google recommends **Kotlin** for Android, with Java still
supported, and draws screens with **Jetpack Compose**. Apple's language is **Swift**, with
Objective-C behind it, and its screens are drawn with **SwiftUI** or the older UIKit. Neither
platform runs the other's code. That is why the track forks after this course: you choose one
language and one toolkit, or a third route that writes one app for both, and lesson 2 lays the
three side by side.

**The tools follow the owners too, and this is the one that costs money.** Android Studio, Google's
editor, runs on Windows, macOS and Linux. Xcode, the only tool that builds an iOS app, runs on macOS
alone, so building for the iPhone needs a Mac. A section further down in this lesson says what that
means for this course, which is nothing, and for the ones after it.
