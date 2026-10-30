---
title: map, filter and reduce
version: 1
---

Most loops over a collection do one of three jobs: turn every item into something else, keep the items
that pass a test, or combine all the items into one value. **Swift has a method for each: `map`,
`filter` and `reduce`**, and each takes a closure, written as lesson 3's trailing closures.

A week of sessions, each a tuple with a course, a duration and whether it was done:

```schooling-example
{"language": "swift", "file": "Transform.swift", "parts": [{"code": "// Transform.swift\nlet week: [(course: String, minutes: Int, done: Bool)] = [\n    (\"Swift\", 45, true),\n    (\"Kotlin\", 30, false),\n    (\"Swift\", 60, true),\n    (\"SQL\", 20, true),\n]", "note": "Four sessions, each a tuple with named parts. Lesson 5 replaces the tuple with a type of its own; for these three methods the tuple is enough."}, {"code": "let hours = week.map { Double($0.minutes) / 60 }\nprint(hours)", "note": "`map`: one result per item, in the same order. The closure turns a session into its length in hours."}, {"code": "let pending = week.filter { !$0.done }\nprint(pending.map { $0.course })", "note": "`filter`: the items for which the closure says `true`. `!` reads as \"not\", so this keeps the sessions not yet done."}, {"code": "let planned = week.reduce(0) { $0 + $1.minutes }\nprint(planned)", "note": "`reduce`: one value from all of them. It starts at 0 and adds each session's minutes; the part below the output slows it down."}, {"code": "let studied = week.filter { $0.done }.map { $0.minutes }.reduce(0, +)\nprint(studied)", "note": "The three in a chain, read left to right: the done sessions, their minutes, the sum."}]}
```

```
ana@vm:~/sw/l04$ swift Transform.swift
[0.75, 0.5, 1.0, 0.3333333333333333]
["Kotlin"]
155
125
```

**Each method returns a new collection and leaves `week` alone**, which is why `week` can be a `let`.
`map` produced an array of the same length with different contents; `filter`, one with the same kind of
contents and fewer of them; `reduce`, a single value. The chain in the last part reads in the order it
runs: keep the done sessions, take their minutes, add them up. The loop that does the same job needs a
`var` and four lines, and the reader has to run it in their head to see which of the three jobs it does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-pipeline\" aria-label=\"Four sessions in a column: Swift 45 done, Kotlin 30 not done, Swift 60 done, SQL 20 done. filter done keeps three of them, dropping Kotlin. map minutes turns the three into the numbers 45, 60 and 20. reduce with plus adds them into one number, 125.\"><defs><marker id=\"l04-pipeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Swift 45</text><text x=\"80\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">done</text><rect x=\"20\" y=\"78\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Kotlin 30</text><text x=\"80\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not done</text><rect x=\"20\" y=\"126\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Swift 60</text><text x=\"80\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">done</text><rect x=\"20\" y=\"174\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SQL 20</text><text x=\"80\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">done</text><line x1=\"145\" y1=\"120\" x2=\"335\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l04-pipeline-ah-phosphor)\"></line><text x=\"240\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">filter { $0.done }</text><text x=\"240\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 kept</text><rect x=\"340\" y=\"60\" width=\"60\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">45</text><rect x=\"340\" y=\"104\" width=\"60\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">60</text><rect x=\"340\" y=\"148\" width=\"60\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"370\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 numbers</text><text x=\"370\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">map { $0.minutes }</text><line x1=\"405\" y1=\"120\" x2=\"615\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l04-pipeline-ah-phosphor)\"></line><text x=\"510\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">reduce(0, +)</text><rect x=\"620\" y=\"100\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"660\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">125</text><text x=\"660\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 value</text></svg>", "caption": "The chain in Transform.swift: each step hands a new collection to the next, and the last hands back one value."}
```

## reduce, slowly

`reduce(0, +)` is the shortest way to add up an array, and it is worth seeing what it does once:

```swift
// Reduce.swift
let minutes = [45, 30, 60]
let total = minutes.reduce(0) { sum, next in
    print("\(sum) + \(next)")
    return sum + next
}
print(total)
```

```
ana@vm:~/sw/l04$ swift Reduce.swift
0 + 45
45 + 30
75 + 60
135
```

`reduce` starts from the value you give it, 0, and calls the closure once per item with **the result
so far and the next item**. Whatever the closure returns becomes the result so far for the next call.
`+` can be passed instead of a closure because the operator is itself a function of type `(Int, Int)
-> Int`, the shape `reduce` asks for.

## compactMap, again

Lesson 2 met `compactMap`: a `map` whose closure returns an optional, keeping only the values that are
there. With `map` and `filter` named, it reads as what it is, **map and then filter out the `nil`s**,
in one pass.
