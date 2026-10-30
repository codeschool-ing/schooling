---
title: The dollar sign, a wrapper's second face
version: 1
---

`$minutes` in section 02's SwiftUI view is not a different variable that somebody declared. **A
wrapper may offer a second value, its `projectedValue`, and the compiler names it with a `$`** in front
of the property. What that value is depends entirely on the wrapper: SwiftUI's `@State` projects a
`Binding`, a handle another view can read and write through, which is how the `Stepper` changes
`minutes`. Ours can project anything useful.

The planner would like to know when a value was clamped, so that it can tell the student that 900
minutes is more than one session can hold. The wrapper is the only code that knows, so it remembers,
and projects it:

```swift
// Projected.swift
@propertyWrapper
struct Clamped {
    private var value: Int
    private(set) var projectedValue = false
    let range: ClosedRange<Int>

    init(wrappedValue: Int, _ range: ClosedRange<Int>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }

    var wrappedValue: Int {
        get { value }
        set {
            value = min(max(newValue, range.lowerBound), range.upperBound)
            projectedValue = value != newValue
        }
    }
}

struct StudySession {
    @Clamped(0...600) var minutes = 45
}

var session = StudySession()
for typed in [90, 900, 600] {
    session.minutes = typed
    if session.$minutes {
        print("\(typed) is too long: kept \(session.minutes)")
    } else {
        print("\(typed) minutes")
    }
}
```

```
ana@vm:~/sw/l16$ swift Projected.swift
90 minutes
900 is too long: kept 600
600 minutes
```

**`session.$minutes` is a `Bool`**, because `projectedValue` is one. The compiler turned `$minutes`
into `_minutes.projectedValue`, the same way it turns `minutes` into `_minutes.wrappedValue`. The 600
that came last was accepted as it was, so the flag went back to `false`: it describes the most recent
write, not the history.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l16-wrapper\" aria-label=\"On the left, the one line you write: @Clamped(0...600) var minutes. Arrows lead to three generated declarations on the right: a private stored property _minutes holding the Clamped wrapper, a computed minutes whose getter and setter go to _minutes.wrappedValue, and $minutes, which reads _minutes.projectedValue.\"><defs><marker id=\"l16-wrap-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what you write</text><rect x=\"20\" y=\"38\" width=\"270\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"155\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@Clamped(0...600) var minutes</text><text x=\"400\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what the compiler generates</text><rect x=\"400\" y=\"38\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">private var _minutes: Clamped</text><text x=\"550\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the wrapper itself, hidden</text><path d=\"M290 55 C340 55 350 60 398 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-wrap-ah)\"></path><rect x=\"400\" y=\"98\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">var minutes: Int</text><text x=\"550\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get/set → _minutes.wrappedValue</text><path d=\"M290 55 C340 55 350 120 398 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-wrap-ah)\"></path><rect x=\"400\" y=\"158\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">var $minutes: Bool</text><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get → _minutes.projectedValue</text><path d=\"M290 55 C340 55 350 180 398 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-wrap-ah)\"></path><text x=\"155\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read minutes</text><text x=\"155\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">= call the getter</text><text x=\"155\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read $minutes</text><text x=\"155\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">= ask the wrapper</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--amber)\">one line in, three declarations out</text></svg>", "caption": "A property wrapper expanded: the storage is the wrapper, the property goes through wrappedValue, and the dollar name through projectedValue."}
```

`private(set)` on `projectedValue` means callers may read it and only the wrapper may change it. A
caller that could set "was clamped" to whatever it liked would make the flag mean nothing.

## Reading someone else's wrapper

When you meet an `@` you do not know, three questions find out what it does, and the answers are in
the wrapper's declaration, not at the place you use it:

| question | where to look |
|---|---|
| what does reading the property do? | the getter of `wrappedValue` |
| what does writing it do? | the setter of `wrappedValue`, if it has one |
| what does `$name` give? | the type of `projectedValue`, if there is one |

For SwiftUI the answers are in Apple's documentation, and `ios-apps` asks them of `@State`,
`@Binding` and `@Environment` in turn. The mechanism under each is the one you have just written.
