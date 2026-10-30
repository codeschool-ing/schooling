---
title: Which body runs
version: 1
---

Section 05 ended on a rule: list a member in the protocol if a conforming type may replace it. This
section is why. **The same call on the same value can run two different bodies**, depending on the
type the code holds it as, and nothing in the call shows it.

```swift
// Dispatch.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

extension Describable {
    func summary() -> String { "\(title) (no details)" }
    func headline() -> String { "== \(title) ==" }
}

struct Course: Describable {
    var title: String
    func summary() -> String { "\(title): 20 lessons" }
    func headline() -> String { "** \(title) **" }
}

let swift = Course(title: "Swift")
print(swift.summary(), "|", swift.headline())

let item: any Describable = swift
print(item.summary(), "|", item.headline())
```

```
ana@vm:~/sw/l08$ swift Dispatch.swift
Swift: 20 lessons | ** Swift **
Swift: 20 lessons | == Swift ==
```

The first line is what anyone would expect: `Course` wrote both methods and its own bodies ran.
The second line is the same value, held as `any Describable`, and **`headline()` ran the
extension's body, not the struct's**. `summary()` did not change.

## Requirements are looked up, extensions are not

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l08-dispatch\" aria-label=\"Two calls on the same value held as any Describable. item.summary() goes through the conformance table that Course filled in, and reaches Course's own summary. item.headline() has no entry in the table, so the compiler picked the extension's headline at compile time; Course's own headline, drawn dashed, is not reached through the protocol.\"><defs><marker id=\"l08-dispatch-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-dispatch-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">item.summary()</text><rect x=\"20\" y=\"170\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">item.headline()</text><rect x=\"270\" y=\"22\" width=\"200\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">conformance table</text><text x=\"370\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">summary() → Course</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Course.summary()</text><rect x=\"520\" y=\"105\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"610\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">Course.headline()</text><text x=\"610\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">not reached through the protocol</text><rect x=\"520\" y=\"175\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">extension headline()</text><path d=\"M220 58 L268 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l08-dispatch-ah-phosphor)\"></path><path d=\"M470 58 L518 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l08-dispatch-ah-phosphor)\"></path><path d=\"M220 190 L518 193\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l08-dispatch-ah-amber)\"></path><text x=\"370\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">looked up while the program runs</text><text x=\"370\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">chosen when it compiles</text></svg>", "caption": "A requirement is found in the table each conformance fills in. A method that lives only in the extension is chosen from the type the code can see."}
```

`summary()` is a **requirement**. Every type that conforms to `Describable` records which body meets
each requirement, in a table the compiler builds for that conformance, and a call through
`any Describable` looks the body up in that table while the program runs. So the call finds
`Course`'s method, and it would find a default only for a type that wrote none.

`headline()` is **not a requirement**; it exists only in the extension. A call through
`any Describable` has no table entry to look up, so the compiler decides at compile time, from the
type it can see, which is the protocol. The struct's `headline()` is a separate method that happens
to have the same name, and it is reached only when the code holds a `Course`. The first is called
**dynamic dispatch** and the second **static dispatch**.

## Avoiding the surprise

Nothing is wrong with the language here; the program does what the declarations say. The defect is
in a design where a type means to customise a member and the protocol never asked for it. Two habits
remove it:

- **every member a conforming type may write its own version of goes in the protocol**, with its
  default in the extension;
- a member in an extension alone is a **helper** built from the requirements, and no conforming type
  should declare one with the same name.

Lesson 10 builds whole designs out of protocol extensions, and this rule is what keeps them
predictable.
