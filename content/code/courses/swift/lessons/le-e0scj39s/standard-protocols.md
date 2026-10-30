---
title: Protocols the standard library already has
version: 1
---

Most protocols a Swift program conforms to were written by somebody else. Four of them turn up in
nearly every type of the planner, and the compiler writes the code for three of them unless you
ask otherwise:

| protocol | what it gives | written by |
|---|---|---|
| `Equatable` | `==` and `!=` | the compiler, comparing every stored property |
| `Hashable` | a hash, so the value can be a `Set` element or a dictionary key | the compiler, from every stored property |
| `Comparable` | `<`, and with it `sorted()`, `min()`, `max()` | you: only you know what "less" means |
| `CustomStringConvertible` | what `print` shows | you, through `description` |

```swift
// Session.swift
struct StudySession: Hashable, Comparable, CustomStringConvertible {
    var course: String
    var minutes: Int

    static func < (a: StudySession, b: StudySession) -> Bool { a.minutes < b.minutes }
    var description: String { "\(course) \(minutes) min" }
}

let a = StudySession(course: "Swift", minutes: 45)
let b = StudySession(course: "Swift", minutes: 45)
let c = StudySession(course: "Kotlin", minutes: 30)
print(a == b, a == c, a < c)
print(Set([a, b, c]).count)
print([a, c].sorted())
print(a)
```

```
ana@vm:~/sw/l08$ swift Session.swift
true false false
2
[Kotlin 30 min, Swift 45 min]
Swift 45 min
```

`a == b` is `true` though nobody wrote `==`: **the synthesised `Equatable` compares every stored
property**, and both of them match. `Hashable` was synthesised the same way, so the set of three
sessions holds two, `a` and `b` being equal. `Comparable` needed one function, `<`, written as a
`static func` because an operator belongs to the type rather than to one value; `sorted()` then
works with no argument. `description` decided what `print` showed, for the single session and for
each element of the array.

## When the compiler will not write it

Synthesis needs every stored property to conform already. A property whose type cannot be compared
leaves `==` impossible to write automatically, and the compiler says which property is to blame:

```swift
// NoteRef.swift
final class Note {
    var text = ""
}

struct StudySession: Equatable {
    var minutes: Int
    var note: Note
}
```

```
ana@vm:~/sw/l08$ swiftc NoteRef.swift -o noteref 2>&1 | head -13
NoteRef.swift:6:8: error: type 'StudySession' does not conform to protocol 'Equatable'
 4 | }
 5 | 
 6 | struct StudySession: Equatable {
   |        |- error: type 'StudySession' does not conform to protocol 'Equatable'
   |        `- note: add stubs for conformance
 7 |     var minutes: Int
 8 |     var note: Note
   |         `- note: stored property type 'Note' does not conform to protocol 'Equatable', preventing synthesized conformance of 'StudySession' to 'Equatable'
 9 | }
10 | 

Swift.==:1:24: note: candidate would match if 'StudySession' conformed to 'RawRepresentable'
ana@vm:~/sw/l08$ swiftc NoteRef.swift -o noteref 2>&1 | wc -l
63
```

The compiler prints much more than this, and `head -13` keeps the part worth reading; `wc -l`
counts the whole message. After the lines shown come notes about every other `==` in the standard
library that might have matched, one per protocol, and the last of them names the requirement
itself. The note to read is the one pointing at line 8: **the stored property `note` is what
prevents the synthesis.**

`Note` is a class with no `==`, and lesson 5 explains why two class instances have no obvious
meaning for "equal". The fix is either to make `Note` conform, or to write `==` for the session
yourself and say what equality means for it, for example the same minutes and the same text.

## Equal is your decision

The synthesised `==` is a good default and not always the right answer. Two sessions with the same
course and the same minutes, on different days, are equal to it. **If a type has an identity, such
as an `id`, equality may be about that and nothing else**, and then you write `==` and `hash(into:)`
yourself, using the same properties in both. Values that are equal must hash the same, or a `Set`
loses track of them.
