---
title: Default implementations
version: 1
---

Section 04 added members to one type. **An extension of a protocol adds members to every type that
conforms to it**. When one of those members has the same name and type as a requirement, it becomes
the **default implementation**: a conforming type that writes nothing for that requirement gets the
default, and one that writes its own keeps its own.

```schooling-example
{"language": "swift", "file": "Defaults.swift", "parts": [{"code": "// Defaults.swift\nprotocol Timed {\n    var title: String { get }\n    var minutes: Int { get }\n    func summary() -> String\n}", "note": "Two properties and a method. Nothing here says how `summary()` is written, so every conforming type would have to write one."}, {"code": "extension Timed {\n    func summary() -> String { \"\\(title), \\(minutes) min\" }\n    var isLong: Bool { minutes >= 60 }\n}", "note": "A protocol extension. `summary()` gets a default body built only from the two requirements, and `isLong` is a new member every conforming type receives for free."}, {"code": "struct StudySession: Timed {\n    var title: String\n    var minutes: Int\n}", "note": "Meets the two properties and writes no `summary()` at all: the default fills the requirement."}, {"code": "struct Exam: Timed {\n    var title: String\n    var minutes: Int\n    func summary() -> String { \"EXAM \\(title) (\\(minutes) min)\" }\n}", "note": "Writes its own `summary()`, which replaces the default for this type alone."}, {"code": "let week: [any Timed] = [\n    StudySession(title: \"Optionals\", minutes: 45),\n    Exam(title: \"Swift basics\", minutes: 90),\n]\nfor item in week {\n    print(item.summary(), item.isLong)\n}", "note": "Through `any Timed`, each element answers with its own type's `summary()`, default or not."}], "output": "Optionals, 45 min false\nEXAM Swift basics (90 min) true"}
```

`swift Defaults.swift` runs it, and the output is two lines, one per element. The session had no `summary()` of its own and printed the
default's shape; the exam printed its capitals. `isLong` was never declared in either struct, and
both answer it.

## What a default may use

A default is written once for types it has never seen, so **it can use only what the protocol
guarantees**: here, `title` and `minutes`. Asking for `self.lessons` inside the extension would not
compile, because nothing promises every `Timed` type has lessons. That restriction is what makes a
good default small: a sentence built from the requirements, a check on them, a calculation over
them.

## Defaults with a condition

An extension can be limited to some of the conforming types with a `where` clause, such as
`extension Timed where Self: Equatable`, and its members then exist only on types that meet both.
The standard library uses this everywhere: `contains(_:)` exists on an array only when its elements
are `Equatable`, because comparing needs `==`. Lesson 9 writes constraints of that kind for
generics.

## Requirement or not

`summary()` is listed in the protocol and `isLong` is not. That difference looks like bookkeeping,
and it decides which body runs when a type writes its own version, which is the surprise section 07
takes apart. **The rule to take away now: if a conforming type is allowed to replace a member, list
the member in the protocol.**
