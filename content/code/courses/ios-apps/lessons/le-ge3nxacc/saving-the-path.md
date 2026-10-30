---
title: Saving where the person was, and refusing a screen that no longer exists
version: 1
---

**iOS may end an app in the background at any time, and a person who comes back expects the screen
they left.** Lesson 2 is about when that happens. With the path as an array of `Codable` values,
saving the stack is encoding an array, and restoring it is decoding one. On a Mac the app would do
it with `@SceneStorage` or a file when the scene goes to the background; neither was run. The
encoding, the decoding, and the one check the restore needs all run here.

**The check is the part people leave out.** A path saved on Monday may name a session deleted on
Tuesday. Restored blindly, it pushes a screen for something that is not there. The fix is to keep
the longest start of the path whose every route still names something in the plan. Save this as
`Sources/PlannerCore/RoutePruning.swift`:

```swift
// Sources/PlannerCore/RoutePruning.swift
extension Route {
    /// The longest start of `path` whose every route still names something in `plan`.
    public static func stillValid(_ path: [Route], in plan: Plan) -> [Route] {
        Array(path.prefix { route in
            switch route {
            case .course(let id): plan.courses.contains { $0.id == id }
            case .session(let id): plan.sessions.contains { $0.id == id }
            case .week(let day): day.count == 10
            }
        })
    }
}
```

`prefix(while:)` stops at the first route that fails, rather than filtering it out, and that is
deliberate: a session screen whose course is gone should not be shown with nothing under it. The
check on a week's day only looks at the length; lesson 10 is where a day typed by a person is
checked properly.

A program to watch it work. This lesson's manifest adds an executable target `paths`, the same way
lesson 7's added `track`. Replace `Package.swift`:

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
        .executableTarget(name: "paths", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

And save this as `Sources/paths/main.swift`:

```schooling-example
{"language": "swift", "file": "Sources/paths/main.swift", "parts": [{"code": "// Sources/paths/main.swift\nimport Foundation\nimport PlannerCore\n\nlet encoder = JSONEncoder()\nencoder.outputFormatting = [.sortedKeys]\n\nlet path: [Route] = [.course(id: \"sql\"), .session(id: \"s3\")]\nlet saved = try encoder.encode(path)\nprint(\"saved:   \", String(decoding: saved, as: UTF8.self))\nlet restored = try JSONDecoder().decode([Route].self, from: saved)\nprint(\"restored:\", restored == path)\n", "note": "The person was on session `s3` of the SQL course. Encode the path, print the JSON, decode it and compare. `.sortedKeys` makes the output the same on every run."}, {"code": "var plan = Plan(\n    courses: [Course(id: \"sql\", title: \"SQL Databases\")],\n    sessions: [StudySession(id: \"s3\", courseID: \"sql\", date: \"2026-10-23\", minutes: 60)]\n)\nprint(\"nothing deleted:\", Route.stillValid(restored, in: plan))\nplan.sessions.removeAll()\nprint(\"s3 deleted:     \", Route.stillValid(restored, in: plan))\nplan.courses.removeAll()\nprint(\"sql deleted:    \", Route.stillValid(restored, in: plan))\n", "note": "Then the restore, three times: with everything still there, after the session was deleted, and after the course was too."}]}
```

```
ana@vm:~/navigate$ .build/debug/paths
saved:    [{"course":{"id":"sql"}},{"session":{"id":"s3"}}]
restored: true
nothing deleted: [PlannerCore.Route.course(id: "sql"), PlannerCore.Route.session(id: "s3")]
s3 deleted:      [PlannerCore.Route.course(id: "sql")]
sql deleted:     []
```

**The JSON is what the compiler synthesised from the enum**: each route is an object whose one key is
the case's name and whose value holds the labelled associated values. That is a format you now own.
Rename `session` to `sessionDetail` in the enum and every path saved before the rename stops
decoding, so a saved path should be treated like any other saved data: if the decode throws, start
at the root rather than crash.

**The three restores are the rule at work.** With the session gone the app reopens on the SQL
course, the screen the person was on before it. With the course gone too it reopens on the list.
