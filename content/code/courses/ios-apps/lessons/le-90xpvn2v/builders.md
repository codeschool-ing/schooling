---
title: Result builders: how a body holds several views
version: 1
---

**A body that lists three views one under another is not three statements; it is one expression,
assembled by a result builder.** In ordinary Swift, a function body with three bare expressions in it
would compute three values and throw them away. In a body, those lines become one value that holds all
three, because SwiftUI marks `body` with its builder, and the builder is a type with static functions
the compiler calls on each line.

Builders are a Swift feature, not a SwiftUI one: the `swift` course meets them in its lesson 16, and
they compile on Linux like anything else. Here is a small one that builds the lines of a course card
instead of views. Save this as `builder.swift` in `~/l03`:

```schooling-example
{"language": "swift", "file": "builder.swift", "parts": [{"code": "// builder.swift: a result builder like SwiftUI's, building lines of text\n@resultBuilder\nenum LinesBuilder {\n    static func buildExpression(_ line: String) -> [String] { [line] }\n    static func buildBlock(_ parts: [String]...) -> [String] { parts.flatMap { $0 } }\n", "note": "`@resultBuilder` marks the type. `buildExpression` turns each line into a part, here a one-element array; `buildBlock` receives every part of a block and joins them into one value."}, {"code": "    static func buildOptional(_ part: [String]?) -> [String] { part ?? [] }\n    static func buildEither(first part: [String]) -> [String] { part }\n    static func buildEither(second part: [String]) -> [String] { part }\n}\n", "note": "Three more functions make `if` legal inside a builder. `buildOptional` is an `if` with no `else`: nothing when the condition is false. The two `buildEither` are the two branches of an `if`/`else`."}, {"code": "@LinesBuilder\nfunc card(title: String, minutes: Int, done: Bool) -> [String] {\n    title\n    \"\\(minutes) min\"\n    if done {\n        \"done\"\n    }\n}\n\nprint(card(title: \"SQL Databases\", minutes: 50, done: true))\nprint(card(title: \"Mobile Fundamentals\", minutes: 40, done: false))\n", "note": "The function body reads like a SwiftUI body: lines with no `return`, and an `if`. The compiler rewrites it into calls to the builder's functions, and the result is one array."}]}
```

```
ana@vm:~/l03$ swift builder.swift
["SQL Databases", "50 min", "done"]
["Mobile Fundamentals", "40 min"]
```

**The second card has two lines, because the `if` was false and `buildOptional` got `nil`.** Nothing
special happened at run time: the compiler rewrote the function before it ran. What it wrote is
roughly this, and seeing it once removes the magic:

```swift
let a = LinesBuilder.buildExpression(title)
let b = LinesBuilder.buildExpression("\(minutes) min")
let c = LinesBuilder.buildOptional(done ? LinesBuilder.buildBlock(LinesBuilder.buildExpression("done")) : nil)
return LinesBuilder.buildBlock(a, b, c)
```

That expansion is written by hand to show the shape, from the rules of the Swift language reference
for result builders; it was not printed by the compiler.

## SwiftUI's builder

SwiftUI's builder is `ViewBuilder`, and `body` carries it. It has the same family of functions, and
instead of joining strings it combines views into one value whose **type** records every view and
every branch. That is the "one type" section 03 said a body must return: however many views a body
lists, the builder turns them into a single type.

Apple's documentation for `ViewBuilder`, read on 30 October 2026, adds that from Xcode 27 the builder
constructs what it calls type-agnostic content, and names `ContentBuilder` as the alias to write where
code expects that. The rule this lesson is about does not change with it: a body is one expression,
and the builder decides how its lines become one value.
