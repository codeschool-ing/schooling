---
title: What a closure captures
version: 1
---

A closure can use names from the place it was written. That sounds obvious until you notice that **the
closure may run after that place is gone**. Swift keeps what the closure uses alive for as long as the
closure lives. That is called **capturing**, and it has consequences for what a closure sees.

## A counter that outlives its function

```swift
// Counter.swift
func makeCounter() -> () -> Int {
    var count = 0
    return {
        count += 1
        return count
    }
}
let next = makeCounter()
print(next(), next(), next())
let other = makeCounter()
print(other())
```

```
ana@vm:~/sw/l03$ swift Counter.swift
1 2 3
1
```

`makeCounter` returned, and its local `count` would normally have disappeared with it. The closure
captured it instead, so each call to `next` finds the same `count` and adds one. `other` came from a
second call to `makeCounter`, so it captured a second `count`, which is why it starts again at 1.

## Captured by reference, unless you say otherwise

A closure captures the **variable**, not the value it had when the closure was written. A capture list,
in square brackets before the parameters, copies the value at that moment instead:

```swift
// CaptureList.swift
var goal = 300
let report = { print("goal \(goal)") }
let fixed = { [goal] in print("fixed \(goal)") }
goal = 360
report()
fixed()
```

```
ana@vm:~/sw/l03$ swift CaptureList.swift
goal 360
fixed 300
```

Both closures were written while `goal` was 300. `report` captured the variable and read 360 when it
finally ran; `fixed` copied 300 into its capture list and kept it. **Which one you want depends on what
the closure is for**: a report should show today's goal, and a record of what the goal was when a session
started should not move.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l03-capture\" aria-label=\"Left: two closures returned by two calls to makeCounter. next points at its own captured variable count, now 3; other points at a different count, now 1. Right: a variable goal holding 360. The closure report points at the variable and reads 360 when it runs. The closure fixed holds its own copy, 300, made when it was written.\"><defs><marker id=\"l03-capture-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">two calls, two variables</text><rect x=\"30\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">next</text><line x1=\"140\" y1=\"82\" x2=\"205\" y2=\"82\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l03-capture-ah-phosphor)\"></line><rect x=\"210\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">count</text><text x=\"265\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">3</text><text x=\"265\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">captured</text><rect x=\"30\" y=\"150\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">other</text><line x1=\"140\" y1=\"172\" x2=\"205\" y2=\"172\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l03-capture-ah-phosphor)\"></line><rect x=\"210\" y=\"150\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">count</text><text x=\"265\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"265\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">captured</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><rect x=\"400\" y=\"100\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"455\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">goal</text><text x=\"455\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">360</text><rect x=\"580\" y=\"50\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">report</text><line x1=\"580\" y1=\"80\" x2=\"515\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l03-capture-ah-phosphor)\"></line><text x=\"560\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the variable, read when it runs</text><rect x=\"580\" y=\"170\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">fixed</text><rect x=\"600\" y=\"198\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"635\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">300</text><text x=\"560\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a copy, made when it was written</text></svg>", "caption": "Each closure keeps what it captured alive. A variable is shared with the closure; a capture list keeps a copy."}
```

Capture lists come back in lesson 11, where `[weak self]` is the way to stop a closure from keeping an
object alive for ever. That is the most common reason to write one, and it needs lesson 5's classes first.

## Escaping

A closure passed to a function and only run inside it, as `repeatTwice` ran its action, is
**non-escaping**: it cannot outlive the call. Store it to run later and the compiler objects:

```swift
// Escaping.swift
var handlers: [() -> Void] = []
func later(_ action: () -> Void) {
    handlers.append(action)
}
```

```
ana@vm:~/sw/l03$ swiftc Escaping.swift -o escaping
Escaping.swift:4:21: error: converting non-escaping parameter 'action' to generic parameter 'Element' may allow it to escape
2 | var handlers: [() -> Void] = []
3 | func later(_ action: () -> Void) {
4 |     handlers.append(action)
  |                     `- error: converting non-escaping parameter 'action' to generic parameter 'Element' may allow it to escape
5 | }
6 | 
```

The message is wordy, and the important words are at the end: **"may allow it to escape"**. Putting the
closure in an array that lives on after `later` returns would let it escape the call. Writing the
parameter as `_ action: @escaping () -> Void` is how you say that this is intended, and it is also a
warning to whoever reads the signature: anything this closure captures will be kept alive for as long as
it is stored. Lesson 11 is about what that costs.
