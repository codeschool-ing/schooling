---
title: Protocol extensions as mixins
version: 1
---

Section 03 split the planner into capabilities. The other half of the design is where the behaviour
lives. **A protocol extension attaches behaviour to a capability, so every type that has the
capability gets the behaviour**, without a base class and without copying. Such an extension is
often called a **mixin**: a bundle of methods mixed into whichever types conform.

```schooling-example
{"language": "swift", "file": "Mixins.swift", "parts": [{"code": "// Mixins.swift\nprotocol Titled { var title: String { get } }\nprotocol Timed { var minutes: Int { get } }", "note": "Two capabilities, one requirement each. They know nothing about each other."}, {"code": "extension Timed {\n    var asHours: String {\n        minutes % 60 == 0 ? \"\\(minutes / 60)h\" : \"\\(minutes / 60)h\\(minutes % 60)\"\n    }\n    var isLong: Bool { minutes >= 60 }\n}", "note": "Behaviour for everything timed, built from `minutes` alone. These are helpers, not requirements, so no type should write its own (lesson 8, section 07)."}, {"code": "extension Titled where Self: Timed {\n    var label: String { \"\\(title) (\\(asHours))\" }\n}", "note": "A member that exists only on types with both capabilities: it needs a title and the hours from the extension above."}, {"code": "extension Sequence where Element: Timed {\n    var totalMinutes: Int { reduce(0) { $0 + $1.minutes } }\n}", "note": "Any sequence of timed values gets a total: an array, a set, a lazy filter. The constraint is on the element, as in lesson 9."}, {"code": "struct StudySession: Titled, Timed {\n    var title: String\n    var minutes: Int\n}\n\nstruct Break: Timed {\n    var minutes: Int\n}", "note": "The two types write their stored properties and nothing else. A break takes time and has no title, so it has no `label`."}, {"code": "let week = [StudySession(title: \"Optionals\", minutes: 45),\n            StudySession(title: \"Generics\", minutes: 90)]\nfor session in week { print(session.label, session.isLong) }\nprint(week.totalMinutes, week.totalMinutes >= 300 ? \"goal met\" : \"goal not met\")\nprint(Break(minutes: 40).asHours)", "note": "Every member used here came from an extension."}], "output": "Optionals (0h45) false\nGenerics (1h30) true\n135 goal not met\n0h40"}
```

`swift Mixins.swift` runs it. Each session printed its label and whether it is long, the week came
to 135 minutes against a goal of 300, and the break, which has no title, still knew its hours.

## Behaviour follows the capability

The two structs are three stored properties between them. Everything else, four members, arrived
because they conform to small protocols with extensions behind them. Add a third timed type, a
`Lecture`, and it has `asHours`, `isLong` and a place in `totalMinutes` the moment it declares `:
Timed`. **Nothing was inherited and nothing was copied**: the behaviour is written once, next to the
capability it depends on.

## Conditional behaviour

`label` is the interesting one. It lives in `extension Titled where Self: Timed`, so it exists on a
type only when the type has both capabilities. In a class tree this would need a class that is a
child of `Titled` and of `Timed`, which is the double inheritance section 02 could not have. Here it
is one `where` clause. `totalMinutes` is conditional too, on the element of a sequence, and lesson
9's constraints are what make it read like a property of the week.

## The limit

A mixin can only use what its protocol requires, as lesson 8 said of defaults. **If an extension
starts needing a property no requirement promises, the capability is missing a requirement, or the
member belongs to a type rather than to the protocol.** That question, asked each time, is what keeps
the protocols small.
