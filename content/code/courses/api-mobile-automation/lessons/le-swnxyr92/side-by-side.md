---
title: Espresso, XCUITest and Appium side by side
version: 1
---

**The three tools differ less in what they can test than in where their code runs, and everything
else follows from that.** Espresso is inside the Android app. XCUITest is beside the iOS app in a
process of its own. Appium is on a computer, talking to a driver that talks to the device. The
table puts lessons 15, 16 and this one in one place:

| | Espresso (lesson 16) | XCUITest | Appium (lesson 15) |
|---|---|---|---|
| **platform** | Android | iOS | both, with a driver for each |
| **where the test code runs** | on the device, in the app's process | on the device, in a runner app beside the app | on a computer, in its own process |
| **how it reaches the app** | holds the app's views directly | the accessibility layer | W3C WebDriver over HTTP, then the driver: UiAutomator2 on Android, XCUITest on iOS |
| **what it can name** | the screen, and the app's own classes | the screen, by accessibility identifier or label | the screen, by resource id, accessibility id or text |
| **what it waits for** | the main thread, by itself; anything else through an idling resource | the app settling, by itself; anything else with a written wait | nothing by itself; every wait is written |
| **the system's own screens** | no: only the app's windows | yes, by addressing the system as another app | yes, it sees the whole screen |
| **language** | Kotlin or Java, the app's | Swift or Objective-C, the app's | any language with a WebDriver client |
| **what it needs** | Android Studio or Gradle | a Mac with Xcode | a Mac too, for iOS; the Android SDK for Android |
| **who usually writes it** | the app's developers | the app's developers | testers, often for both apps at once |

**The common belief is that Appium is slower because it is "not native".** The reason is more
precise and more useful. Every step an Appium test takes is an HTTP request to a server, which asks
a driver. On iOS the driver asks WebDriverAgent, which is itself an XCUITest runner. So an Appium test on
iOS does everything an XCUITest test does, plus a network hop and a server for each step. It buys
one suite and one language for two platforms with that time.

## Choosing, for a team

A team with one Android app and one iOS app, each written natively, usually ends up with all of
them, at different heights of the pyramid:

- the logic tested where it lives, with local tests on Android and Swift Testing on iOS, by the
  developers, by the hundred;
- each app's screens tested with its own platform's tool, Espresso or XCUITest, by the developers,
  because those tools are fast and live in the app's own project;
- a smaller suite of journeys through both apps, such as finding a show and opening it, written
  once in Appium by the testers. The journey is the same on both phones, and one suite costs less to
  keep than two.

That last suite works only if the two apps name their elements the same way. Section 04 showed
that is not automatic: Tickets on Android has rows called `title`, and on iOS rows called
`show-sh-103`. **Agreeing on the names is a request a tester makes of both teams**, early. It is
the cheapest test-automation work there is.
