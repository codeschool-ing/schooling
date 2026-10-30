---
title: A session's life as a state machine
version: 1
---

A study session goes through stages: planned, then running, then done, and a planned session may be
skipped instead. A struct with `isRunning`, `isDone` and `isSkipped` booleans allows eight
combinations of which four make sense, and nothing stops a session from being both done and skipped.
**An enum with a case per stage allows exactly the stages there are**, and associated values carry
what each stage knows:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l07-states\" aria-label=\"A state diagram. Four states in boxes: planned with minutes, running with planned minutes and a start time, done with minutes, and skipped. Arrows: start goes from planned to running, finish goes from running to done, skip goes from planned to skipped. A note says that any other event is refused and the state stays as it is.\"><defs><marker id=\"l07-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l07-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"30\" y=\"60\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">.planned</text><text x=\"120\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"270\" y=\"60\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">.running</text><text x=\"360\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">planned, startedAt</text><rect x=\"510\" y=\"60\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">.done</text><text x=\"600\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"270\" y=\"170\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">.skipped</text><path d=\"M210 88 L268 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-ah)\"></path><text x=\"239\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">start(at:)</text><path d=\"M450 88 L508 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-ah)\"></path><text x=\"479\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">finish(minutes:)</text><path d=\"M120 116 L120 198 L268 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-ah2)\"></path><text x=\"150\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">skip</text><text x=\"600\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">any other event: refused, the state stays</text></svg>", "caption": "Three moves are allowed and every other pair of state and event is refused. Each state carries only what is true of it."}
```

The transitions belong in the type, as a `mutating` method that takes an event and decides what the
next state is. A switch on the pair, state and event, lists the moves that are allowed, and everything
else is refused rather than half-done:

```swift
// Status.swift
enum Status {
    case planned(minutes: Int)
    case running(planned: Int, startedAt: String)
    case done(minutes: Int)
    case skipped
}
enum Event {
    case start(at: String)
    case finish(minutes: Int)
    case skip
}
extension Status {
    mutating func handle(_ event: Event) -> Bool {
        switch (self, event) {
        case let (.planned(minutes), .start(at)):
            self = .running(planned: minutes, startedAt: at)
        case let (.running, .finish(minutes)):
            self = .done(minutes: minutes)
        case (.planned, .skip):
            self = .skipped
        default:
            return false
        }
        return true
    }
}
var status = Status.planned(minutes: 45)
let events: [Event] = [.finish(minutes: 10), .start(at: "19:00"), .skip, .finish(minutes: 50)]
for event in events {
    let accepted = status.handle(event)
    print(accepted ? "accepted" : "refused ", event, "->", status)
}
```

```
ana@vm:~/sw/l07$ swift Status.swift
refused  finish(minutes: 10) -> planned(minutes: 45)
accepted start(at: "19:00") -> running(planned: 45, startedAt: "19:00")
refused  skip -> running(planned: 45, startedAt: "19:00")
accepted finish(minutes: 50) -> done(minutes: 50)
```

Four events, two refused. **Finishing a session that never started was refused**, and so was skipping
one already running; in both cases the status stayed as it was. `self = …` replaces the whole value
with a new case, which is how a `mutating` method of an enum changes it. `case let (…)` binds every
name in the pattern at once, so `minutes` and `at` come out of two different enums in one line.

The `default` here is deliberate and the rule of section 04 still holds: this switch is over pairs,
and listing every refused pair, nine of the twelve, would hide the three that matter. What `default`
costs is exactly the warning section 04 described. A new `Status` case is still caught wherever a
switch over `Status` alone lists them, such as a screen that shows each state, and that switch is
where the new case gets its meaning.

This is the shape `ios-apps` gives a session on screen, and the shape lesson 13 writes to JSON.
