---
title: What needs a Mac, said now
version: 1
---

**An iPhone app is built with Xcode, and Xcode runs on macOS and nowhere else.** Apple's licence for
Xcode and its SDKs allows them on Apple hardware only, and the iOS simulator comes with Xcode. So
does SwiftUI: the framework the screens are written in ships inside the iOS and macOS SDKs and has
no Linux or Windows version. Putting the app on a real iPhone, and lessons 21 and 22, need a paid
Apple Developer Program membership on top. It is better to know all of that in lesson 1 than in
lesson 9.

**And yet most of this course can be practised on any computer.** An app's screens are a thin layer
over its data and its rules, and those are plain Swift. Swift runs on Linux, which is what lesson 20
of `swift` is about, and every lesson here puts its plain-Swift half in a **Swift
package** that builds and tests the same way on Linux and on a Mac. Xcode opens that package
without a change and the app target imports it.

| lessons | what you practise on any computer | what needs a Mac with Xcode |
|---|---|---|
| 1 | the planner's package, its tests, reading an `Info.plist` | the Xcode project, targets and schemes |
| 2 to 5 | the scene phase as a state machine, result builders, a model of layout and of modifiers | every SwiftUI view, the canvas and the simulator |
| 6 to 10 | `Binding` built by hand, `@Observable` itself, identity in lists, navigation paths and deep links, form validation | the screens that use them |
| 11 | the arithmetic of a timing curve | every animation |
| 12 | all of it: `URLSession`, decoding, errors, cancellation, against a server on your machine | nothing |
| 13 | very little | SwiftData, which exists only on Apple systems |
| 14 and 15 | the repository, its tests, an image cache and the memory sums | `AsyncImage` and the views |
| 16 to 19 | scheduling and trigger arithmetic, notification payloads, privacy files, contrast ratios | background tasks, notifications, permission prompts and VoiceOver, on a simulator or a phone |
| 20 | Swift Testing and XCTest, run by `swift test` | UI tests and previews |
| 21 and 22 | a certificate signing request with `openssl` | signing, TestFlight and App Store review, with a paid membership |

**Without a Mac you can still take every lesson.** The SwiftUI halves are then material to read
rather than practice: what the code says, what Apple's documentation says it does, and what to look
for when you do have a Mac. **Those parts are marked in the lessons as not run.** The course was
recorded on a Linux computer, and nothing from Xcode, the simulator, a device, signing or App Store
Connect was run for it. Every transcript you see was produced by a command on that machine, and its
output is pasted as it came back; every SwiftUI listing is code written from Apple's documentation
and shown with no screenshot and no output, because no run produced one.

Apple's own documentation is what those parts lean on, and Apple moves it every year. The course
was written against the documentation as it stood on 30 October 2026, when the current release was
**Xcode 27.1**, and against APIs that iOS 17 and later provide, since the package declares iOS 17 as
its floor. Where a later Xcode has moved a menu, the idea in the lesson is the part that stays.

## Without a Mac, and wanting the Mac half too

Section 03 names the ways to get Xcode, and none of them is free. Two are worth knowing now. An
**iPad with Swift Playgrounds**, which Apple offers at no charge on the App Store, builds and runs SwiftUI apps on the iPad itself. It is the one way to run the screens of this course without a Mac. It is not Xcode, and lessons 1, 20 and 21 describe things it does not have. And a **rented Mac
in a data centre**, by the hour or the month from several companies, is a real Mac you reach over a
remote desktop. Lesson 20 of `react-native` covers a third, which builds an app on rented Macs
without your ever seeing one, and it does nothing for developing against a simulator.
