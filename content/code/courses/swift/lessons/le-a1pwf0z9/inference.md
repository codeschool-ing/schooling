---
title: Types you did not write
version: 1
---

None of the programs so far has written a type, and every name in them has one. **Swift infers the
type from the value**, at compile time, and from then on the name has that type for good. Nothing
is decided while the program runs. `type(of:)` asks for the type of a value, which makes the
inference visible:

```swift
// Inference.swift
let course = "Swift"
let minutes = 45
let hours = 1.5
let done = false
let pace: Double = 45
print(type(of: course), type(of: minutes), type(of: hours), type(of: done), type(of: pace))
print(minutes / 60, Double(minutes) / 60, Int(hours))
print(Int.max, Int8.max, Int8.min)
```

```
ana@vm:~/sw/l01$ swift Inference.swift
String Int Double Bool Double
0 0.75 1
9223372036854775807 127 -128
```

Four rules produced the first line:

| a literal like | is inferred as |
|---|---|
| `"Swift"` | `String` |
| `45` | `Int` |
| `1.5` | `Double` |
| `false` | `Bool` |

The fifth name, `pace`, has an **annotation**: `: Double` after the name says which type you want.
The literal `45` would have been an `Int` on its own, and the annotation turned it into a `Double`.
That works because a literal has no type until it is used; an integer literal can become any number
type the context asks for. Section 07 shows that a value which already has a type gets no such
favour.

## Integers divide as integers

`minutes / 60` printed `0`. Both sides are `Int`, so the division is an integer division: 45 divided
by 60 is 0, with 45 left over, and the remainder is dropped. `Double(minutes) / 60` converts first,
and gives `0.75`. **The type of the operands decides the arithmetic**, and nothing warns you. When a
result is smaller than you expected, look at the types before the numbers. `Int(hours)` goes the
other way and cuts `1.5` down to `1`, towards zero.

## Integers have sizes

`Int` is 64 bits on every computer and phone Swift ships for today, and the third line prints its
largest value. `Int8`, `Int16`, `Int32` and `Int64` exist, with unsigned versions such as `UInt8`,
for file formats and network protocols where the size is part of the contract. **Use `Int` unless a
format tells you otherwise**; mixing sizes costs conversions everywhere, for the reason section 07
shows. `Double` is the floating-point type to reach for, and `Float` is half its size.

## When to write the type anyway

An annotation that only repeats what the literal says, `let minutes: Int = 45`, adds nothing. Write
one when the literal would infer the wrong type, as with `pace`, or when there is no literal at all
and the reader would have to look elsewhere to know. An annotation is also checked. It is never a
conversion:

```swift
// Annotated.swift
let minutes: Int = 1.5
print(minutes)
```

```
ana@vm:~/sw/l01$ swiftc Annotated.swift -o annotated
Annotated.swift:2:20: error: cannot convert value of type 'Double' to specified type 'Int'
1 | // Annotated.swift
2 | let minutes: Int = 1.5
  |                    `- error: cannot convert value of type 'Double' to specified type 'Int'
3 | print(minutes)
4 | 
```

A `Double` literal cannot become an `Int` without losing the `.5`, and the compiler will not do
that quietly.
