---
title: One function for every type
version: 1
---

The planner needs the first and the last session of a week, and the first and the last course of a
track. Written plainly, that is two functions with the same body and different types in the
signature, and a third the day somebody needs it for dates. **A generic function is written once
with a placeholder for the type, and the compiler fills the placeholder in at each call.**

```swift
// Generic.swift
func firstAndLast<T>(_ items: [T]) -> (first: T, last: T)? {
    guard let first = items.first, let last = items.last else { return nil }
    return (first, last)
}

let minutes = [45, 30, 60, 90]
let courses = ["Swift", "Kotlin", "SQL"]

if let ends = firstAndLast(minutes) { print(ends.first, ends.last) }
if let ends = firstAndLast(courses) { print(ends.first, ends.last) }
print(firstAndLast([Double]()) as Any)
```

```
ana@vm:~/sw/l09$ swift Generic.swift
45 90
Swift SQL
nil
```

`<T>` after the name declares a **type parameter** called `T`. Inside the function `T` stands for
one type, the same one everywhere it appears, so the array's elements and the two values returned
have the same type. At the first call `T` is `Int`, because `minutes` is an `[Int]`; at the second
it is `String`. Nobody wrote either: **the compiler infers the type parameter from the arguments**,
the way lesson 1 showed it inferring the type of a `let`. The third call passes an empty array of
`Double`, and the function returns `nil`, as the `guard` from lesson 2 says.

`T` is a convention and nothing more. The standard library writes `Element` for what a collection
holds and `Value` for what a dictionary maps to, and a name that says what the type is for reads
better than a letter once there is more than one.

## Generic, and still checked

A placeholder is not "any type, decided at run time". Each call is checked with its real type, so
`let n: Int = firstAndLast(courses)!.first` is refused, since that call's `T` is `String`. **The
safety of lesson 1 survives**: one body, and every use of it typed exactly.

## What a placeholder does not know

Inside the function, `T` could be anything, so the body can do with a `T` only what can be done
with every type: store it, pass it on, return it. Comparing two of them is not on that list:

```swift
// Largest.swift
func largest<T>(_ items: [T]) -> T? {
    var best = items.first
    for item in items where item > best! {
        best = item
    }
    return best
}
```

```
ana@vm:~/sw/l09$ swiftc Largest.swift -o largest
Largest.swift:4:34: error: binary operator '>' cannot be applied to two 'T' operands
2 | func largest<T>(_ items: [T]) -> T? {
3 |     var best = items.first
4 |     for item in items where item > best! {
  |                                  `- error: binary operator '>' cannot be applied to two 'T' operands
5 |         best = item
6 |     }
```

The compiler is not saying `>` is wrong for numbers. It is saying that some types have no `>` at
all, a planner's `Note` class among them, and this function promised to work for every type.
Section 03 adds the promise that makes the comparison legal.
