---
title: Why every iOS test needs a Mac
version: 1
---

**Every tool that builds an iOS app or runs its tests on a screen runs on macOS, and on nothing
else.** Xcode, Apple's development environment, is published for the Mac only. The iOS Simulator
is part of Xcode. The two frameworks this lesson is about, Swift Testing and XCUITest, are run by
Xcode or by its command-line twin, `xcodebuild`. And macOS itself may only be installed on Apple's
own computers, under the licence Apple publishes with it. A virtual Mac on a Windows laptop is not a
route this course can recommend.

The belief this corrects is a hopeful one: that some tool, Appium perhaps, opens iOS to a Windows
or Linux computer. It does not. Lesson 15's test names `platformName: iOS` from any computer. But
the Appium server it talks to must run on a Mac with Xcode. Its XCUITest driver builds and runs
WebDriverAgent there, a test runner made with Apple's XCUITest. **The client can be anywhere; the machine that touches the
iPhone is always a Mac.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 298\" role=\"img\" aria-label=\"Three nested regions. The outer one is any computer with Swift 6, macOS, Linux or Windows: Swift Testing tests of the logic behind the screens run there, and so does the code of an Appium client. Inside it, a Mac with Xcode: the iOS Simulator, which is part of Xcode, XCUITest on the simulator, and the Appium server when the app is iOS. Inside that, an iPhone and an Apple Account: a build that Xcode signs for your phone, and the phone switched to Developer Mode.\"><rect x=\"20\" y=\"30\" width=\"660\" height=\"240\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">any computer with Swift 6: macOS, Linux or Windows</text><rect x=\"36\" y=\"92\" width=\"176\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"124\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Swift Testing</text><text x=\"124\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the logic behind the screens</text><rect x=\"36\" y=\"168\" width=\"176\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"124\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">an Appium client</text><text x=\"124\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the test's own code</text><rect x=\"228\" y=\"58\" width=\"436\" height=\"198\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"242\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a Mac with Xcode</text><rect x=\"244\" y=\"92\" width=\"180\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"334\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the iOS Simulator</text><text x=\"334\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">part of Xcode</text><rect x=\"244\" y=\"146\" width=\"180\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"334\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">XCUITest</text><text x=\"334\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the app on a simulator</text><rect x=\"244\" y=\"200\" width=\"180\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"334\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the Appium server</text><text x=\"334\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">when the app is iOS</text><rect x=\"440\" y=\"86\" width=\"210\" height=\"158\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"454\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">and an iPhone, an Apple Account</text><rect x=\"454\" y=\"124\" width=\"182\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a signed build</text><text x=\"545\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Xcode signs it for your phone</text><rect x=\"454\" y=\"184\" width=\"182\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Developer Mode</text><text x=\"545\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">switched on in the phone</text><text x=\"350\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">each box needs everything around it: an iPhone test needs the Mac as well</text></svg>", "caption": "What each level of iOS testing needs. Only the outer ring is open to a computer that is not a Mac."}
```

## What each level needs

- Code without a screen. The rules behind the screens, such as how a price is written or how
  boxoffice's answer is read, can be tested with Swift Testing wherever Swift 6 runs. That is macOS,
  Linux and Windows, with the toolchain from swift.org. Section 03 writes those tests.
- The app on a simulator. A Mac with Xcode installed from the Mac App Store, free. The simulator
  runs the app, and XCUITest drives it. Lesson 19 says what a simulator is and what it hides.
- The app on a real iPhone. The Mac, plus an Apple Account signed in to Xcode, plus the phone
  connected and switched to *Developer Mode* in its settings. iOS has asked for that since iOS
  16. Every app that runs on an iPhone is **signed**, and Xcode signs your build for your own phone.
  At the time of writing, a free Apple Account can do that for a device of your own, with limits on
  how long the signature lasts. Handing the app to testers through TestFlight, or publishing it,
  needs a paid membership of the Apple Developer Program, on terms Apple sets and changes.

**A Mac does not have to be on your desk.** Hosted CI services rent macOS machines by the minute.
Lesson 20's device clouds offer real iPhones over the network. Some companies rent whole Macs in a
data centre. All of them run on Apple hardware, which is what the licence asks.

## What this lesson does, and does not

**Nothing in this lesson was run.** The course was recorded on a Linux machine with no Mac within
reach. The Swift toolchain could not be downloaded there either, so not even the Swift Testing
tests of section 03 were compiled. Every Swift file in this lesson is written against the APIs
Apple documents, and is short on purpose so that each line can be read. No output, report or
screenshot of it is shown, because none was made.

Without a Mac, this lesson lets you read an iOS suite and review one. You can write the cases it
should contain and talk about it with the developers who run it. If you have a Mac, every file here
is meant to be typed in and run, and section 05 says how.
