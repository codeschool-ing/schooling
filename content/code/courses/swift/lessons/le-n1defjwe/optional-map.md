---
title: Transforming without unwrapping
version: 1
---

Sometimes the question is not "is there a value?" but "if there is one, change it into something
else". A typed duration in minutes should become seconds; a missing one should stay missing. **An
optional has a `map` method that applies a function to the value inside, if there is one, and keeps
the `nil` if there is not.** The result is still optional.

```swift
// OptionalMap.swift
func seconds(_ minutes: Int) -> Int {
    minutes * 60
}
let typed: Int? = Int("45")
let missing: Int? = Int("forty")
print(String(describing: typed.map(seconds)))
print(String(describing: missing.map(seconds)))
let entries = ["45", "forty", "30"]
let numbers = entries.compactMap { Int($0) }
print(numbers)
```

```
ana@vm:~/sw/l02$ swift OptionalMap.swift
Optional(2700)
nil
[45, 30]
```

`typed.map(seconds)` gave `Optional(2700)`, and the same call on `missing` gave `nil` without calling
`seconds` at all. It is the same idea as `?.`: **do this to the value if it is there, otherwise pass
the `nil` along**, written for a function rather than a property.

## Dropping the nils from a list

The last two lines take a list of strings, try to turn each into an `Int`, and keep only the ones that
worked. `compactMap` does exactly that: it runs the code in braces on every item, gets an `Int?` back
each time, and **collects the values while discarding the `nil`s**. The result is `[45, 30]`, an array
of plain `Int`.

The braces `{ Int($0) }` are a closure, a small function written in place, with `$0` standing for each
item. Lesson 3 explains closures and that `$0` properly, and lesson 4 is about `map`, `filter` and
their relatives on arrays. For now it is enough to recognise `compactMap` as "convert each, keep the
ones that worked", which is the loop of section 03 in one line.

## Four ways, one rule

Each way of opening an optional decides what happens to `nil`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-four-ways\" aria-label=\"A table of four ways to open the optional Int(typed), which holds 45 or nil. With if let, 45 is available inside the braces, and nil skips them. With guard let, 45 is available below the guard, and nil leaves the function. With ?? 0, 45 gives 45 and nil gives 0, the default. With an exclamation mark, 45 gives 45 and nil stops the program.\"><rect x=\"20\" y=\"120\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Int(typed)</text><text x=\"85\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">45, or nil</text><text x=\"260\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">write</text><text x=\"450\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">with 45</text><text x=\"615\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">with nil</text><rect x=\"180\" y=\"50\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">if let m = …</text><line x1=\"150\" y1=\"150\" x2=\"180\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">m is 45 in the braces</text><text x=\"615\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the braces are skipped</text><rect x=\"180\" y=\"110\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">guard let m = … else</text><line x1=\"150\" y1=\"150\" x2=\"180\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"450\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">m is 45 below it</text><text x=\"615\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the function leaves</text><rect x=\"180\" y=\"170\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">… ?? 0</text><line x1=\"150\" y1=\"150\" x2=\"180\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"450\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">45</text><text x=\"615\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">0, the default</text><rect x=\"180\" y=\"230\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">…!</text><line x1=\"150\" y1=\"150\" x2=\"180\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"450\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">45</text><text x=\"615\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the program stops</text></svg>", "caption": "Four ways to open an optional. They agree about 45 and differ only in what nil does."}
```

**Pick by what `nil` means in the place you are writing.** If it means skip, `if let`. If it means the
function cannot go on, `guard let`. If it means a default that is as good as a value, `??`. If it means
the program is broken, `!` — and then be sure.
