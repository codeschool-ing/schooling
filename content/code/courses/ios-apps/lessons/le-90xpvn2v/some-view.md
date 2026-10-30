---
title: some View: one type, which only the compiler has to know
version: 1
---

**`some View` means "exactly one concrete type that conforms to `View`", chosen by the body and
hidden from whoever reads it.** The compiler knows the type and checks it; you do not have to write
it, which matters because a real body's type is long. The belief to replace is that `some View` means
"any view at all", so that a body could return one kind of view on one call and another on the next.
It cannot, and plain Swift shows why without SwiftUI.

Here is the same rule on a protocol of our own. `Card` stands for `View`, and two types conform to
it. Save this as `opaque.swift` in a directory for this lesson, `~/l03`:

```swift
// opaque.swift
protocol Card {
    func render() -> String
}
struct Title: Card {
    let text: String
    func render() -> String { "# \(text)" }
}
struct Minutes: Card {
    let value: Int
    func render() -> String { "\(value) min" }
}

func header(short: Bool) -> some Card {
    if short { return Minutes(value: 50) }
    return Title(text: "SQL Databases")
}
print(header(short: false).render())
```

`swift opaque.swift` compiles a single file and runs it, as lesson 1 section 08 did for
`check.swift`:

```
ana@vm:~/l03$ swift opaque.swift; echo $?
opaque.swift:14:6: error: function declares an opaque return type 'some Card', but the return statements in its body do not have matching underlying types [#OpaqueTypeInference]
12 | }
13 | 
14 | func header(short: Bool) -> some Card {
   |      `- error: function declares an opaque return type 'some Card', but the return statements in its body do not have matching underlying types [#OpaqueTypeInference]
15 |     if short { return Minutes(value: 50) }
   |                       `- note: return statement has underlying type 'Minutes'
16 |     return Title(text: "SQL Databases")
   |            `- note: return statement has underlying type 'Title'
17 | }
18 | print(header(short: false).render())

[#OpaqueTypeInference]: <https://docs.swift.org/compiler/documentation/diagnostics/opaque-type-inference>
1
```

**The compiler refuses, and its note names both types.** `some Card` promised one underlying type,
and the two `return` statements give two. Nothing ran: the exit status is 1 and the `print` never
happened. A body is the same kind of function, so a SwiftUI body that returned a `Text` on one branch
and an `Image` on another would be refused with this message.

## Why SwiftUI wants one type

**Because the type is the shape of the screen.** A body's type records which views it contains, in
what order and in which branch, so SwiftUI can compare an old description with a new one by
structure, without guessing. Section 07 shows that shape with a type of our own.

There are two ways to return different views from one body, and SwiftUI uses the first:

- **a result builder**, which turns an `if` and an `else` into one type with a slot for each branch.
  `body` is marked with one, and section 06 builds a small builder of our own;
- **type erasure**, SwiftUI's `AnyView`, which wraps any view and hides its type. It compiles, and it
  hides exactly the structure SwiftUI compares by: Apple's documentation for `AnyView` says that
  whenever the wrapped type changes, the old hierarchy is destroyed and a new one created.
