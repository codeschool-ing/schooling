---
title: any, and what the box costs
version: 1
---

Lesson 8 put courses and sessions in one array as `[any Describable]`, and section 06 sent the
mixed case here. **`any Protocol` is an existential: a value whose concrete type is decided while the
program runs, kept in a box that also remembers what that type is.** `some` is one type the caller
does not know; `any` is a box that can hold a different type each time.

## The box has a size

The box is real, and `MemoryLayout` measures it:

```swift
// Box.swift
protocol Describable { var title: String { get } }
struct Course: Describable { var title: String; var lessons: Int }
struct StudySession: Describable { var title: String; var minutes: Int }

print(MemoryLayout<Int>.size, MemoryLayout<String>.size)
print(MemoryLayout<Course>.size, MemoryLayout<StudySession>.size)
print(MemoryLayout<any Describable>.size)

let mixed: [any Describable] = [Course(title: "Swift", lessons: 20),
                                StudySession(title: "Optionals", minutes: 45)]
for item in mixed { print(item.title) }
```

```
ana@vm:~/sw/l09$ swift Box.swift
8 16
24 24
40
Swift
Optionals
```

An `Int` is 8 bytes and a `String` 16, so each struct is 24. An `any Describable` is **40 bytes**
whatever it holds: a buffer of three words for the value, one word saying which type is inside, and
one pointing at that type's conformance table from lesson 8, which is how `item.title` finds the
right property. A value too big for the buffer is stored elsewhere and the buffer holds a pointer to
it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l09-box\" aria-label=\"Two arrays side by side. On the left, [Course]: three cells of 24 bytes each, every one a Course, packed one after the other. On the right, [any Describable]: two cells of 40 bytes each. Each cell is split into a 24-byte value buffer, one word saying which type is inside, and one word pointing at that type's conformance table. The first box holds a Course, the second a StudySession.\"><text x=\"130\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">[Course]</text><text x=\"130\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one type, known when it compiles</text><rect x=\"40\" y=\"70\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Course</text><text x=\"130\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24 B</text><rect x=\"40\" y=\"132\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Course</text><text x=\"130\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24 B</text><rect x=\"40\" y=\"194\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Course</text><text x=\"130\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24 B</text><text x=\"500\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">[any Describable]</text><text x=\"500\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a box per element, the type read while it runs</text><rect x=\"300\" y=\"70\" width=\"400\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"310\" y=\"80\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Course</text><text x=\"405\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">value, 24 bytes</text><rect x=\"510\" y=\"80\" width=\"80\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which type</text><rect x=\"600\" y=\"80\" width=\"90\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"645\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conformance</text><text x=\"645\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">table</text><rect x=\"300\" y=\"160\" width=\"400\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"310\" y=\"170\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">StudySession</text><text x=\"405\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">value, 24 bytes</text><rect x=\"510\" y=\"170\" width=\"80\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which type</text><rect x=\"600\" y=\"170\" width=\"90\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"645\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conformance</text><text x=\"645\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">table</text><text x=\"500\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">40 B × 2</text></svg>", "caption": "An array of one struct holds the structs themselves. An array of any holds a 40-byte box per element: room for the value, and two words that say what it is and where its methods are."}
```

## What an any cannot do

The box hides the type, and with it anything that depends on the type. Lesson 8's `Describable` has
no associated type, so nothing was lost. Section 05's `Store` has one, and a store in a box no longer
knows what it accepts:

```swift
// AnyStore.swift
protocol Store {
    associatedtype Item
    var all: [Item] { get }
    mutating func add(_ item: Item)
}

struct Minutes: Store {
    var all: [Int] = []
    mutating func add(_ item: Int) { all.append(item) }
}

var store: any Store = Minutes()
print(store.all)
store.add(30)
```

```
ana@vm:~/sw/l09$ swiftc AnyStore.swift -o anystore
AnyStore.swift:15:1: error: member 'add' cannot be used on value of type 'any Store'; consider using a generic constraint instead [#ExistentialMemberAccess]
13 | var store: any Store = Minutes()
14 | print(store.all)
15 | store.add(30)
   | `- error: member 'add' cannot be used on value of type 'any Store'; consider using a generic constraint instead [#ExistentialMemberAccess]
16 | 

[#ExistentialMemberAccess]: <https://docs.swift.org/compiler/documentation/diagnostics/existential-member-access-limitations>
```

Line 14, reading `all`, was accepted: only line 15 has an error. Adding is refused,
because nothing stops `store` from holding a store of strings at that moment, and the message
suggests what to do instead: **a generic constraint**, like section 05's `fill<S: Store>`, which
keeps the type known.

## Choosing between them

| you have | write |
|---|---|
| one type the caller should not need to name | `some Protocol` |
| a parameter that accepts any conforming type | `some Protocol`, or a constraint `<T: Protocol>` |
| values of different types in one collection, or a stored property whose type changes | `any Protocol` |

**Start with `some`, and write `any` when the values really are mixed.** `any` is not wrong, and the
planner's mixed list is exactly what it is for; it is a box with a lookup on every call, and a
generic that knows its type has neither. Swift 6 asks you to write the word `any` for that reason,
so the cost is visible where it is paid. Code from before that rule wrote `[Describable]`, which
still compiles today, and lesson 15 is where the language modes that tighten rules like this one
are explained.
