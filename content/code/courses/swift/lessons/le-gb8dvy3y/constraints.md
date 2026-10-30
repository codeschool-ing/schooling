---
title: Constraints say what the type must be able to do
version: 1
---

A **constraint** narrows a type parameter to the types that conform to a protocol, and in exchange
the body may use everything that protocol requires. `largest` needs `>`, which is what `Comparable`
provides, so it says so:

```swift
// Constrained.swift
func largest<T: Comparable>(_ items: [T]) -> T? {
    var best = items.first
    for item in items where item > best! {
        best = item
    }
    return best
}

print(largest([45, 30, 60, 90]) ?? 0)
print(largest(["Swift", "Kotlin", "SQL"]) ?? "")
print(largest([2.5, 0.75]) ?? 0)
```

```
ana@vm:~/sw/l09$ swift Constrained.swift
90
Swift
2.5
```

`<T: Comparable>` reads "any `T` that is `Comparable`". The body compiles now, because every type
allowed in has a `>`. `Int`, `String` and `Double` all conform, and `"Swift"` is the largest string
because strings compare letter by letter and `W` comes after `Q`.

## The refusal moves to the call

The constraint did not make the check go away. It moved it from the body to every call, where the
type is known:

```swift
// NotComparable.swift
final class Note {
    var text = ""
}

func largest<T: Comparable>(_ items: [T]) -> T? { items.max() }

print(largest([Note(), Note()]) as Any)
```

```
ana@vm:~/sw/l09$ swiftc NotComparable.swift -o notcomparable
NotComparable.swift:8:7: error: global function 'largest' requires that 'Note' conform to 'Comparable'
4 | }
5 | 
6 | func largest<T: Comparable>(_ items: [T]) -> T? { items.max() }
  |      `- note: where 'T' = 'Note'
7 | 
8 | print(largest([Note(), Note()]) as Any)
  |       `- error: global function 'largest' requires that 'Note' conform to 'Comparable'
9 | 
```

**The error names the requirement and the type that misses it**, and the note shows what `T` was
inferred to be. A constraint is a contract with two sides: the function may use `>`, and the caller
must bring a type that has it. Lesson 8's `Comparable` conformance is how a planner type gets in.

## where, for longer contracts

Some conditions are about types connected to the parameter rather than the parameter itself. A
week total should accept any collection of integers, an array, a set or a range, and nothing else:

```swift
// WeekTotal.swift
func weekTotal<C: Collection>(_ sessions: C) -> Int where C.Element == Int {
    sessions.reduce(0, +)
}

print(weekTotal([45, 30, 60, 90]))
print(weekTotal(Set([45, 30])))
print(weekTotal(1...4))
```

```
ana@vm:~/sw/l09$ swift WeekTotal.swift
225
75
10
```

`C: Collection` lets the function loop over the argument; the `where` clause adds that the
collection's `Element` must be `Int`. `Element` is an **associated type** of `Collection`, a type
each collection decides for itself, and section 05 writes a protocol with one. A `where` clause can
hold several conditions separated by commas, and it is also how lesson 8's conditional extensions
were written.
