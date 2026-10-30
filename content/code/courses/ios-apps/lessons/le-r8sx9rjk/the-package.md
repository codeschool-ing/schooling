---
title: The planner's core, as a Swift package
version: 1
---

**Every lesson in this course works on one app: a study planner.** A student lists the courses
they are taking, opens one, adds study sessions with a date and a length in minutes, marks them
done, and sees how much of the week's plan they have finished. It is the app the `frontend` track
builds in a browser, and `android-apps` and `react-native` build the same one, with the same
screens and the same data, so the last lesson of each can compare like with like.

The app has two halves, and they live in two places. **The screens are SwiftUI, and only Xcode
builds them.** The data and the sums every screen shows are plain Swift, and they go in a
**Swift package**: a directory with a manifest, `Package.swift`, that the `swift` command builds
and tests on Linux and that Xcode opens on a Mac without a single change. This section builds the
package. Section 06 shows how the app target uses it.

## The layout

A package is a convention about directories. `Sources/<target>/` holds a target's code and
`Tests/<target>/` its tests, and the manifest names the targets. Make the directories:

```
ana@vm:~$ mkdir -p planner/Sources/PlannerCore planner/Sources/week planner/Tests/PlannerCoreTests
ana@vm:~$ cd planner
```

Save this as `Package.swift` in `~/planner`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Planner",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "week", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

**The first line is not a comment, whatever it looks like.** `swift-tools-version: 6.0` tells
the toolchain which version of the manifest format this file is written in, and with it the
Swift 6 language mode, where the compiler refuses a data race rather than warning about it.
`platforms` is read only when the package is built for an Apple system: iOS 17 is the first
version with the `@Observable` macro lesson 7 uses and with SwiftData, which lesson 13 needs. On
Linux it is ignored.

Three targets. `PlannerCore` is the library the app will import. `week` is a small command-line
program that prints a week's total, so you can see the library work. `PlannerCoreTests` is its
tests.

## The core

Save this as `Sources/PlannerCore/Plan.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Plan.swift", "parts": [{"code": "// Sources/PlannerCore/Plan.swift\nimport Foundation\n\npublic struct Course: Identifiable, Hashable, Sendable {\n    public let id: String\n    public var title: String\n\n    public init(id: String, title: String) {\n        self.id = id\n        self.title = title\n    }\n}\n", "note": "A course is a value with an `id` that never changes and a `title` that may. Everything else in the planner points at a course by its `id`, so renaming one loses nothing. `public` is what lets the app, a different module, see it."}, {"code": "public struct StudySession: Identifiable, Hashable, Sendable {\n    public let id: String\n    public let courseID: String\n    public var date: String  // YYYY-MM-DD\n    public var minutes: Int\n    public var done: Bool\n\n    public init(id: String, courseID: String, date: String, minutes: Int, done: Bool = false) {\n        self.id = id\n        self.courseID = courseID\n        self.date = date\n        self.minutes = minutes\n        self.done = done\n    }\n}\n", "note": "`StudySession` rather than `Session`, because lesson 12 brings `URLSession` into the same files and two things called session is one too many. The date is a day written as text, the way the planner stores it on every platform; further down, this section says why a `Date` would be the wrong type here."}, {"code": "public enum PlanError: Error, Equatable {\n    case unknownCourse(String)\n    case unknownSession(String)\n}\n\npublic struct WeekTotal: Equatable, Sendable {\n    public let monday: String\n    public let planned: Int\n    public let done: Int\n}\n", "note": "The two ways a change can name something that is not there, as an error the caller has to handle. A `WeekTotal` is the one sum every screen shows: minutes planned and minutes done in one week."}, {"code": "public struct Plan: Sendable {\n    public var courses: [Course]\n    public var sessions: [StudySession]\n\n    public init(courses: [Course] = [], sessions: [StudySession] = []) {\n        self.courses = courses\n        self.sessions = sessions\n    }\n\n    public mutating func add(_ session: StudySession) throws(PlanError) {\n        guard courses.contains(where: { $0.id == session.courseID }) else {\n            throw .unknownCourse(session.courseID)\n        }\n        sessions.append(session)\n    }\n\n    public mutating func markDone(_ id: String) throws(PlanError) {\n        guard let i = sessions.firstIndex(where: { $0.id == id }) else {\n            throw .unknownSession(id)\n        }\n        sessions[i].done = true\n    }\n", "note": "A session for a course that does not exist is refused, and so is marking one that does not exist. `throws(PlanError)` is a typed throw: the caller knows the only error it can get. `mutating` is how a method on a struct says it changes the value it was called on."}, {"code": "    public func weekTotal(today: String) -> WeekTotal {\n        let monday = mondayOf(today)\n        let week = sessions.filter { mondayOf($0.date) == monday }\n        let planned = week.reduce(0) { $0 + $1.minutes }\n        let done = week.filter(\\.done).reduce(0) { $0 + $1.minutes }\n        return WeekTotal(monday: monday, planned: planned, done: done)\n    }\n}\n", "note": "`today` is an argument and not the clock, so the same plan always gives the same answer and a test can pin it. `\\.done` is a key path used as a function: keep the sessions whose `done` is true."}]}
```

**A `Plan` is a value.** It is a `struct`, so assigning it copies it and `mutating` methods change
only the copy they were called on. Lesson 6 leans on that: a screen holds one plan, and a change
made to a copy somewhere else cannot reach it by accident.

The week starts on Monday, and finding the Monday of a day is the only calendar arithmetic the
planner does. Save this as `Sources/PlannerCore/Days.swift`:

```swift
// Sources/PlannerCore/Days.swift
import Foundation

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// The Monday of the week `day` falls in. Both are YYYY-MM-DD.
public func mondayOf(_ day: String) -> String {
    let parts = day.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3,
          let date = utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    else { preconditionFailure("not a day: \(day)") }
    let weekday = utc.component(.weekday, from: date)  // Sunday 1 ... Saturday 7
    let back = (weekday + 5) % 7                         // Monday 0 ... Sunday 6
    let monday = utc.date(byAdding: .day, value: -back, to: date)!
    let c = utc.dateComponents([.year, .month, .day], from: monday)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}
```

**The calendar is fixed to UTC on purpose.** A day like `2026-10-19` has no time and no zone. If
the code read it in the phone's own zone, the same plan could put a session in one week in São
Paulo and the next in Tokyo. Pinning one calendar makes the answer a property of the text.

`preconditionFailure` stops the program on a day that is not a day. That is a bug in the caller,
and lesson 10 is where text a person typed gets checked before it gets this far.

## Something to run

Save this as `Sources/week/main.swift`. It builds the plan for the week of Monday 19 October 2026,
changes it twice and prints the week's total. It is given "today" rather than reading the clock,
so it prints the same numbers whenever you run it:

```swift
// Sources/week/main.swift
import PlannerCore

var plan = Plan(
    courses: [
        Course(id: "sql", title: "SQL Databases"),
        Course(id: "mobile", title: "Mobile Fundamentals"),
    ],
    sessions: [
        StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true),
        StudySession(id: "s2", courseID: "mobile", date: "2026-10-20", minutes: 40, done: true),
        StudySession(id: "s3", courseID: "sql", date: "2026-10-23", minutes: 60),
        StudySession(id: "s4", courseID: "mobile", date: "2026-10-27", minutes: 45),
    ]
)

try plan.add(StudySession(id: "s5", courseID: "mobile", date: "2026-10-22", minutes: 30))
try plan.markDone("s5")
print(plan.weekTotal(today: "2026-10-21"))
```

## And a test that holds it there

A program you read the output of is a check you have to repeat by eye. A test repeats it for you.
Save this as `Tests/PlannerCoreTests/PlanTests.swift`, the last of the five files:

```swift
// Tests/PlannerCoreTests/PlanTests.swift
import Testing
@testable import PlannerCore

@Test func mondayIsTheStartOfTheWeek() {
    #expect(mondayOf("2026-10-21") == "2026-10-19")
    #expect(mondayOf("2026-10-19") == "2026-10-19")
    #expect(mondayOf("2026-10-25") == "2026-10-19")  // a Sunday
}

@Test func aSessionForNoCourseIsRefused() {
    var plan = Plan(courses: [Course(id: "sql", title: "SQL Databases")])
    #expect(throws: PlanError.unknownCourse("art")) {
        try plan.add(StudySession(id: "s1", courseID: "art", date: "2026-10-19", minutes: 30))
    }
    #expect(plan.sessions.isEmpty)
}
```

`import Testing` is **Swift Testing**, the framework the Swift 6 toolchain ships on every
platform. Lesson 20 compares it with XCTest, which Xcode projects have used since before it
existed. The Sunday line is the one worth having: `(weekday + 5) % 7` is easy to get wrong by one,
and a Sunday is where being wrong by one shows.

## Build, run, test

```
ana@vm:~/planner$ find Sources Tests -type f | sort
Sources/PlannerCore/Days.swift
Sources/PlannerCore/Plan.swift
Sources/week/main.swift
Tests/PlannerCoreTests/PlanTests.swift
ana@vm:~/planner$ swift build
Building for debugging...
[Pre-planning 1 / 95]
[Describing: 12 / 192]
[26 / 38] PlannerCore
[35 / 41] week-product
[38 / 42] PlannerCore
[43 / 43] week-product
Build complete! (5.34 secs)
ana@vm:~/planner$ .build/debug/week
WeekTotal(monday: "2026-10-19", planned: 180, done: 120)
```

`swift build` compiles the package into `.build/debug/`, and `week` is the program it made there.
The first build compiles everything; the next ones compile only what changed. (`swift run week`
does both steps in one command.) **Wednesday the 21st is in the week that starts on Monday the
19th**, so the four sessions from the 19th to the 23rd count and `s4`, on the 27th, does not: 50 +
40 + 60 + 30 is 180 minutes planned, and the three done are 120.

```
ana@vm:~/planner$ swift test
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[13 / 28] PlannerCoreTests-product
[17 / 28] PlannerCoreTests-product
[21 / 29] PlannerCoreTests-product
[25 / 32] PlannerCoreTests-test-runner
[29 / 32] PlannerCoreTests-test-runner
[33 / 33] PlannerCoreTests-test-runner
Build complete! (2.96 secs)
Test Suite 'All tests' started at 2026-10-30 15:05:17.548
Test Suite 'Debug-linux-x86_64.xctest' started at 2026-10-30 15:05:17.549
Test Suite 'Debug-linux-x86_64.xctest' passed at 2026-10-30 15:05:17.549
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.0 (0.0) seconds
Test Suite 'All tests' passed at 2026-10-30 15:05:17.549
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.0 (0.0) seconds
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aSessionForNoCourseIsRefused() started.
◇ Test mondayIsTheStartOfTheWeek() started.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.001 seconds.
✔ Test run with 2 tests in 0 suites passed after 0.002 seconds.
```

The test run prints two reports. The first is XCTest's, which found no XCTest tests in this package
and says so; the second is Swift Testing's, which found two and passed both. They started in one
order and finished in another because Swift Testing runs tests in parallel unless told otherwise,
and a test that depends on another having run first is a test that fails on some days.
