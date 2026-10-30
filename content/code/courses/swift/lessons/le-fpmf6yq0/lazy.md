---
title: Lazy properties
version: 1
---

Some values are expensive to build and may never be needed: a summary of a long history, a parsed
file, a formatter. **A `lazy` property is stored, but its initial value is computed the first time
it is read, and never again.** Until then the instance carries no value for it at all:

```swift
// Lazy.swift
struct Report {
    let sessions: [Int]
    lazy var summary: String = {
        print("building the summary")
        return "\(sessions.count) sessions, \(sessions.reduce(0, +)) minutes"
    }()
}
var report = Report(sessions: [45, 30, 60])
print("report made")
print(report.summary)
print(report.summary)
```

```
ana@vm:~/sw/l06$ swift Lazy.swift
report made
building the summary
3 sessions, 135 minutes
3 sessions, 135 minutes
```

The initial value is a closure called on the spot, `{ … }()`, which is the usual way to write an
initial value that needs several lines. **"building the summary" was printed once**, at the first
read and after "report made", and the second read found the stored string. A lazy initial value may
use the instance's other properties, `sessions` here, which an ordinary default value may not,
because by the time anything reads a lazy property the instance exists.

## Reading it changes the instance

The first read of a lazy property stores a value, which is a change. For a struct, a change needs a
`var`, and so a lazy property cannot be read through a `let`:

```swift
// LazyLet.swift
struct Report {
    let sessions: [Int]
    lazy var summary: String = "\(sessions.count) sessions"
}
let report = Report(sessions: [45, 30])
print(report.summary)
```

```
ana@vm:~/sw/l06$ swiftc LazyLet.swift -o lazylet
LazyLet.swift:7:14: error: cannot use mutating getter on immutable value: 'report' is a 'let' constant
4 |     lazy var summary: String = "\(sessions.count) sessions"
5 | }
6 | let report = Report(sessions: [45, 30])
  | `- note: change 'let' to 'var' to make it mutable
7 | print(report.summary)
  |              `- error: cannot use mutating getter on immutable value: 'report' is a 'let' constant
8 | 
```

"Mutating getter" is the compiler's name for a read that writes. That is the exception section 02
promised: **`lazy` works on a class freely and on a struct only through a `var`**, which makes it far
more common in classes. It is also why a lazy property is always `var`, never `let`.

## Which kind runs code, and when

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-kinds\" aria-label=\"A table drawn as a grid. Rows: stored, computed, observed, lazy and static properties. Columns: what happens at initialisation, on a read and on a write. Stored: stores the value, returns it, stores it. Computed: nothing, runs get, runs set. Observed: stores without running the observers, returns it, runs willSet then stores then didSet. Lazy: nothing, builds the value on the first read, stores it. Static: nothing per instance, initialised once for the type on its first use, stores it.\"><text x=\"80.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">kind</text><text x=\"235.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">at init</text><text x=\"410.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">on read</text><text x=\"595.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">on write</text><rect x=\"23\" y=\"40\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stored</text><rect x=\"143\" y=\"40\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stores the value</text><rect x=\"333\" y=\"40\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">returns it</text><rect x=\"493\" y=\"40\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stores it</text><rect x=\"23\" y=\"80\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">computed</text><rect x=\"143\" y=\"80\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing</text><rect x=\"333\" y=\"80\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">runs get</text><rect x=\"493\" y=\"80\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">runs set</text><rect x=\"23\" y=\"120\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">observed</text><rect x=\"143\" y=\"120\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stores, no observer</text><rect x=\"333\" y=\"120\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">returns it</text><rect x=\"493\" y=\"120\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">willSet, store, didSet</text><rect x=\"23\" y=\"160\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lazy</text><rect x=\"143\" y=\"160\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing</text><rect x=\"333\" y=\"160\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">first read: builds it</text><rect x=\"493\" y=\"160\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stores it</text><rect x=\"23\" y=\"200\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">static</text><rect x=\"143\" y=\"200\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing per instance</text><rect x=\"333\" y=\"200\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">first use: initialises</text><rect x=\"493\" y=\"200\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stores it</text></svg>", "caption": "The same three moments for each kind of property. The boxes drawn in amber are where code of yours runs."}
```

A lazy property is computed once and then behaves like a stored one; a computed property runs on
every read; an observed property runs on every write after initialisation. Choosing between them is
choosing when the code runs.
