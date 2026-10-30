---
title: Actors, which take one call at a time
version: 1
---

**An actor is a type whose state only its own code can touch, one call at a time.** It is declared
like a class, with the word `actor` instead, and it is a reference type like a class: everybody who
holds one holds the same one. What it adds is the rule. Here is `WeekTotal` again, with one word
changed and one `await` added:

```schooling-example
{"language": "swift", "file": "Actor.swift", "parts": [{"code": "// Actor.swift\nactor WeekTotal {\n    var minutes = 0\n    func add(_ m: Int) { minutes += m }\n}", "note": "**`actor` in place of `final class`**, and nothing else in the type changes. `minutes` is now **isolated** to the actor: only code running on the actor may touch it."}, {"code": "func countWeek() async -> Int {\n    let week = WeekTotal()\n    await withTaskGroup(of: Void.self) { group in\n        for _ in 1...8 {\n            group.addTask {\n                for _ in 1...100_000 {\n                    await week.add(1)\n                }\n            }\n        }\n    }\n    return await week.minutes", "note": "The same eight tasks. Each call to `add` now has an **`await`**, because a call into an actor from outside may have to wait for the calls ahead of it. Reading `minutes` at the end is a crossing too, and takes one as well."}, {"code": "}\n\nfor _ in 1...3 {\n    print(\"expected 800000, got \\(await countWeek())\")\n}", "note": "Three runs, as before, compiled this time with `-swift-version 6`, which raised no error."}]}
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Actor.swift -o actor && ./actor
expected 800000, got 800000
expected 800000, got 800000
expected 800000, got 800000
```

**Right three times, in the Swift 6 mode, with no lock written anywhere.** Each `await week.add(1)` is
a request to the actor; the actor runs the requests it receives one after another, so two `+=` on
`minutes` never overlap. The eight tasks still run side by side. What they no longer do is touch
`minutes` themselves.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l15-actor\" aria-label=\"Four tasks on the left each send await week.add(1) to an actor. Inside the actor, calls wait in a line, one add runs at a time, and only that running call changes minutes.\"><defs><marker id=\"l15-actor-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l15-actor-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">task 1</text><path d=\"M140 56 L250 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah2)\"></path><rect x=\"20\" y=\"88\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">task 2</text><path d=\"M140 104 L250 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah2)\"></path><rect x=\"20\" y=\"136\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">task 3</text><path d=\"M140 152 L250 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah2)\"></path><rect x=\"20\" y=\"184\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">task 4</text><path d=\"M140 200 L250 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah2)\"></path><text x=\"195\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">await week.add(1)</text><rect x=\"255\" y=\"60\" width=\"420\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"465\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">actor WeekTotal</text><text x=\"330\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waiting in line</text><rect x=\"275\" y=\"110\" width=\"110\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"330\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add(1)</text><rect x=\"275\" y=\"140\" width=\"110\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"330\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add(1)</text><rect x=\"275\" y=\"170\" width=\"110\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"330\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add(1)</text><path d=\"M385 150 L450 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah)\"></path><rect x=\"455\" y=\"128\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add(1)</text><text x=\"500\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">running</text><path d=\"M545 150 L580 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah)\"></path><rect x=\"585\" y=\"128\" width=\"75\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"622\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes</text><text x=\"622\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">+= 1</text><text x=\"465\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper)\">one call at a time touches the state</text><text x=\"465\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the tasks run side by side; only the actor touches minutes</text></svg>", "caption": "An actor serialises the calls it receives: the tasks still run in parallel, and the state is touched by one call at a time."}
```

## Crossing the boundary takes an await

From outside the actor, every method call and every read of a property is a request that may have to
wait its turn, and the compiler insists on `await` for it. A write from outside is not a request at
all, and is refused whatever you write:

```swift
// Outside.swift
actor WeekTotal {
    var minutes = 0
    func add(_ m: Int) { minutes += m }
}

let week = WeekTotal()
week.add(45)
week.minutes = 0
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Outside.swift -o outside
Outside.swift:8:6: error: call to actor-isolated instance method 'add' in a synchronous main actor-isolated context [#ActorIsolatedCall]
 2 | actor WeekTotal {
 3 |     var minutes = 0
 4 |     func add(_ m: Int) { minutes += m }
   |          `- note: calls to instance method 'add' from outside of its actor context are implicitly asynchronous
 5 | }
 6 | 
 7 | let week = WeekTotal()
 8 | week.add(45)
   |      `- error: call to actor-isolated instance method 'add' in a synchronous main actor-isolated context [#ActorIsolatedCall]
 9 | week.minutes = 0
10 | 

Outside.swift:9:6: error: actor-isolated property 'minutes' can not be mutated from the main actor
 1 | // Outside.swift
 2 | actor WeekTotal {
 3 |     var minutes = 0
   |         `- note: mutation of this property is only permitted within the actor
 4 |     func add(_ m: Int) { minutes += m }
 5 | }
   :
 7 | let week = WeekTotal()
 8 | week.add(45)
 9 | week.minutes = 0
   |      `- error: actor-isolated property 'minutes' can not be mutated from the main actor
10 | 

[#ActorIsolatedCall]: <https://docs.swift.org/compiler/documentation/diagnostics/actor-isolated-call>
```

The first error is the rule for calls: **a call to an actor's method from outside is implicitly
asynchronous**, as the note puts it, and a synchronous context cannot make one. `await week.add(45)`
in an `async` context fixes it. The second has no `await` fix: **only the actor's own code may change
its properties.** A caller that wants `minutes` set to zero asks the actor to do it, by calling a
method such as `reset()` that the actor provides.

Inside the actor nothing changes: `add` reads and writes `minutes` with no `await`, because code that
is already running on the actor has the actor to itself. **The boundary is the actor's edge, and the
`await` marks every crossing of it.** Both errors mention the main actor, because the top level of a
program runs on it; section 06 is about what that means.

## What it costs

Each `await` to an actor is a possible suspension, and `Actor.swift` made 800,000 of them per run.
That is the price of the protection, and it is why a counter is a poor use of one. An actor earns its
place when it guards state that several parts of a program share, such as a planner's cache of
courses or the connection to a server, and each call does a meaningful amount of work.
