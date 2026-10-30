---
title: Equal, or the same one
version: 1
---

"Are these two sessions the same?" has two meanings, and Swift gives each its own operator. **`==`
asks whether two values are equal**: same course, same minutes. **`===` asks whether two references
reach the same instance.** A struct only has the first question, because two struct values are never
"the same one". A class has the second for free and the first only if you write it.

```swift
// Identity.swift
struct SessionValue: Equatable {
    var course: String
    var minutes: Int
}
final class SessionRef {
    var minutes: Int
    init(minutes: Int) { self.minutes = minutes }
}
let a = SessionValue(course: "Swift", minutes: 45)
let b = SessionValue(course: "Swift", minutes: 45)
print(a == b)

let x = SessionRef(minutes: 45)
let y = SessionRef(minutes: 45)
let z = x
print(x === y, x === z)
```

```
ana@vm:~/sw/l05$ swift Identity.swift
true
false true
```

**`: Equatable` after the struct's name is all it took to get `==`.** It declares that the struct
conforms to the standard library's `Equatable` protocol, and when every stored property is itself
equatable, the compiler writes the comparison: equal when every property is equal. Lesson 8 is about
protocols; for now, read `: Equatable` as "values of this type can be compared".

For the class, `x` and `y` hold the same number of minutes and are still two instances, so `===`
answers `false`; `z` was assigned from `x`, so `x === z` is `true`. Asking a class for `==` without
having written it is refused:

```swift
// NoEquals.swift
final class SessionRef {
    var minutes: Int
    init(minutes: Int) { self.minutes = minutes }
}
let x = SessionRef(minutes: 45)
let y = SessionRef(minutes: 45)
print(x == y)
```

```
ana@vm:~/sw/l05$ swiftc NoEquals.swift -o noequals
NoEquals.swift:8:9: error: binary operator '==' cannot be applied to two 'SessionRef' operands
6 | let x = SessionRef(minutes: 45)
7 | let y = SessionRef(minutes: 45)
8 | print(x == y)
  |         `- error: binary operator '==' cannot be applied to two 'SessionRef' operands
9 | 
```

The compiler will not guess what equality means for a class, because for a class the honest answer
is a decision: two accounts with the same name are different people. You can make a class
`Equatable` and write `==` yourself, as lesson 8 shows. **For a struct the guess is right, which is
part of why structs are the default for data.**
