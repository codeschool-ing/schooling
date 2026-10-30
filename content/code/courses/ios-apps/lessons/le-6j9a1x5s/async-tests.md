---
title: Async tests, and a source that fails on purpose
version: 1
---

**An async function is tested by an async test, and Swift Testing needs nothing else to run one.**
The test function is marked `async`, it `await`s the code, and the framework waits for it. What makes
async code hard to test is not the waiting: it is that the real source of its data, a server or a
disk, is slow, changes, and fails when it likes. So the code is written against a **protocol**, and
the test hands it a source it controls.

This file is new in the package, and lesson 14 builds the planner's real repository on the same idea.
Save it as `Sources/PlannerCore/Loading.swift`:

```swift
// Sources/PlannerCore/Loading.swift
/// Anything that can hand over a plan, sooner or later: a file, a server, a test.
public protocol PlanSource: Sendable {
    func load() async throws -> Plan
}

/// The week's total of whatever the source holds.
public func loadWeek(from source: some PlanSource, today: String) async throws -> WeekTotal {
    let plan = try await source.load()
    return plan.weekTotal(today: today)
}
```

`some PlanSource` means any type that conforms, chosen by the caller and fixed at compile time.
`Sendable` is there because an async function may run on another thread, and Swift 6 refuses to pass
a value across threads unless its type says that is safe.

Two sources for the tests: one that returns a fixed plan, and one that always fails. Save this as
`Tests/PlannerCoreTests/LoadingTests.swift`:

```swift
// Tests/PlannerCoreTests/LoadingTests.swift
import Testing
@testable import PlannerCore

struct FixedSource: PlanSource {
    let plan: Plan
    func load() async throws -> Plan { plan }
}

struct Offline: Error, Equatable {}

struct FailingSource: PlanSource {
    func load() async throws -> Plan { throw Offline() }
}

@Test func aLoadedWeekIsSummed() async throws {
    let source = FixedSource(plan: Plan(
        courses: [Course(id: "sql", title: "SQL Databases")],
        sessions: [StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true)]
    ))
    let total = try await loadWeek(from: source, today: "2026-10-21")
    #expect(total == WeekTotal(monday: "2026-10-19", planned: 50, done: 50))
}

@Test func aFailedLoadIsPassedOn() async {
    await #expect(throws: Offline()) {
        try await loadWeek(from: FailingSource(), today: "2026-10-21")
    }
}
```

**`await #expect(throws:)` is how an async failure is expected.** The `await` goes in front of the
macro because the closure inside it is async. The second test proves the error reaches the caller
unchanged, which is the half that is usually not written: the screen in lesson 12 shows an error
state only if the error arrives.

```
ana@vm:~/l20$ swift test --filter Loading 2>&1 | grep -E "^(✔|✘)"
✔ Test aFailedLoadIsPassedOn() passed after 0.001 seconds.
✔ Test aLoadedWeekIsSummed() passed after 0.001 seconds.
✔ Test run with 2 tests in 0 suites passed after 0.001 seconds.
```

A fake that fails is also how a test reaches code a real server would only reach on a bad day, and
the planner's other fakes, in lesson 14, follow the same pattern: a type of a few lines, written in the
test file, that does one thing every time.
