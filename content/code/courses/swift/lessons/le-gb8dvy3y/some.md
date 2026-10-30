---
title: some, a type the caller does not need to know
version: 1
---

A function that returns a lazy sequence of the week's long sessions has a return type nobody wants
to write: `LazyFilterSequence<LazyMapSequence<Array<StudySession>, Int>>`, and it changes whenever the
body changes. **`some Protocol` as a return type says: one specific type, chosen by this function,
which conforms to the protocol, and which the caller does not need to know.**

```swift
// Some.swift
struct StudySession {
    var course: String
    var minutes: Int
}

let week = [StudySession(course: "Swift", minutes: 45),
            StudySession(course: "SQL", minutes: 90),
            StudySession(course: "Swift", minutes: 60)]

func longMinutes(_ sessions: [StudySession]) -> some Sequence<Int> {
    sessions.lazy.map(\.minutes).filter { $0 >= 60 }
}

let long = longMinutes(week)
print(Array(long))
print(type(of: long))
```

```
ana@vm:~/sw/l09$ swift Some.swift
[90, 60]
LazyFilterSequence<LazyMapSequence<Array<StudySession>, Int>>
```

The caller sees `some Sequence<Int>`: something it can loop over that produces integers. `Array(long)`
works because that is all an array needs. The second line prints the real type, which the function
chose and the signature hid. The `<Int>` after the protocol pins its associated type, `Element`, so
the caller knows what comes out. `\.minutes` is a **key path**, a short way to write `{ $0.minutes }`.

## One type, fixed

**`some` is still exactly one type.** The compiler knows which, checks every use of it, and generates
the same fast code as if the full name had been written. What it refuses is a function that returns
different types on different paths:

```swift
// TwoTypes.swift
protocol Describable { var title: String { get } }
struct Course: Describable { var title: String }
struct StudySession: Describable { var title: String; var minutes: Int }

func pick(_ long: Bool) -> some Describable {
    if long { return Course(title: "Swift") }
    return StudySession(title: "Optionals", minutes: 45)
}
```

```
ana@vm:~/sw/l09$ swiftc TwoTypes.swift -o twotypes
TwoTypes.swift:6:6: error: function declares an opaque return type 'some Describable', but the return statements in its body do not have matching underlying types [#OpaqueTypeInference]
 4 | struct StudySession: Describable { var title: String; var minutes: Int }
 5 | 
 6 | func pick(_ long: Bool) -> some Describable {
   |      `- error: function declares an opaque return type 'some Describable', but the return statements in its body do not have matching underlying types [#OpaqueTypeInference]
 7 |     if long { return Course(title: "Swift") }
   |                      `- note: return statement has underlying type 'Course'
 8 |     return StudySession(title: "Optionals", minutes: 45)
   |            `- note: return statement has underlying type 'StudySession'
 9 | }
10 | 

[#OpaqueTypeInference]: <https://docs.swift.org/compiler/documentation/diagnostics/opaque-type-inference>
```

The two notes name the two types the returns had. A `some` return is a promise of one type the
caller cannot name; two types would break the promise. When different paths really need different
types, the return type is `any Describable`, and section 07 is about what that costs.

## some in a parameter

`some` also works in a parameter, `func show(_ item: some Describable)`, and there it is shorthand for
a generic function: it means exactly `func show<T: Describable>(_ item: T)`, with the type parameter
left unnamed. SwiftUI is built on both uses; every view says its body is `some View`, a type nobody
could write by hand. SwiftUI itself is Apple-only and is not run in this course, but the rule for
`some` is the same one you just watched the compiler enforce.
