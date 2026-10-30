---
title: An if in a body is a branch in a type
version: 1
---

**When a body says `if done { … } else { … }`, its type holds both branches, and which one is shown
is a value inside it.** SwiftUI therefore knows, when `done` flips, that one branch went away and the
other arrived, and treats them as two different views: the one that left is removed with any state it
had, and the one that arrived starts fresh. That is called **structural identity**, identity given by
a view's position in the type, and lesson 8 sets beside it the other kind, explicit identity from an
`id`.

The builder of section 06 joined strings, so it lost the shape. This one keeps the shape in the type,
the way SwiftUI's does. Save it as `branches.swift` in `~/l03`:

```schooling-example
{"language": "swift", "file": "branches.swift", "parts": [{"code": "// branches.swift: a builder that keeps the shape in the type, as SwiftUI's does\nstruct Text { let words: String }\nstruct Image { let name: String }\nstruct Pair<A, B> { let first: A; let second: B }\nenum Either<First, Second> { case first(First), second(Second) }\n", "note": "Two stand-ins for views, and two generic types for shapes: `Pair` holds two things side by side, and `Either` holds one of two, saying which."}, {"code": "@resultBuilder\nenum ShapeBuilder {\n    static func buildBlock<A>(_ a: A) -> A { a }\n    static func buildBlock<A, B>(_ a: A, _ b: B) -> Pair<A, B> { Pair(first: a, second: b) }\n    static func buildEither<F, S>(first: F) -> Either<F, S> { .first(first) }\n    static func buildEither<F, S>(second: S) -> Either<F, S> { .second(second) }\n}\n", "note": "The builder is generic, so every result's type is built from the types of its parts. An `if`/`else` becomes an `Either` of the two branch types, whichever branch runs."}, {"code": "func row(done: Bool) -> some Any {\n    func build<T>(@ShapeBuilder _ content: () -> T) -> T { content() }\n    return build {\n        Text(words: \"SQL Databases\")\n        if done {\n            Image(name: \"checkmark\")\n        } else {\n            Text(words: \"50 min\")\n        }\n    }\n}\n", "note": "A row for one course: its title, then a checkmark if the course's work is done and the minutes if not. `some Any` is section 03's rule again, one hidden type, and it compiles because the builder made one."}, {"code": "print(type(of: row(done: true)))\nprint(type(of: row(done: false)))\nprint(row(done: true))\nprint(row(done: false))\n", "note": "The type of both rows, then both values."}]}
```

```
ana@vm:~/l03$ swift branches.swift
Pair<Text, Either<Image, Text>>
Pair<Text, Either<Image, Text>>
Pair<Text, Either<Image, Text>>(first: branches.Text(words: "SQL Databases"), second: branches.Either<branches.Image, branches.Text>.first(branches.Image(name: "checkmark")))
Pair<Text, Either<Image, Text>>(first: branches.Text(words: "SQL Databases"), second: branches.Either<branches.Image, branches.Text>.second(branches.Text(words: "50 min")))
```

**The two types are the same, `Pair<Text, Either<Image, Text>>`, and the values differ in one word:
`.first` against `.second`.** That is all SwiftUI needs to see that the title stayed where it was and
the second slot changed branch. The title keeps its identity; the checkmark and the minutes are two
different views in two different slots.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l03-branches\" aria-label=\"The type Pair&lt;Text, Either&lt;Image, Text&gt;&gt; drawn as a tree. Pair has two slots: the first holds Text, the title; the second holds Either, which has two branches, first holding Image, the checkmark, and second holding Text, the minutes. When done is true the first branch is filled; when it is false the second. The title is in the same slot either way.\"><defs><marker id=\"l03-branches-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l03-branches-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-branches-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l03-branches-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"280\" y=\"20\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Pair</text><rect x=\"110\" y=\"100\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Text</text><text x=\"200\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the title, always here</text><rect x=\"430\" y=\"100\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">Either</text><path d=\"M330 54 L220 98\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-branches-ah-wire)\"></path><path d=\"M390 54 L490 98\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-branches-ah-wire)\"></path><rect x=\"340\" y=\"180\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.first: Image</text><text x=\"420\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">when done is true</text><rect x=\"530\" y=\"180\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"615\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.second: Text</text><text x=\"615\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">when done is false</text><path d=\"M490 134 L430 178\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-branches-ah-amber)\"></path><path d=\"M530 134 L600 178\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-branches-ah-amber)\"></path></svg>", "caption": "Both values have this one type. Flipping done moves the second slot from one branch to the other, and the view in it is a different view."}
```

## The trap it sets

Because a branch is a different view, **flipping an `if` resets whatever the branch held.** Suppose
`CourseDetailView` showed a text field for a note in one branch and the same field, with a different
colour, in the other. Typing half a note and flipping the condition would destroy the field and make a
new one, and the half note would be gone. When only a value differs between two branches, the fix is
one view with a changing value instead of two views: one field whose colour depends on `done`. Lesson
5 meets the same trap in the form of a modifier wrapped in an `if`, and lesson 11 sees what it does to
an animation.

Nothing in this section ran SwiftUI. The program above ran on Linux, and the claim that SwiftUI treats
the branches of an `if` as different views comes from Apple's WWDC21 session *Demystify SwiftUI*,
which is about exactly this.
