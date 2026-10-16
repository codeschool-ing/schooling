---
title: XCUITest, the app driven from a second process
version: 1
---

**An XCUITest test does not run inside the app; it runs in a program of its own and drives the app
from outside.** Xcode builds the UI tests into a separate *runner* app and installs it on the
simulator beside yours. The runner launches your app and acts on it through iOS's accessibility
layer. It finds what is on the screen, taps it and reads it, the way a person with a screen reader
would. XCUITest is the UI-testing half of XCTest, Apple's own since 2015.

It is tempting to think of it as Apple's Espresso, since both are the platform owner's native tool.
In the way that matters most it is the opposite. Espresso shares the app's process and can reach
into its objects, as lesson 16 showed, while **an XCUITest test sees only the screen**. In that it
is closer to Appium, lesson 15, and in fact Appium's iOS driver is built on it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"On the Mac, Xcode or xcodebuild builds, installs and starts the tests. Inside the simulator there are two processes: the runner app, TicketsUITests, and Tickets itself. The runner reaches the app only through the accessibility layer, the tree of what is on the screen.\"><defs><marker id=\"f18two-processes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"660\" height=\"210\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the Mac</text><rect x=\"36\" y=\"118\" width=\"140\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"106\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Xcode</text><text x=\"106\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">xcodebuild</text><rect x=\"210\" y=\"56\" width=\"455\" height=\"168\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"224\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the simulator</text><rect x=\"226\" y=\"96\" width=\"160\" height=\"110\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"306\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">a process</text><rect x=\"238\" y=\"128\" width=\"136\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"306\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the runner app</text><text x=\"306\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">TicketsUITests</text><rect x=\"408\" y=\"132\" width=\"104\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">accessibility</text><text x=\"460\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the screen tree</text><rect x=\"532\" y=\"96\" width=\"120\" height=\"110\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"592\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">another process</text><rect x=\"542\" y=\"128\" width=\"100\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"592\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tickets</text><text x=\"592\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the app</text><line x1=\"176\" y1=\"143\" x2=\"236\" y2=\"156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f18two-processes-ah)\"></line><line x1=\"374\" y1=\"156\" x2=\"406\" y2=\"156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f18two-processes-ah)\"></line><line x1=\"512\" y1=\"156\" x2=\"540\" y2=\"156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f18two-processes-ah)\"></line><text x=\"130\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">builds, installs, starts</text><text x=\"350\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the test acts on what the screen shows, and reaches none of the app’s variables</text></svg>", "caption": "An XCUITest test runs in a runner app of its own, beside the app, and reaches it through accessibility, as Appium does."}
```

## Telling the app something

Being outside, the test cannot set a variable in the app the way lesson 16 set `Shows.baseUrl`.
What it can do is start the app with **launch arguments** and **environment variables**, which the
app reads when it starts. The test below sets `BOXOFFICE_URL`. The app's developers read it in
one line of their own and use it instead of the address they ship with. That line is a promise
between the people who build the app and the people who test it, like the ids of lesson 14.

The address is `localhost`, and on iOS that is right. **The simulator is a program on the Mac and
shares the Mac's network**, so `localhost:8080` inside it is boxoffice on the Mac. An Android emulator needed `10.0.2.2` in
lesson 14, and lesson 19 says why the two differ. The app still needs Apple's permission to speak
plain HTTP. iOS refuses it by default, under a rule called *App Transport Security*. An exception
for local addresses goes in the app's settings, the counterpart of lesson 14's network security
file.

## How the app names its elements

**XCUITest finds an element by its accessibility identifier**, which the developers set in the
app's code. It is the iOS counterpart of Android's resource id. The iOS Tickets is not built in
this course. So here is only the part a tester needs to see, from the app's SwiftUI views, and not
a file to save:

```swift
// the list: one button per show, named by the show's id
List(shows, id: \.id) { show in
    Button { selected = show } label: {
        VStack(alignment: .leading) {
            Text(show.title)
            Text("\(show.time) · \(show.price)")
        }
    }
    .accessibilityIdentifier("show-\(show.id)")
}

// the show's screen
VStack(alignment: .leading) {
    Text(show.title).font(.title).accessibilityIdentifier("title")
    Text(show.time).accessibilityIdentifier("time")
    Text(show.price).accessibilityIdentifier("price")
    Text("\(show.seatsLeft) seats left").accessibilityIdentifier("seats")
}
```

Two differences from the Android app are worth noticing. Each row of the list is named after its
show, `show-sh-103`, so a test can open *O Pagador de Promessas* by name instead of as the third
row. That is better than lesson 15's position. It is also the case lesson 15 warned about: **two apps
that name things differently**. One Appium test cannot drive both without a table translating one
name into the other.

The bracket in a query, `app.buttons["show-sh-103"]`, is matched against the identifier and also
against the element's label, the text it shows. So `app.buttons["Refresh"]` finds the button too. That is the trap of lesson 14 again: it
fails the day the word changes, or the phone is set to Portuguese.

## The test

The UI tests belong to the Xcode project of the app, in its UI-test target. Save it as
`ios/Tickets/TicketsUITests/TicketsUITests.swift`:

```swift
// ios/Tickets/TicketsUITests/TicketsUITests.swift
import XCTest

final class TicketsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["BOXOFFICE_URL"] = "http://localhost:8080"
        app.launch()
        return app
    }

    @MainActor
    func testTheListHasEveryShow() throws {
        let app = launch()
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'show-'"))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 15))
        XCTAssertEqual(rows.count, 3)
    }

    @MainActor
    func testAShowOpensWithItsSeats() throws {
        let app = launch()
        let row = app.buttons["show-sh-103"]
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        row.tap()

        let seats = app.staticTexts["seats"]
        XCTAssertTrue(seats.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["title"].label, "O Pagador de Promessas")
        XCTAssertTrue(seats.label.hasSuffix(" seats left"), seats.label)
    }
}
```

```schooling-example
{
 "language": "swift",
 "file": "TicketsUITests.swift",
 "parts": [
  {
   "code": "final class TicketsUITests: XCTestCase {\n    override func setUpWithError() throws {\n        continueAfterFailure = false\n    }",
   "note": "XCTest's shape: a class whose methods starting with `test` are the tests, and `setUpWithError` before each. `continueAfterFailure = false` stops a UI test at its first failure, since every tap after it acts on a screen that is not the one the test expects."
  },
  {
   "code": "    @MainActor\n    private func launch() -> XCUIApplication {\n        let app = XCUIApplication()\n        app.launchEnvironment[\"BOXOFFICE_URL\"] = \"http://localhost:8080\"\n        app.launch()\n        return app\n    }",
   "note": "`XCUIApplication` is the app under test, seen from outside. The environment is set before `launch()`, which starts the app fresh for each test. `@MainActor` is there because Xcode's own template marks UI tests that way: the XCUI calls run on the main thread."
  },
  {
   "code": "        let rows = app.buttons.matching(NSPredicate(format: \"identifier BEGINSWITH 'show-'\"))\n        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 15))\n        XCTAssertEqual(rows.count, 3)",
   "note": "A **query** describes elements and finds them only when asked. `waitForExistence` waits up to 15 seconds for the list to load and answers true or false; it does not fail on its own, which is why it sits inside `XCTAssertTrue`."
  },
  {
   "code": "        let row = app.buttons[\"show-sh-103\"]\n        XCTAssertTrue(row.waitForExistence(timeout: 15))\n        row.tap()",
   "note": "The row by its identifier, waited for, and tapped. XCUITest waits for the app to settle before a tap, as Espresso waits for the main thread, but it knows nothing about a request in flight: the list arriving from boxoffice is exactly that, so the wait is written."
  },
  {
   "code": "        let seats = app.staticTexts[\"seats\"]\n        XCTAssertTrue(seats.waitForExistence(timeout: 5))\n        XCTAssertEqual(app.staticTexts[\"title\"].label, \"O Pagador de Promessas\")\n        XCTAssertTrue(seats.label.hasSuffix(\" seats left\"), seats.label)",
   "note": "The show's screen. `label` is the text the element shows. The seats are checked for their shape, not their number: lesson 15 asked boxoffice for the number, and the Swift version would do the same with a request of its own, left out here to keep the test short."
  }
 ]
}
```

**This test was not built or run for this course**, which has no Mac. Section 02 says so for the
whole lesson. It is written to XCTest's documented API, and the iOS app it tests exists only as the
fragment above.
