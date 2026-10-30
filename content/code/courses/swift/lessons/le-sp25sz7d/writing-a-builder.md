---
title: Writing a result builder
version: 1
---

The planner prints a week's report: a heading, one line per course, and a line of congratulation when
the goal is met. Written with lesson 4's arrays, it is a `var lines` and an `append` on every line.
**A result builder lets the report be written as what it says**, one line of text per line of code.

A builder is a type marked `@resultBuilder` with at least one static function, `buildBlock`, that
combines the pieces of a block into one value. This one starts with only that:

```swift
// Report.swift
@resultBuilder
enum ReportBuilder {
    static func buildBlock(_ lines: [String]...) -> [String] {
        lines.flatMap { $0 }
    }
    static func buildExpression(_ line: String) -> [String] {
        [line]
    }
}

func report(@ReportBuilder _ content: () -> [String]) -> String {
    content().joined(separator: "\n")
}

let courses = ["Swift": 135, "SQL": 90]
let goal = 300

print(report {
    "Week of 2 November"
    "Swift: \(courses["Swift"] ?? 0) minutes"
    "SQL: \(courses["SQL"] ?? 0) minutes"
})
```

```
ana@vm:~/sw/l16$ swift Report.swift
Week of 2 November
Swift: 135 minutes
SQL: 90 minutes
```

`@ReportBuilder` in front of the closure parameter is what makes the block in the call a builder
block. **`buildExpression` turns each line into the type the builder works with**, here a one-element
array of strings, and `buildBlock` receives one of those per line and flattens them into one list.
The enum has no cases and is never created: it is only a place to keep the static functions, which is
the usual way to write a builder.

## Control flow is opt-in

Courses are a list, so the natural report has a `for` loop in it, and the congratulation is an `if`.
Add both to the block and the compiler stops:

```swift
// ReportLoop.swift
@resultBuilder
enum ReportBuilder {
    static func buildBlock(_ lines: [String]...) -> [String] {
        lines.flatMap { $0 }
    }
    static func buildExpression(_ line: String) -> [String] {
        [line]
    }
}

func report(@ReportBuilder _ content: () -> [String]) -> String {
    content().joined(separator: "\n")
}

let courses = ["SQL": 90, "Swift": 135]
let goal = 300

print(report {
    "Week of 2 November"
    for (course, minutes) in courses.sorted(by: { $0.key < $1.key }) {
        "\(course): \(minutes) minutes"
    }
})
```

```
ana@vm:~/sw/l16$ swiftc ReportLoop.swift -o reportloop
ReportLoop.swift:21:5: error: closure containing control flow statement cannot be used with result builder 'ReportBuilder'
 1 | // ReportLoop.swift
 2 | @resultBuilder
 3 | enum ReportBuilder {
   |      |- note: add 'buildArray(_:)' to the result builder 'ReportBuilder' to add support for 'for'..'in' loops
   |      `- note: enum 'ReportBuilder' declared here
 4 |     static func buildBlock(_ lines: [String]...) -> [String] {
 5 |         lines.flatMap { $0 }
   :
19 | print(report {
20 |     "Week of 2 November"
21 |     for (course, minutes) in courses.sorted(by: { $0.key < $1.key }) {
   |     `- error: closure containing control flow statement cannot be used with result builder 'ReportBuilder'
22 |         "\(course): \(minutes) minutes"
23 |     }
```

**The builder has no `buildArray`, so a `for` is refused**, with the builder named in the message and
a note saying which function would add support for it.
That is a feature: a builder decides which statements make sense inside it, and one that has no
meaning for a loop simply does not offer it. Ours has a meaning for both, so it gets two more static
functions:

```schooling-example
{"language": "swift", "file": "ReportFull.swift", "parts": [{"code": "@resultBuilder\nenum ReportBuilder {\n    static func buildBlock(_ lines: [String]...) -> [String] {\n        lines.flatMap { $0 }\n    }\n    static func buildExpression(_ line: String) -> [String] {\n        [line]\n    }", "note": "The two functions from `Report.swift`, unchanged: one turns a line into a list, the other joins the lists of a block."}, {"code": "    static func buildArray(_ passes: [[String]]) -> [String] {\n        passes.flatMap { $0 }\n    }", "note": "**`buildArray` gives `for` a meaning.** The compiler runs the loop, builds the body once per pass, and hands this function one list per pass to join."}, {"code": "    static func buildOptional(_ lines: [String]?) -> [String] {\n        lines ?? []\n    }\n}", "note": "**`buildOptional` gives an `if` without `else` a meaning.** It receives the body's lines when the condition held, and `nil` when it did not, which becomes no lines at all."}, {"code": "func report(goal: Int, _ courses: [String: Int]) -> String {\n    let total = courses.values.reduce(0, +)\n    return build(goal: goal, total: total, courses).joined(separator: \"\\n\")\n}", "note": "The report function now takes the goal and the courses as parameters, adds up the total, and joins whatever `build` returns."}, {"code": "@ReportBuilder\nfunc build(goal: Int, total: Int, _ courses: [String: Int]) -> [String] {\n    \"Week of 2 November: \\(total) of \\(goal) minutes\"\n    for (course, minutes) in courses.sorted(by: { $0.key < $1.key }) {\n        \"  \\(course): \\(minutes)\"\n    }\n    if total >= goal {\n        \"Goal reached\"\n    }\n}", "note": "**A builder attribute works on a function too**: the body of `build` is a builder block, with no `return`. The `for` and the `if` are the statements `ReportLoop.swift` was refused for."}, {"code": "let courses = [\"SQL\": 90, \"Swift\": 135]\nprint(report(goal: 300, courses))\nprint(report(goal: 200, courses))"}]}
```

```
ana@vm:~/sw/l16$ swift ReportFull.swift
Week of 2 November: 225 of 300 minutes
  SQL: 90
  Swift: 135
Week of 2 November: 225 of 200 minutes
  SQL: 90
  Swift: 135
Goal reached
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l16-builder\" aria-label=\"Three statements of the report block on the left, a line of text, a for loop and an if, each with an arrow to the builder function that handles it: buildExpression, buildArray and buildOptional. All three arrows meet at buildBlock, which produces one array of strings.\"><defs><marker id=\"l16-build-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the block</text><rect x=\"20\" y=\"40\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Week of 2 November: …\"</text><path d=\"M270 58 L338 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"340\" y=\"40\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">buildExpression</text><path d=\"M490 58 L568 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"20\" y=\"100\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">for (course, minutes) in …</text><path d=\"M270 118 L338 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"340\" y=\"100\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">buildArray</text><path d=\"M490 118 L568 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"20\" y=\"160\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">if total &gt;= goal { … }</text><path d=\"M270 178 L338 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"340\" y=\"160\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">buildOptional</text><path d=\"M490 178 L568 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"570\" y=\"108\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">buildBlock</text><path d=\"M635 148 L635 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><text x=\"635\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">[String]</text><text x=\"350\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper)\">each statement goes to the function the compiler picks for it</text></svg>", "caption": "What ReportBuilder does with the body of build: one static function per kind of statement, and buildBlock to join the results."}
```

Two reports from one block. The loop produced one line per course in both. The `if` produced nothing
in the first, where 225 minutes fell short of 300, and "Goal reached" in the second, whose goal was
200. Each statement inside the block went to the function the compiler
picked for it, `buildArray` for the `for` and `buildOptional` for the `if`, and `buildBlock` combined
what they returned. **The report in the call reads as the report on the screen**, which is the whole
point of a builder and the reason SwiftUI is written with one.
