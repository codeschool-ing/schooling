---
title: Swift Testing, for the code behind the screens
version: 1
---

**Swift Testing is Apple's framework for testing code, and it does not touch a screen.** A test is
a function marked `@Test`; a check inside it is `#expect`, which records a failure and lets the
test go on, or `#require`, which stops the test where it stands. Apple introduced it in 2024 with
Swift 6 and Xcode 16, beside XCTest, the framework iOS tests had used since 2013. It is the iOS
counterpart of lesson 14's *local tests*: fast, many, and blind to everything the app draws.

The picture to replace is of Swift Testing as the new XCTest, which will one day test everything.
At the time of writing it **does not run UI tests at all**: Xcode's own new-project dialog offers
"Swift Testing with XCTest UI Tests", and the second half of that sentence is section 04. So an iOS
project of today carries both: Swift Testing for the logic, XCTest for the screens.

## The logic of Tickets, in Swift

An iOS Tickets would need the same rules as the Android one: read boxoffice's list, write a price
from whole cents, write a date as the theatre states it. Put in a **Swift package** of their own,
those rules can be tested without the app, without a simulator and, since Swift 6 runs there too,
without a Mac. The package lives in a folder `ios/TicketsCore` of your boxoffice project.

The manifest names one library and its tests. Save it as `ios/TicketsCore/Package.swift`:

```swift
// swift-tools-version: 6.0
// ios/TicketsCore/Package.swift
import PackageDescription

let package = Package(
    name: "TicketsCore",
    targets: [
        .target(name: "TicketsCore"),
        .testTarget(name: "TicketsCoreTests", dependencies: ["TicketsCore"]),
    ]
)
```

The rules, the same three as `Shows.kt` in lesson 14. Save it as
`ios/TicketsCore/Sources/TicketsCore/Show.swift`:

```swift
// ios/TicketsCore/Sources/TicketsCore/Show.swift
import Foundation

/// A show as boxoffice describes it, and the two lines a screen prints from it.
public struct Show: Decodable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let startsAt: String
    public let priceCents: Int
    public let seatsLeft: Int

    enum CodingKeys: String, CodingKey {
        case id, title
        case startsAt = "starts_at"
        case priceCents = "price_cents"
        case seatsLeft = "seats_left"
    }

    /// "R$ 80,00", from whole cents and never through a floating-point number.
    public var price: String {
        let cents = priceCents % 100
        return "R$ \(priceCents / 100)," + (cents < 10 ? "0" : "") + "\(cents)"
    }

    /// "2026-11-06T20:00:00-03:00" becomes "06/11 20:00", the time as the theatre states it.
    public var time: String {
        let c = Array(startsAt)
        return String(c[8...9]) + "/" + String(c[5...6]) + " " + String(c[11...15])
    }
}

/// The body of GET /v1/shows.
public enum ShowList {
    struct Body: Decodable {
        let shows: [Show]
    }

    public static func parse(_ body: Data) throws -> [Show] {
        try JSONDecoder().decode(Body.self, from: body).shows
    }
}
```

`CodingKeys` maps boxoffice's `starts_at` to Swift's `startsAt`, and the price is built from two
whole numbers, for the reason lesson 14 gave: `6500 / 100.0` goes through a floating-point number,
and a cent can be lost on the way.

The tests. Save it as `ios/TicketsCore/Tests/TicketsCoreTests/ShowTests.swift`:

```swift
// ios/TicketsCore/Tests/TicketsCoreTests/ShowTests.swift
import Foundation
import Testing
@testable import TicketsCore

let pagador = Show(id: "sh-103", title: "O Pagador de Promessas",
                   startsAt: "2026-11-08T18:00:00-03:00", priceCents: 6500, seatsLeft: 4)

@Test func priceIsInReais() {
    #expect(pagador.price == "R$ 65,00")
}

@Test("a price keeps every cent", arguments: [
    (8000, "R$ 80,00"),
    (8005, "R$ 80,05"),
    (1999, "R$ 19,99"),
    (5, "R$ 0,05"),
])
func price(cents: Int, shown: String) {
    let show = Show(id: "sh-x", title: "x", startsAt: pagador.startsAt, priceCents: cents, seatsLeft: 1)
    #expect(show.price == shown)
}

@Test func timeIsTheTheatres() {
    #expect(pagador.time == "08/11 18:00")
}

@Test func theListIsReadFromBoxoffice() throws {
    let body = Data(#"{"shows":[{"id":"sh-103","title":"O Pagador de Promessas","starts_at":"2026-11-08T18:00:00-03:00","price_cents":6500,"seats_left":4}]}"#.utf8)
    let shows = try ShowList.parse(body)
    let first = try #require(shows.first)
    #expect(first == pagador)
}

@Test func aBodyWithoutShowsIsRefused() {
    #expect(throws: DecodingError.self) {
        try ShowList.parse(Data("{}".utf8))
    }
}
```

## Reading the tests

```schooling-example
{
 "language": "swift",
 "file": "ShowTests.swift",
 "parts": [
  {
   "code": "import Testing\n@testable import TicketsCore",
   "note": "`Testing` is the framework. `@testable` lets the tests see what the package keeps internal, such as the memberwise initialiser that builds a `Show` by hand."
  },
  {
   "code": "@Test func priceIsInReais() {\n    #expect(pagador.price == \"R$ 65,00\")\n}",
   "note": "A test is any function marked `@Test`: no class to inherit from, no name it must start with. `#expect` takes an ordinary Swift expression and, when it is false, reports both sides of the `==`, so a failure says what the price was."
  },
  {
   "code": "@Test(\"a price keeps every cent\", arguments: [\n    (8000, \"R$ 80,00\"),\n    (8005, \"R$ 80,05\"),\n    (1999, \"R$ 19,99\"),\n    (5, \"R$ 0,05\"),\n])\nfunc price(cents: Int, shown: String) {",
   "note": "A **parameterised** test: one function, run once per pair, each run reported on its own. The pairs are the boundaries a tester would pick for money: a round price, one cent, ninety-nine cents, and less than a real."
  },
  {
   "code": "    let shows = try ShowList.parse(body)\n    let first = try #require(shows.first)\n    #expect(first == pagador)",
   "note": "`shows.first` is an optional: there may be no first show. `#require` unwraps it or stops the test there, because every line after it would be checking nothing. Use `#require` where the rest of the test depends on the answer, and `#expect` everywhere else."
  },
  {
   "code": "@Test func aBodyWithoutShowsIsRefused() {\n    #expect(throws: DecodingError.self) {\n        try ShowList.parse(Data(\"{}\".utf8))\n    }\n}",
   "note": "The negative case: a body with no `shows` must be refused, not read as an empty list. `#expect(throws:)` passes only if the code inside throws that kind of error. Lesson 2 drew negative cases like this one from boxoffice's contract."
  }
 ]
}
```

`#expect` and `#require` are the two halves of what JUnit calls an assertion, and the split is
worth keeping in mind for every framework in this course. A check that fails and lets the test
continue reports **every** wrong field of a show in one run; a check that stops is right only where
continuing would report nonsense, such as the fields of a show that does not exist.

## Running them

From the package's folder, `ios/TicketsCore`, the command is `swift test`, on a Mac or on any
computer with Swift 6; in Xcode, opening `Package.swift` shows the tests in the *Test navigator*
with a button beside each. Section 05 says more. **These tests were not run for this course**: the
recording machine could not download the Swift toolchain, and section 02 says what that means for
everything in this lesson.
