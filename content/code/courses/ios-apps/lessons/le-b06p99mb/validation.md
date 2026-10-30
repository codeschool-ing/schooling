---
title: Validation lives in the package
version: 1
---

**A form is two things that look like one: what the person typed, and the value the app will keep.**
The belief to drop is that a text field holds a number. It holds text, all the time, including the
moment it reads `4` on the way to `45` and the moment it is empty because somebody deleted the old
value to type a new one. Validation is the step that turns the first into the second, or says why it
cannot, and it is plain Swift. So it goes in the planner's package, where it runs and is tested on any
computer, and `SessionForm` only shows what it decides.

This lesson's package is lesson 1's, in a directory of its own, `~/l10`, with one more source file,
one more test file and one more small program. Copy lesson 1's five files into it, then replace
`Package.swift` with this one, which adds the program `draft`:

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
        .executableTarget(name: "draft", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

## The draft

Save this as `Sources/PlannerCore/SessionDraft.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/SessionDraft.swift", "parts": [{"code": "// Sources/PlannerCore/SessionDraft.swift\nimport Foundation\n\n/// What the session form holds while somebody is typing: text, not yet a session.\npublic struct SessionDraft: Equatable, Sendable {\n    public var courseID: String?\n    public var date: Date\n    public var minutesText: String\n\n    public init(courseID: String? = nil, date: Date, minutesText: String = \"\") {\n        self.courseID = courseID\n        self.date = date\n        self.minutesText = minutesText\n    }\n}\n\n", "note": "The form's state is a **draft**: the course picked, the moment the date picker holds, and the minutes as the text somebody typed. None of it is a `StudySession` yet, and keeping the two types apart is what stops a half-typed form from reaching the plan."}, {"code": "public enum DraftProblem: Equatable, Sendable {\n    case noCourse\n    case noMinutes\n    case minutesNotWhole(String)\n    case minutesOutOfRange(Int)\n}\n\n", "note": "The four things that can be wrong, as values. A form can show a message for each, and a test can name exactly which one it expects."}, {"code": "extension SessionDraft {\n    public static let minutesRange = 5...480\n\n    /// Every problem at once, so the form can show them all rather than one per tap.\n    public var problems: [DraftProblem] {\n        var found: [DraftProblem] = []\n        if courseID == nil { found.append(.noCourse) }\n        let text = minutesText.trimmingCharacters(in: .whitespaces)\n        if text.isEmpty {\n            found.append(.noMinutes)\n        } else if let minutes = Int(text) {\n            if !Self.minutesRange.contains(minutes) { found.append(.minutesOutOfRange(minutes)) }\n        } else {\n            found.append(.minutesNotWhole(text))\n        }\n        return found\n    }\n\n", "note": "`problems` collects every problem rather than stopping at the first, so the form can mark both fields at once. Spaces around the number are forgiven; anything `Int` cannot read is refused whole, so `1.5` and `forty` are both `minutesNotWhole`."}, {"code": "    /// The session this draft describes, or nil while it has a problem.\n    public func session(id: String, calendar: Calendar) -> StudySession? {\n        guard problems.isEmpty, let courseID,\n              let minutes = Int(minutesText.trimmingCharacters(in: .whitespaces))\n        else { return nil }\n        return StudySession(id: id, courseID: courseID, date: day(of: date, in: calendar), minutes: minutes)\n    }\n}\n\n", "note": "The one way out of a draft. While anything is wrong there is no session to add, so the Add button has nothing to send."}, {"code": "/// The day a moment falls on, YYYY-MM-DD, in the calendar the person picked it in.\npublic func day(of date: Date, in calendar: Calendar) -> String {\n    let c = calendar.dateComponents([.year, .month, .day], from: date)\n    return String(format: \"%04d-%02d-%02d\", c.year!, c.month!, c.day!)\n}\n", "note": "The date picker hands over an instant. Which day that instant is depends on the calendar it is read in, so the caller passes the person's own; section 05 shows what goes wrong otherwise."}]}
```

**Every problem is a value, never a sentence.** `DraftProblem.minutesOutOfRange(600)` says what is
wrong and carries the number; the words the person reads are the form's business, in their language,
and lesson 19 is where they are also read aloud by VoiceOver. A validator that returned
`"Minutes must be between 5 and 480"` would tie the rule to one language and leave a test comparing
English sentences.

The range, 5 to 480 minutes, is the planner's own decision: under five is a typo more often than a
session, and eight hours is a day. The other platforms' planners use the same bounds, so the three
apps refuse the same input.

## The tests

Save this as `Tests/PlannerCoreTests/DraftTests.swift`, beside lesson 1's `PlanTests.swift`:

```swift
// Tests/PlannerCoreTests/DraftTests.swift
import Foundation
import Testing
@testable import PlannerCore

let picked = ISO8601DateFormatter().date(from: "2026-10-21T23:30:00-03:00")!

@Test func spacesAroundTheNumberAreForgiven() {
    for typed in ["30", " 30", "30 "] {
        #expect(SessionDraft(courseID: "sql", date: picked, minutesText: typed).problems.isEmpty)
    }
}

@Test func everyProblemIsReportedAtOnce() {
    let draft = SessionDraft(courseID: nil, date: picked, minutesText: "lots")
    #expect(draft.problems == [.noCourse, .minutesNotWhole("lots")])
}

@Test func theDayIsTheOneThePersonSaw() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    let draft = SessionDraft(courseID: "sql", date: picked, minutesText: "45")
    #expect(draft.session(id: "s6", calendar: calendar)?.date == "2026-10-21")
}
```

```
ana@vm:~/l10$ swift test
Building for debugging...
[Provisioning 1 / 7]
[Pre-planning 1 / 182]
[Starting]
[40 / 71] PlannerCore
[48 / 75] draft-product
[51 / 77] week-product
[54 / 78] week-product
[65 / 85] PlannerCoreTests-product
[69 / 85] draft-product
[75 / 86] PlannerCoreTests-product
[78 / 86] PlannerCoreTests-product
[82 / 89] PlannerCoreTests-test-runner
[90 / 90] PlannerCoreTests-test-runner
Build complete! (7.47 secs)
Test Suite 'All tests' started at 2026-10-30 15:22:41.786
Test Suite 'Debug-linux-x86_64.xctest' started at 2026-10-30 15:22:41.788
Test Suite 'Debug-linux-x86_64.xctest' passed at 2026-10-30 15:22:41.788
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.0 (0.0) seconds
Test Suite 'All tests' passed at 2026-10-30 15:22:41.788
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.0 (0.0) seconds
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test spacesAroundTheNumberAreForgiven() started.
◇ Test mondayIsTheStartOfTheWeek() started.
◇ Test theDayIsTheOneThePersonSaw() started.
◇ Test everyProblemIsReportedAtOnce() started.
◇ Test aSessionForNoCourseIsRefused() started.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.002 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.002 seconds.
✔ Test everyProblemIsReportedAtOnce() passed after 0.003 seconds.
✔ Test spacesAroundTheNumberAreForgiven() passed after 0.004 seconds.
✔ Test theDayIsTheOneThePersonSaw() passed after 0.004 seconds.
✔ Test run with 5 tests in 0 suites passed after 0.004 seconds.
```

Five tests: lesson 1's two and these three. The second is the one that pays for itself. **A form that
reports one problem at a time makes a person tap Add once per mistake**, and a test that compares the
whole list is what stops a later change from quietly returning after the first.
