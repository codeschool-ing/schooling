---
title: Lazy sequences
version: 1
---

`map` and `filter` build a whole new array each time they are called. Usually that is what you want. It
is wasteful when you only need the first result that matches, or when the collection is very large or
has no end at all. **`.lazy` turns the chain round: nothing runs until a value is asked for, and then
only as much as that value needs.**

```swift
// Lazy.swift
let sessions = [45, 30, 60, 20, 50]
let eager = sessions
    .map { minutes -> Int in
        print("eager map \(minutes)")
        return minutes * 60
    }
    .first { $0 > 3000 }
print(eager ?? 0)
let lazy = sessions.lazy
    .map { minutes -> Int in
        print("lazy map \(minutes)")
        return minutes * 60
    }
    .first { $0 > 3000 }
print(lazy ?? 0)
```

```
ana@vm:~/sw/l04$ swift Lazy.swift
eager map 45
eager map 30
eager map 60
eager map 20
eager map 50
3600
lazy map 45
lazy map 30
lazy map 60
3600
```

Both chains find the first session longer than 3,000 seconds, which is the 60-minute one at 3,600. The
eager chain converted **all five** sessions to seconds and then searched the result. The lazy chain
converted 45, looked, converted 30, looked, converted 60, and stopped: **three** calls, because `first`
had its answer. The `print` inside each closure is what makes the difference visible; on a list of five
it costs nothing, and on a list of a million read from a file it is most of the work.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l04-lazy\" aria-label=\"Two rows of five sessions, 45, 30, 60, 20 and 50 minutes. Top row, eager: all five are converted to seconds, and then first finds 3600. Bottom row, lazy: 45 is converted and checked, then 30, then 60, which passes, and the remaining two are never converted.\"><text x=\"60\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">eager</text><text x=\"60\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">lazy</text><rect x=\"130\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">45 × 60</text><rect x=\"130\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">45 × 60</text><rect x=\"225\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">30 × 60</text><rect x=\"225\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">30 × 60</text><rect x=\"320\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">60 × 60</text><rect x=\"320\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">60 × 60</text><rect x=\"415\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"455\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">20 × 60</text><rect x=\"415\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"455\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><rect x=\"510\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">50 × 60</text><rect x=\"510\" y=\"140\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"550\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50</text><text x=\"640\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">first { $0 &gt; 3000 }</text><text x=\"355\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">first match</text><text x=\"560\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never converted</text></svg>", "caption": "Eager converts everything and then searches; lazy converts one at a time and stops at the first match."}
```

The closures here spell out their result type, `minutes -> Int in`. Swift would have inferred it from
the `return`; it is written so that each step of the chain says what it produces.

## A sequence with no end

Laziness also makes it possible to describe a sequence that never ends and take only what you need:

```swift
// Endless.swift
let goals = (1...).lazy
    .map { week in 300 + 15 * (week - 1) }
    .prefix(4)
print(Array(goals))
```

```
ana@vm:~/sw/l04$ swift Endless.swift
[300, 315, 330, 345]
```

`1...` is a range with no upper end. Made eager, `map` would try to build an infinite array and never
return. Lazily, it is a description, and `prefix(4)` takes four values from it: a goal that rises by 15
minutes a week for the first four weeks. `Array(…)` is the moment the values are actually computed.

**Use `lazy` when you stop early or the input is large**, and leave it out otherwise: for a short array
that is used whole, it only adds a step and a less obvious type. Lesson 9's `some Sequence` is the
tool for hiding that type when a function returns one.
