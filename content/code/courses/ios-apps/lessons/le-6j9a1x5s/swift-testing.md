---
title: Swift Testing, the framework on every platform
version: 1
---

**A test is a program that knows the answer.** It sets up a plan, calls the code, and says what the
result must be; run every time something changes, it is the only check that does not get tired.
Lesson 1 wrote two with **Swift Testing**, the framework the Swift 6 toolchain ships on macOS, Linux
and Windows. This lesson writes the rest of the planner's tests, and every one of them runs here,
with `swift test`, exactly as it runs in Xcode.

Start from lesson 1's package. Copy it with `cp -r ~/planner ~/l20` and work in the copy; nothing in
lesson 1's files changes in this lesson, and every test below is a new file in
`Tests/PlannerCoreTests/`.

## A suite of tests about one thing

Save this as `Tests/PlannerCoreTests/WeekTests.swift`:

```schooling-example
{"language": "swift", "file": "Tests/PlannerCoreTests/WeekTests.swift", "parts": [{"code": "// Tests/PlannerCoreTests/WeekTests.swift\nimport Testing\n@testable import PlannerCore\n\n@Suite(\"A week's total\")\nstruct WeekTests {\n    let plan = Plan(\n        courses: [Course(id: \"sql\", title: \"SQL Databases\")],\n        sessions: [\n            StudySession(id: \"s1\", courseID: \"sql\", date: \"2026-10-19\", minutes: 50, done: true),\n            StudySession(id: \"s2\", courseID: \"sql\", date: \"2026-10-23\", minutes: 60),\n            StudySession(id: \"s3\", courseID: \"sql\", date: \"2026-10-26\", minutes: 45, done: true),\n        ]\n    )\n\n", "note": "`@Suite` groups tests under a name a person reads, and a suite is a plain `struct`. Its stored properties are the fixture: Swift Testing makes a new instance of the struct for every test, so each test starts from this plan and no test sees what another changed."}, {"code": "    @Test func countsOnlyTheWeekOfToday() {\n        let total = plan.weekTotal(today: \"2026-10-21\")\n        #expect(total.planned == 110)\n        #expect(total.done == 50)\n    }\n\n", "note": "`#expect` is a macro, so when it fails it can print both sides of the comparison and the expression they came from. The week of the 21st holds `s1` and `s2`: 110 planned, 50 done. `s3` is the next Monday's."}, {"code": "    @Test func markingDoneMovesOnlyDone() throws {\n        var plan = plan\n        try plan.markDone(\"s2\")\n        let total = plan.weekTotal(today: \"2026-10-21\")\n        #expect(total.planned == 110)\n        #expect(total.done == 110)\n    }\n\n    @Test func anUnknownSessionIsAnError() {\n        var plan = plan\n        #expect(throws: PlanError.unknownSession(\"s9\")) {\n            try plan.markDone(\"s9\")\n        }\n    }\n}\n", "note": "`var plan = plan` copies the fixture, because `Plan` is a value, and changes only the copy. A test function marked `throws` fails if anything inside it throws, so an unexpected `markDone` error is a failure with its message. The last test expects the error, by value."}]}
```

`--filter` runs only the tests whose names match, and the `grep` keeps the lines that report a
result. Leave both off and `swift test` runs everything and prints its progress as well:

```
ana@vm:~/l20$ swift test --filter WeekTests 2>&1 | grep -E "^(✔|✘)"
✔ Test anUnknownSessionIsAnError() passed after 0.001 seconds.
✔ Test markingDoneMovesOnlyDone() passed after 0.001 seconds.
✔ Test countsOnlyTheWeekOfToday() passed after 0.001 seconds.
✔ Suite "A week's total" passed after 0.001 seconds.
✔ Test run with 3 tests in 1 suite passed after 0.001 seconds.
```

**The suite's name, not its type, is what the report prints**, which is why the name is a sentence.
The three tests are three claims about one thing, each with its own name, and when one fails the
other two still say what still holds.

## `#expect` and `#require`

`#expect` records a failure and lets the test carry on, so one run reports every expectation that
did not hold. **`#require` stops the test** when its condition fails, and it is the one to use when
the rest of the test would be meaningless: `let session = try #require(plan.sessions.first)` ends the
test cleanly on an empty plan, where `plan.sessions.first!` would crash the whole test run.
