---
title: UI tests, the app driven from outside
version: 1
---

**A UI test launches the real app and works it the way a person would: it finds a button by what the
button says, taps it, and checks what appears.** It runs in a separate process, knows nothing of the
app's code, and sees only what accessibility exposes. That makes it the one test that catches a
screen that compiles, passes every unit test and still cannot be used. It also makes it slow and the
easiest to break, so a project keeps few. Nothing in this section was run: UI tests need Xcode and a
simulator. It is written from Apple's documentation for `XCUIApplication` and `XCUIElement`, read on
30 October 2026.

```swift
// PlannerUITests/AddSessionUITests.swift
import XCTest

final class AddSessionUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAddingASessionShowsItInTheWeek() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["SQL Databases"].tap()
        app.buttons["Add session"].tap()
        let minutes = app.textFields["Minutes"]
        minutes.tap()
        minutes.typeText("45")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["45 minutes"].waitForExistence(timeout: 2))
    }
}
```

**The test finds elements by their accessibility labels**, the ones lesson 19 wrote. A button labelled
for VoiceOver is a button a UI test can find; a tappable `Text` from lesson 19 section 03 is invisible
to both. Where a label is not stable, a sentence that changes with the language, SwiftUI's
`.accessibilityIdentifier("addSession")` gives the element a name for tests that VoiceOver never reads.

## Three things that make UI tests worth having

- **Start from a known state.** `launchArguments` reaches the app, and the app checks for
  `-ui-testing` at start-up and loads a fixed plan instead of the person's. Without it, a UI test
  depends on whatever the simulator was left holding by the last run.
- **Wait, do not sleep.** `waitForExistence(timeout:)` returns as soon as the element appears and
  fails after the timeout. A fixed sleep is either too short on a slow machine or wasted time on a
  fast one.
- **`continueAfterFailure = false`.** After a failed tap, every later step fails for the same reason,
  and the report buries the first failure under the others.

**Keep the flows few and important**: adding a session, marking one done, the week's total changing.
Everything that is arithmetic is already a unit test in the package, where it runs in milliseconds
on any computer. A UI test that checks a sum checks it slowly, and only on a Mac.
