---
title: Testing code that waits
version: 1
---

Most of a real planner's work waits for something: a server, a disk, another task. Lesson 14 wrote
that waiting with `async` and `await`, and **a test of async code is an async test**: mark the test
function `async`, `await` the call, and the framework waits with it. No callbacks, no sleeping for
"long enough", and no test that passes because it finished before the work did.

## Something to sync

The library gains the piece that sends a week's finished sessions somewhere. Where they go is a
protocol, lesson 10's seam, so the library does not know whether it is a server, a file or a test:

```swift
// Sources/PlannerCore/Syncer.swift
public protocol SessionStore: Sendable {
    func save(_ sessions: [StudySession]) async throws
}

public struct Syncer: Sendable {
    let store: any SessionStore

    public init(store: any SessionStore) {
        self.store = store
    }

    public func sync(
        _ week: Week,
        onSaved: (StudySession) -> Void = { _ in }
    ) async throws -> Int {
        let done = week.sessions.filter(\.done)
        for session in done {
            try await store.save([session])
            onSaved(session)
        }
        return done.count
    }
}
```

`sync` saves the finished sessions one at a time, calls `onSaved` after each, and returns how many
it saved. It suspends at every `await`, and a test has to follow it there.

## Two async tests

```schooling-example
{"language": "swift", "file": "Tests/PlannerCoreTests/SyncerTests.swift", "parts": [
{"code": "import Testing\n@testable import PlannerCore", "note": "The same framework; nothing extra is imported for async code."},
{"code": "actor MemoryStore: SessionStore {\n    private(set) var saved: [StudySession] = []\n\n    func save(_ sessions: [StudySession]) async throws {\n        saved += sessions\n    }\n}", "note": "A store that keeps what it is given in memory. It is an `actor` because `sync` calls it from a task and the test reads it afterwards, and lesson 15 is why shared mutable state lives in one."},
{"code": "@Suite struct SyncerTests {\n    @Test func savesOnlyDoneSessions() async throws {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        week.add(StudySession(course: \"swift\", minutes: 30))\n        week.add(StudySession(course: \"kotlin\", minutes: 60, done: true))\n        let store = MemoryStore()\n        let count = try await Syncer(store: store).sync(week)\n        #expect(count == 2)\n        #expect(await store.saved.map(\\.course) == [\"swift\", \"kotlin\"])\n    }", "note": "`async throws` on the test, `try await` on the call. Reading the actor's `saved` is a crossing into it, so the expectation needs `await` too, and `#expect` takes it."},
{"code": "    @Test func reportsEachSavedSession() async throws {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        week.add(StudySession(course: \"kotlin\", minutes: 60, done: true))\n        let syncer = Syncer(store: MemoryStore())\n        try await confirmation(expectedCount: 2) { saved in\n            _ = try await syncer.sync(week) { _ in saved() }\n        }\n    }\n}", "note": "A **confirmation** checks that something happens, and how often: the test fails unless `saved()` is called exactly twice before the block returns. It is how to test a callback, an event or a notification, which has no return value to `#expect` on."}
]}
```

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter SyncerTests 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Planning deferred tasks]
[9 / 26] PlannerCore
[17 / 30] PlannerCoreTests-product
[18 / 31] PlannerCoreTests-product
[19 / 31] PlannerCore
[20 / 31] PlannerCoreTests-product
[24 / 30] PlannerCoreTests-product
[28 / 31] PlannerCoreTests-product
[32 / 34] PlannerCoreTests-test-runner
[33 / 35] PlannerCoreTests-test-runner
[35 / 35] PlannerCoreTests-test-runner
Build complete! (2.86 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite SyncerTests started.
◇ Test reportsEachSavedSession() started.
◇ Test savesOnlyDoneSessions() started.
✔ Test reportsEachSavedSession() passed after 0.001 seconds.
✔ Test savesOnlyDoneSessions() passed after 0.001 seconds.
✔ Suite SyncerTests passed after 0.004 seconds.
✔ Test run with 2 tests in 1 suite passed after 0.004 seconds.
```

Both passed, and neither waited a moment longer than the work took: the runner awaited each test
until it returned. **An async test never needs a sleep.** A test that sleeps "until the work is
probably done" is either slow, when the sleep is generous, or occasionally wrong, when the machine
is busy, and both are worse than no test.

## When the count is wrong

`confirmation` is strict in both directions. If `sync` forgot to call `onSaved`, the confirmation
would see zero calls where it expected two and fail; if it called it twice per session, four
calls would fail it as well. Changing the test's `expectedCount` to 3 shows the message:

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter reportsEachSavedSession 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[2 / 7] PlannerCoreTests-product
[5 / 10] PlannerCoreTests-product
[9 / 12] PlannerCoreTests-product
[13 / 15] PlannerCoreTests-test-runner
[16 / 16] PlannerCoreTests-test-runner
Build complete! (1.93 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite SyncerTests started.
◇ Test reportsEachSavedSession() started.
✘ Test reportsEachSavedSession() recorded an issue at SyncerTests.swift:26:31: Confirmation was confirmed 2 times, but expected to be confirmed 3 times
✘ Test reportsEachSavedSession() failed after 0.001 seconds with 1 issue.
✘ Suite SyncerTests failed after 0.001 seconds with 1 issue.
✘ Test run with 1 test in 1 suite failed after 0.001 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

`Confirmation was confirmed 2 times, but expected to be confirmed 3 times`. The number in the test
is a claim about the code, and the framework counted.

## XCTest waits too

XCTest test methods may also be `async`, and `await` works in them the same way; older XCTest code
uses `XCTestExpectation` and `wait(for:timeout:)` instead, which is the callback-era shape and
carries a timeout because it could not know when the work was done. You will read both in existing
projects. New async tests are simplest in Swift Testing, as above.
