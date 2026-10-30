---
title: mutating, and the let that means it
version: 1
---

A struct's methods can read its properties freely. **A method that changes them has to say so,
with `mutating`**, and that one word lets the compiler apply `let` to structs all the way down. A
week's log of minutes, with a method to add a session, written without it:

```swift
// Mutating.swift
struct Week {
    var minutes: [Int] = []
    func add(_ session: Int) {
        minutes.append(session)
    }
}
```

```
ana@vm:~/sw/l05$ swiftc Mutating.swift -o mutating
Mutating.swift:5:17: error: cannot use mutating member on immutable value: 'self' is immutable
2 | struct Week {
3 |     var minutes: [Int] = []
4 |     func add(_ session: Int) {
  |     `- note: mark method 'mutating' to make 'self' mutable
5 |         minutes.append(session)
  |                 `- error: cannot use mutating member on immutable value: 'self' is immutable
6 |     }
7 | }
```

Inside an ordinary method, `self`, the value the method was called on, is a constant, exactly as a
parameter is. `minutes.append` changes `self`, so the compiler refuses, and its note gives the fix.
`= []` after the property is a default value; the memberwise initialiser then lets you leave that
argument out, and `Week()` is a week with no sessions.

With `mutating` in place, the method compiles and works on a `var`:

```swift
// WeekLog.swift
struct Week {
    var minutes: [Int] = []
    mutating func add(_ session: Int) {
        minutes.append(session)
    }
    func total() -> Int {
        minutes.reduce(0, +)
    }
}
var week = Week()
week.add(45)
week.add(30)
print(week.minutes, week.total())
```

```
ana@vm:~/sw/l05$ swiftc WeekLog.swift -o weeklog && ./weeklog
[45, 30] 75
```

Now the same type, held in a `let`:

```swift
// Frozen.swift
struct Week {
    var minutes: [Int] = []
    mutating func add(_ session: Int) {
        minutes.append(session)
    }
    func total() -> Int {
        minutes.reduce(0, +)
    }
}
let frozen = Week(minutes: [45, 30])
print(frozen.total())
frozen.add(60)
```

```
ana@vm:~/sw/l05$ swiftc Frozen.swift -o frozen
Frozen.swift:13:8: error: cannot use mutating member on immutable value: 'frozen' is a 'let' constant
 9 |     }
10 | }
11 | let frozen = Week(minutes: [45, 30])
   | `- note: change 'let' to 'var' to make it mutable
12 | print(frozen.total())
13 | frozen.add(60)
   |        `- error: cannot use mutating member on immutable value: 'frozen' is a 'let' constant
14 | 
```

**This refusal is the useful one.** `frozen` is a `let`, and `add` is `mutating`, so the
compiler will not call it: a `let` struct cannot change at all, through a property or through a
method. That is the guarantee section 05 said a class cannot give, and `mutating` is what makes it
checkable. `total` is not mutating and works on a `let` as on a `var`. `reduce(0, +)` adds the
minutes up, and lesson 4 explained it.

A class has no `mutating`. Its methods may always change its properties, which is why `let` on a
class only fixes the reference. The word is the visible sign of the difference: **reading
`mutating` tells you a struct method changes the value it was called on**, and its absence tells
you it does not.
