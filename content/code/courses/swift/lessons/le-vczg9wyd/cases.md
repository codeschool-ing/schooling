---
title: A type with a fixed list of values
version: 1
---

A day of the week is one of seven things, never an eighth. Writing it as a `String` lets a typo
through, `"Firday"`, and writing it as an `Int` leaves every reader to remember that 5 means Friday.
**An enumeration, `enum`, is a type whose values are a list you write out**, and nothing outside the
list can be a value of it:

```swift
// Cases.swift
enum Weekday: String, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}
enum Level: Int {
    case easy = 1, medium, hard
}
let today = Weekday.friday
print(today, today.rawValue)
print(Weekday(rawValue: "friday") as Any, Weekday(rawValue: "Friday") as Any)
print(Weekday.allCases.count, Weekday.allCases.first!)
print(Level.medium.rawValue, Level(rawValue: 3) as Any)
var day: Weekday = .monday
day = .sunday
print(day)
```

```
ana@vm:~/sw/l07$ swiftc Cases.swift -o cases && ./cases
friday friday
Optional(cases.Weekday.friday) nil
7 monday
2 Optional(cases.Level.hard)
sunday
```

Each `case` is one value. Where the type is already known, as in `day = .sunday`, the type's name can
be left out and only the dot written, which is why Swift code is full of short forms such as
`.monday`.

**A raw value is a second identity for each case, of a type you choose.** `: String` after the
enum's name gives every case a string, and with nothing written the string is the case's own name.
`: Int` gives numbers, and after `easy = 1` each following case takes the next one. The raw value
is what you write to a file or send over a network, and lesson 13 does exactly that.

**Going back from a raw value can fail**, so `Weekday(rawValue:)` returns an optional: `"friday"`
found its case, and `"Friday"`, with a capital, found none and gave `nil`. That is the same
failable initialiser lesson 6 wrote by hand, and the compiler writes this one. `as Any` silences the
warning lesson 1 met when printing an optional; the output still shows the `Optional(…)` wrapper,
with the type's full name inside, `cases.Weekday`, prefixed by the module as lesson 5 found for
classes.

`CaseIterable` asks the compiler for `allCases`, an array of every case in the order written. It is
how a screen lists the seven days without anybody typing them twice.

## An enum is a value type

An enum is copied like a struct, can have methods and computed properties like a struct, and has no
stored properties of its own: a case is the whole of the value. What it can have instead is the
subject of the next section.
