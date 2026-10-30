---
title: Testing work that runs when nobody is watching
version: 1
---

**Background work is the hardest code in an app to see running, and the easiest to ship broken.**
The system chooses when it runs, possibly hours after it was scheduled, on a phone in somebody's
pocket. A refresh handler that throws on its second line can fail every night for a month and show
nothing on any screen. So it is tested in two halves: the decisions in the package, with tests that
run in a second; and the wiring to the system, by hand, on a device.

## The decisions, on any computer

Everything sections 06 and 07 decided is a function of its inputs: the moment, the time zone, the
pending sessions, whether the task was cancelled. Save this as
`Tests/PlannerCoreTests/BackgroundTests.swift`; it uses `FakeSource` and `freshStore` from lesson 14's
tests, which are in the same test target:

```swift
// Tests/PlannerCoreTests/BackgroundTests.swift
import Foundation
import Testing
@testable import PlannerCore

func moment(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

func calendar(_ zone: String) -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: zone)!
    return c
}

@Test func withNothingWaitingTheNextRefreshIsSixInTheMorning() {
    let next = nextRefresh(after: moment("2026-10-21T22:30:00-03:00"), pending: 0, calendar: calendar("America/Sao_Paulo"))
    #expect(next == moment("2026-10-22T06:00:00-03:00"))
}

@Test func theNightTheClocksGoBackIsAnHourLonger() {
    let now = moment("2026-10-24T22:30:00+01:00")
    let next = nextRefresh(after: now, pending: 0, calendar: calendar("Europe/Lisbon"))
    #expect(next == moment("2026-10-25T06:00:00Z"))
    #expect(next.timeIntervalSince(now) == 8.5 * 3600)
}

@Test func sessionsWaitingAskAgainInFifteenMinutes() {
    let now = moment("2026-10-21T22:30:00-03:00")
    #expect(nextRefresh(after: now, pending: 3, calendar: calendar("America/Sao_Paulo")) == now.addingTimeInterval(900))
}

@Test func aCancelledSyncSendsNothingAndKeepsEverything() async throws {
    let fake = FakeSource()
    let repo = try PlannerRepository(source: fake, store: freshStore())
    try await repo.refresh()
    await fake.set(online: false)
    for n in 1...3 {
        try await repo.add(StudySession(id: "b\(n)", courseID: "sql", date: "2026-10-22", minutes: 20))
    }
    await fake.set(online: true)
    let cut = await Task {
        withUnsafeCurrentTask { $0?.cancel() }      // the system's time is already up
        return await repo.syncUntilCancelled()
    }.value
    #expect(cut.sent == 0 && cut.left == 3)
    let whole = await repo.syncUntilCancelled()
    #expect(whole.sent == 3 && whole.left == 0)
}
```

The Lisbon test pins the hour the clocks went back. **The cancelled-sync test is the expiration with
nothing left to chance**: `withUnsafeCurrentTask` cancels the task the closure is running in before
the sync starts, which is the case of a task whose time was already up, and the second call checks
that the three sessions it did not send are all still there to send.

```
ana@vm:~/planner$ swift test 2>&1 | grep -E "✔|✘"
✔ Test aSessionFromTheServerBecomesAModelSession() passed after 0.003 seconds.
✔ Test anAnswerLostOnTheWayIsSentAgainAndKeptOnce() passed after 0.003 seconds.
✔ Test offlineTheDeviceStillHasItsPlan() passed after 0.003 seconds.
✔ Test aSessionAddedOfflineIsSentLater() passed after 0.003 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.003 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.003 seconds.
✔ Test aSessionEncodesWithTheServersSpelling() passed after 0.003 seconds.
✔ Test aSessionTheServerRefusesIsDroppedAndReported() passed after 0.003 seconds.
✔ Test aCancelledSyncSendsNothingAndKeepsEverything() passed after 0.003 seconds.
✔ Test theNightTheClocksGoBackIsAnHourLonger() passed after 0.005 seconds.
✔ Test sessionsWaitingAskAgainInFifteenMinutes() passed after 0.005 seconds.
✔ Test withNothingWaitingTheNextRefreshIsSixInTheMorning() passed after 0.006 seconds.
✔ Test run with 12 tests in 0 suites passed after 0.006 seconds.
```

Twelve tests now: lesson 1's two, lesson 12's two, lesson 14's four, and these four.

## The wiring, on a device

Whether the system really calls the handler can only be seen on a phone. Apple's guide *Starting and
Terminating Tasks During Development* gives two debugger commands for it, and says they **work only on
devices**, not in the simulator; they were not run for this course. Pause the app in Xcode's debugger
after the request has been submitted, and type at the `(lldb)` prompt, with the planner's identifier:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.example.planner.refresh"]
```

Resume, and the system launches the task as it would hours later. To try the other end, pause inside
the running task and type the expiration command:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.example.planner.refresh"]
```

The same guide warns that these are private functions, for development only: **an app that references
them in code it submits is rejected**, which is why they are typed at the debugger and never written
in a file. What to look for: the handler runs, the pending count drops by however many it managed, the
next refresh is scheduled, and after an expiration the device's file still says exactly what was sent.
