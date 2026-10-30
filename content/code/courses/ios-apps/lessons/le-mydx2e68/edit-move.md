---
title: Deleting and moving by id, tested
version: 1
---

**A list reports an edit in positions, and the plan must apply it by identity.** `onDelete` hands
over an `IndexSet`; `onMove` hands over an `IndexSet` and a destination. Both count rows of the
collection `ForEach` was given, which on the course screen is one course's sessions filtered out of
the plan. Apply those numbers to `plan.sessions` directly and you delete or move a different
session, often one from a course the person was not even looking at.

`List`'s side of this needs SwiftUI. The arithmetic does not, so it goes in the package and is tested
on any computer. Copy lesson 1's package for this lesson, `cp -r ~/planner ~/editing`, and add
`Sources/PlannerCore/PlanEditing.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/PlanEditing.swift", "parts": [{"code": "// Sources/PlannerCore/PlanEditing.swift\nimport Foundation\n\nextension Plan {\n    /// One course's sessions, in the order the course screen shows them.\n    public func sessions(of courseID: String) -> [StudySession] {\n        sessions.filter { $0.courseID == courseID }\n    }\n", "note": "What the course screen shows. Keeping it a function of the plan means the screen and the tests below build `shown` the same way."}, {"code": "    /// Delete the rows at `offsets` of a screen that showed `shown`.\n    public mutating func delete(at offsets: IndexSet, in shown: [StudySession]) {\n        let ids = Set(offsets.map { shown[$0].id })\n        sessions.removeAll { ids.contains($0.id) }\n    }\n", "note": "The translation from positions to identity, done once, at the edge: offsets into what was shown become ids, and the plan deletes by id. `IndexSet` is Foundation's, the type `onDelete` hands over."}, {"code": "    /// Move rows of a screen that showed `shown`, as a list reports a drag:\n    /// the rows at `offsets` go before the row that was at `destination`.\n    public mutating func move(from offsets: IndexSet, to destination: Int, in shown: [StudySession]) {\n        var order = shown.map(\\.id)\n        let moving = offsets.map { order[$0] }\n        let above = offsets.filter { $0 < destination }.count\n        order.removeAll { moving.contains($0) }\n        order.insert(contentsOf: moving, at: destination - above)\n", "note": "`onMove` reports a drag as the offsets moved and a destination counted in the list *before* the move. Rows taken from above the destination shift it up by one each, which is what `above` corrects."}, {"code": "        let slots = sessions.indices.filter { i in order.contains(sessions[i].id) }\n        let byID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })\n        for (slot, id) in zip(slots, order) {\n            sessions[slot] = byID[id]!\n        }\n    }\n}\n", "note": "Write the new order back into the places this course's sessions held in the whole plan, so the other course's sessions do not move. The force unwrap cannot fail: every id in `order` came from `sessions`."}]}
```

SwiftUI's own `Array.move(fromOffsets:toOffset:)` and `remove(atOffsets:)`, which Apple's examples
use with `onMove` and `onDelete`, are extensions that ship with SwiftUI, so they are not on Linux.
The few lines above do the same job and say what they are doing.

Then three tests. Save this as `Tests/PlannerCoreTests/EditingTests.swift`:

```swift
// Tests/PlannerCoreTests/EditingTests.swift
import Foundation
import Testing
@testable import PlannerCore

func fourSessions() -> Plan {
    Plan(
        courses: [Course(id: "sql", title: "SQL Databases"), Course(id: "mobile", title: "Mobile Fundamentals")],
        sessions: [
            StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50),
            StudySession(id: "s2", courseID: "mobile", date: "2026-10-20", minutes: 40),
            StudySession(id: "s3", courseID: "sql", date: "2026-10-23", minutes: 60),
            StudySession(id: "s4", courseID: "sql", date: "2026-10-24", minutes: 30),
        ]
    )
}

@Test func aScreenOffsetIsNotAPlanIndex() {
    var plan = fourSessions()
    plan.sessions.remove(at: 1)                  // the SQL screen's row 1 is s3...
    #expect(plan.sessions.map(\.id) == ["s1", "s3", "s4"])
}

@Test func deletingFromTheCourseScreenDeletesWhatWasShown() {
    var plan = fourSessions()
    let shown = plan.sessions(of: "sql")         // s1, s3, s4
    plan.delete(at: [1], in: shown)
    #expect(plan.sessions.map(\.id) == ["s1", "s2", "s4"])
}

@Test func movingWithinACourseLeavesTheOtherCourseInPlace() {
    var plan = fourSessions()
    let shown = plan.sessions(of: "sql")         // s1, s3, s4
    plan.move(from: [2], to: 0, in: shown)       // drag s4 to the top
    #expect(plan.sessions(of: "sql").map(\.id) == ["s4", "s1", "s3"])
    #expect(plan.sessions.map(\.id) == ["s4", "s2", "s1", "s3"])
}
```

```
ana@vm:~/editing$ swift test --filter Editing
Building for debugging...
[Pre-planning 1 / 153]
[Starting]
Build complete! (0.68 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aScreenOffsetIsNotAPlanIndex() started.
◇ Test movingWithinACourseLeavesTheOtherCourseInPlace() started.
◇ Test deletingFromTheCourseScreenDeletesWhatWasShown() started.
✔ Test aScreenOffsetIsNotAPlanIndex() passed after 0.001 seconds.
✔ Test movingWithinACourseLeavesTheOtherCourseInPlace() passed after 0.001 seconds.
✔ Test deletingFromTheCourseScreenDeletesWhatWasShown() passed after 0.001 seconds.
✔ Test run with 3 tests in 0 suites passed after 0.001 seconds.
```

**The first test passes, and what it pins is the bug.** The SQL screen's row 1 is `s3`; position 1
of the whole plan is `s2`, the mobile session, and that is what `remove(at: 1)` took. The second
deletes `s3` as the person meant. The third drags `s4` to the top of the SQL screen and checks two
things: the SQL sessions come out in the dragged order, and `s2`, which belongs to the other course,
is still second in the plan. `--filter Editing` ran these three and left lesson 1's alone.

On the screen the calls are one line each, inside `onDelete` and `onMove` on the `ForEach`, passing
the same `shown` the `ForEach` was given. Not run here: they need SwiftUI.
