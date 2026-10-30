---
title: Small protocols, composed
version: 1
---

**Protocol-oriented design describes each capability as a small protocol, and lets a type conform
to every one it has.** A type that takes time conforms to `Timed`; one with a grade conforms to
`Graded`; a mock exam conforms to both, and nothing about one capability is copied into the other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l10-tree\" aria-label=\"Left, a class tree: StudyItem at the top, StudySession and Exam below it, and MockExam under Exam only. A dashed arrow shows length copied from StudySession into MockExam, and a note under MockExam says minutes is 0, inherited. Right, a grid: three protocols, Titled, Timed and Graded, as columns, and StudySession, Exam and MockExam as rows, with a mark wherever the type conforms. MockExam has all three marks.\"><defs><marker id=\"l10-tree-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"175\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">one superclass each</text><rect x=\"105\" y=\"44\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">StudyItem</text><rect x=\"25\" y=\"124\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">StudySession</text><rect x=\"195\" y=\"124\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Exam</text><rect x=\"195\" y=\"204\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">MockExam</text><path d=\"M175 76 L95 124\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M175 76 L265 124\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M265 156 L265 204\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M95 156 L95 220 L193 220\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-tree-ah-amber)\" stroke-dasharray=\"5 4\"></path><text x=\"95\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">length, copied</text><text x=\"265\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">minutes: 0, inherited</text><path d=\"M372 20 L372 270\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"550\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">one protocol per capability</text><text x=\"520\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Titled</text><text x=\"590\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Timed</text><text x=\"660\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Graded</text><text x=\"392\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">StudySession</text><circle cx=\"520\" cy=\"110\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"590\" cy=\"110\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"660\" cy=\"110\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"392\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Exam</text><circle cx=\"520\" cy=\"155\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"590\" cy=\"155\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><circle cx=\"660\" cy=\"155\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"392\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">MockExam</text><circle cx=\"520\" cy=\"200\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"590\" cy=\"200\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"660\" cy=\"200\" r=\"7\" fill=\"var(--phosphor)\"></circle></svg>", "caption": "In the tree, a mock exam sits under one parent and copies the other. In the grid, it lists the capabilities it has, and each is checked."}
```

```swift
// Composed.swift
protocol Titled { var title: String { get } }
protocol Timed { var minutes: Int { get } }
protocol Graded { var grade: Int { get } }

struct StudySession: Titled, Timed {
    var title: String
    var minutes: Int
}

struct Exam: Titled, Graded {
    var title: String
    var grade: Int
}

struct MockExam: Titled, Timed, Graded {
    var title: String
    var minutes: Int
    var grade: Int
}

func totalMinutes(_ items: [any Timed]) -> Int {
    items.reduce(0) { $0 + $1.minutes }
}

func report(_ item: some Titled & Graded) -> String {
    "\(item.title): \(item.grade)%"
}

let timed: [any Timed] = [
    StudySession(title: "Optionals", minutes: 45),
    MockExam(title: "Generics", minutes: 60, grade: 70),
]
print("minutes this week:", totalMinutes(timed))
print(report(Exam(title: "Swift basics", grade: 80)))
print(report(MockExam(title: "Generics", minutes: 60, grade: 70)))
```

```
ana@vm:~/sw/l10$ swift Composed.swift
minutes this week: 105
Swift basics: 80%
Generics: 70%
```

The total is 105, and the mock exam's minutes counted. Compare the parts with section 02:

- **Nothing answers for things it does not have.** `Exam` is not `Timed`, so it cannot be put in
  `timed` by mistake, and there is no `0` minutes to inherit. An exam in that array is a compile
  error, which is exactly where the wrong total belongs.
- **`MockExam` lists what it is**, and the compiler holds it to all of it. Leaving `minutes` out
  would be lesson 8's "does not conform", not a silent zero.
- **The types are structs.** No `init` had to call `super.init`, and each value gets its memberwise
  initialiser from lesson 6 and value semantics from lesson 5.

## &: a type that is several things

`Titled & Graded` is a **protocol composition**: a type that conforms to both. `report` takes `some
Titled & Graded`, lesson 9's generic shorthand, so it accepts an `Exam` and a `MockExam` and refuses
a `StudySession`. A composition used often can be named, `typealias Assessed = Titled & Graded`, and
the standard library does the same: `Codable`, lesson 13's subject, is `Encodable & Decodable`.

## Small means small

A protocol with one requirement looks like overhead, and it is the opposite. **The fewer
requirements a protocol has, the more types can honestly conform to it**, and the more functions
can ask for exactly what they use. `totalMinutes` needs minutes and nothing else, so it asks for
`Timed` and nothing else. A single `StudyItem` protocol with `minutes`, `grade` and `title` would be
the base class of section 02 again, with the same guesses.
