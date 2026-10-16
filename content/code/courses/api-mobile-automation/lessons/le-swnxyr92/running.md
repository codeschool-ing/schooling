---
title: Running iOS tests, by hand and in a pipeline
version: 1
---

**Xcode runs a test from a button, `xcodebuild` runs the same tests from a terminal, and both need
a Mac.** The first is for writing a test, the second for a pipeline, the same split lesson 16 made
between Android Studio and Gradle. Nothing in this section was run for this course, and no output
is shown for any of it.

## In Xcode

Choose a simulator in the toolbar at the top of the window, an iPhone model with an iOS version
beside it. *Product › Test*, or Command-U, builds the app and its tests and starts that simulator. It
runs every test the project has, Swift Testing and XCTest alike. The *Test navigator* lists them,
with a diamond beside each test and each class that runs just that one when pressed. A failure
shows its message on the line that failed, and the *Report navigator* keeps every run.

## On the command line

The simulators Xcode installed are listed by `simctl`, its tool for them, and a run names one by
model:

```sh
xcrun simctl list devices available
xcodebuild test -project Tickets.xcodeproj -scheme Tickets \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -resultBundlePath build/Tickets.xcresult
```

- `-scheme` names what to build and which tests come with it. A new project has one scheme,
  named after the app.
- `-destination` says where to run. The name must be a simulator that `simctl` listed. Which
  iPhones exist depends on the Xcode version, so `iPhone 16` is an example and not a promise.
- `-resultBundlePath` writes the run's results and logs into one bundle, `Tickets.xcresult`. Xcode
  opens it, and a CI server can keep it as an artefact.
- `-only-testing:TicketsUITests/TicketsUITests/testAShowOpensWithItsSeats` runs one test, named as
  target, class and method.

`xcodebuild` exits with a non-zero code when a test fails, which is all a pipeline needs from it,
as lesson 6 said of Newman. The Swift package of section 03 needs none of this. `swift test` in
`ios/TicketsCore` builds and runs its tests, on a Mac or on Linux or Windows with Swift 6.

## In a pipeline

A pipeline for iOS UI tests needs a macOS machine, and that is the expensive part. **Hosted CI
services charge more for a macOS minute than for a Linux one, several times as much at the time of
writing.** A macOS machine is also slower to get and to start. The prices and the multiples change,
so check the service's own page rather than any number in a course.

That cost pushes the suite into the shape lesson 14 drew for Android, and more steeply. Many Swift
Testing tests on the logic, which can run on the cheap Linux machines. Fewer XCUITest tests, each
one there because a person's path through the screens needs it. And real iPhones only where the
simulator is known to hide something, which is lesson 19's subject.
