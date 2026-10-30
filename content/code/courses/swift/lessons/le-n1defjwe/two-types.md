---
title: Two types where you expected one
version: 1
---

Lesson 1 ended on `Int("45")`, which gave `Optional(45)` rather than `45`. That was not a quirk of
`Int`. **Swift splits every type in two: `String`, which always holds a string, and `String?`, which
holds a string or nothing at all.** Nothing is written `nil`, and only the second type accepts it.

In many languages any object can be null, and nothing in the code tells you which ones might be.
The compiler lets you ask an absent value for its length, and the program finds out when it runs. A
student's planner has notes that are missing far more often than they are present, so that crash is
the commonest one there is. Swift moves the question to compile time:

```swift
// TwoMistakes.swift
let course: String = nil
let note: String? = "read chapter 3"
print(note.count)
```

```
ana@vm:~/sw/l02$ swiftc TwoMistakes.swift -o twomistakes
TwoMistakes.swift:2:22: error: 'nil' cannot initialize specified type 'String'
1 | // TwoMistakes.swift
2 | let course: String = nil
  |             |        `- error: 'nil' cannot initialize specified type 'String'
  |             `- note: add '?' to form the optional type 'String?'
3 | let note: String? = "read chapter 3"
4 | print(note.count)

TwoMistakes.swift:4:7: error: value of optional type 'String?' must be unwrapped to refer to member 'count' of wrapped base type 'String'
2 | let course: String = nil
3 | let note: String? = "read chapter 3"
4 | print(note.count)
  |       |- error: value of optional type 'String?' must be unwrapped to refer to member 'count' of wrapped base type 'String'
  |       |- note: chain the optional using '?' to access member 'count' only for non-'nil' base values
  |       `- note: force-unwrap using '!' to abort execution if the optional value contains 'nil'
5 | 
```

**Two errors, and each is one half of the rule.** The first: a `String` cannot be `nil`, and the
note suggests adding `?` to make it a `String?`. The second: `note` is a `String?`, so it may be
`nil`, and asking `nil` for its `count` has no answer. The compiler refuses to guess and lists two
ways forward, a `?` and a `!`, which are sections 05 and 06 of this lesson.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l02-two-types\" aria-label=\"Two boxes. The left, String, holds strings such as &quot;Swift&quot;, &quot;&quot; and &quot;read chapter 3&quot;, and is never nil. The right, String?, holds the same strings and nil as well. An arrow from String to String? is marked free: every String is a String?. An arrow back is marked: back needs an answer for nil, with the four answers if let, guard let, ?? and !.\"><defs><marker id=\"l02-two-types-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-two-types-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"40\" width=\"230\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">String</text><text x=\"145\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Swift&quot;</text><text x=\"145\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;&quot;</text><text x=\"145\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;read chapter 3&quot;</text><text x=\"145\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">never nil</text><rect x=\"460\" y=\"40\" width=\"230\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">String?</text><rect x=\"480\" y=\"78\" width=\"190\" height=\"82\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"575\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Swift&quot;</text><text x=\"575\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;&quot;</text><text x=\"575\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;read chapter 3&quot;</text><text x=\"575\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">nil</text><text x=\"575\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a String, or nil</text><line x1=\"265\" y1=\"100\" x2=\"455\" y2=\"100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-two-types-ah-phosphor)\"></line><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">free: every String is a String?</text><line x1=\"455\" y1=\"160\" x2=\"265\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#l02-two-types-ah-amber)\"></line><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">back needs an answer for nil:</text><text x=\"360\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">if let, guard let, ??, !</text></svg>", "caption": "Two types, and the arrow between them is free in one direction only."}
```

## A String is always a String?

The arrow in the figure only goes one way for free. **Every `String` can be used where a `String?`
is expected**, because a string is one of the things a `String?` may hold. Going back needs an
answer for the `nil` case, and the rest of this lesson is the four answers Swift offers.

```swift
// Nulls.swift
let course: String = "Swift"
var note: String? = nil
print(note == nil)
note = course
print(note == nil, note == "Swift")
let empty: String? = ""
print(empty == nil)
```

```
ana@vm:~/sw/l02$ swift Nulls.swift
true
false true
false
```

`note` started empty, received a string from `course` with no conversion written, and compared
equal to `"Swift"` from then on. The last line is the distinction worth keeping: **`""` is a
string, with nothing in it; `nil` is no string at all.** A note the student cleared and a note they
never wrote are two different facts, and a `String?` can say which.

## What the ? is made of

`String?` is shorthand. The type underneath is `Optional<String>`, an enumeration with exactly two
cases: `.some`, which carries a value, and `.none`, which is what `nil` means.

```swift
// Spelled.swift
let typed: Optional<Int> = .some(45)
let missing: Int? = .none
print(typed == 45, missing == nil, type(of: typed))
```

```
ana@vm:~/sw/l02$ swift Spelled.swift
true true Optional<Int>
```

You will almost never write `.some` or `.none` yourself, and you do not need to yet. It is worth
recognising, because the compiler's messages and `print` both use the long name, and lesson 7 comes
back to `Optional` as the first enum you ever used.
