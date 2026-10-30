---
title: What a view is subscribed to, measured
version: 1
---

**A view is subscribed to exactly the properties its `body` read the last time it ran, and to
nothing else.** That is the whole of Observation's contract with SwiftUI, and it can be watched on
Linux, because SwiftUI uses the same public function anybody can call:
`withObservationTracking(_:onChange:)`. It runs a closure, records every observable property the
closure read, and calls `onChange` the first time one of them is about to be written.

This program stands in for three views. Each "view" is a closure that reads what that screen's
`body` would read, and `onChange` prints where SwiftUI would draw again. Each scene makes a fresh
model, so one scene's subscriptions cannot leak into the next. Save it as `Sources/track/main.swift`:

```schooling-example
{"language": "swift", "file": "Sources/track/main.swift", "parts": [{"code": "// Sources/track/main.swift\nimport Observation\nimport PlannerCore\n\n@MainActor func sampleModel() -> PlannerModel {\n    PlannerModel(\n        plan: Plan(\n            courses: [Course(id: \"sql\", title: \"SQL Databases\"), Course(id: \"mobile\", title: \"Mobile Fundamentals\")],\n            sessions: [\n                StudySession(id: \"s1\", courseID: \"sql\", date: \"2026-10-19\", minutes: 50, done: true),\n                StudySession(id: \"s3\", courseID: \"sql\", date: \"2026-10-23\", minutes: 60),\n            ]\n        ),\n        today: \"2026-10-21\"\n    )\n}\n", "note": "A small plan, two courses and two sessions, the same data the other lessons use."}, {"code": "@MainActor func scene(_ title: String, _ change: (PlannerModel) throws -> Void) rethrows {\n    let model = sampleModel()\n    print(title)\n    withObservationTracking { _ = model.plan.courses.map(\\.title) } onChange: {\n        print(\"  CourseListView would run body again\")\n    }\n    withObservationTracking { _ = model.week } onChange: {\n        print(\"  WeekView would run body again\")\n    }\n    withObservationTracking { _ = model.today } onChange: {\n        print(\"  Header would run body again\")\n    }\n    try change(model)\n}\n", "note": "Three subscriptions, one per screen. The course list reads the course titles; the week screen reads `week`, which reads `plan` and `today`; a header reads only `today`. Then the scene makes one change."}, {"code": "scene(\"today moves on a week\") { $0.today = \"2026-10-28\" }\ntry scene(\"s3 is marked done\") { try $0.markDone(\"s3\") }\nscene(\"a course is renamed\") { $0.plan.courses[0].title = \"SQL\" }\nscene(\"lastSaved is set\") { $0.lastSaved = \"2026-10-21T18:00\" }\n", "note": "Four changes, one per scene."}]}
```

```
ana@vm:~/observe$ swift build 2>&1 | grep -E "error|warning"
ana@vm:~/observe$ .build/debug/track
today moves on a week
  WeekView would run body again
  Header would run body again
s3 is marked done
  WeekView would run body again
  CourseListView would run body again
a course is renamed
  WeekView would run body again
  CourseListView would run body again
lastSaved is set
```

`swift build` compiles the new model and the new program, and the `grep` shows nothing because
nothing it was asked to show, an error or a warning, was printed. Then the four scenes:

- **`today` moved, and only the two screens that read it were told.** The course list read titles,
  which live in `plan`, so it was left alone.
- **Marking `s3` done told the week screen, which is right, and the course list, which drew nothing
  that changed.** The list read `model.plan.courses`, and Observation tracks `plan` as one property:
  any write to it, a session included, is a write to `plan`.
- **Renaming a course told the week screen too**, whose numbers did not move, for the same reason.
- **`lastSaved` told nobody**, because `@ObservationIgnored` took it out of tracking.

The order of the lines inside a scene is not something to rely on, and on another run it can differ:
Observation keeps no order among the views it notifies.

**The second and third scenes are the cost of keeping the plan as one value.** A screen that reads
any part of `plan` redraws when any part of it changes. For a planner with a few dozen sessions that
costs nothing anybody can see, and the simplicity is worth more. When it does matter, a list of a few
thousand rows, the fix is to break the state into observable pieces each screen reads separately,
and lesson 8 measures what a list actually redraws.
