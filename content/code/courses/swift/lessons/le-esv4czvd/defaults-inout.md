---
title: Default values, variadic parameters and inout
version: 1
---

Three more things a parameter can be, each solving one problem.

## A default for the usual case

Most sessions in the planner are 30 minutes and are planned for Monday. A **default value** lets the
call leave out what is usual:

```swift
// Defaults.swift
func plan(_ course: String, minutes: Int = 30, on day: String = "Monday") {
    print("\(day): \(course) for \(minutes) min")
}
plan("Swift")
plan("Swift", minutes: 45)
plan("Swift", on: "Friday")
plan("Swift", minutes: 60, on: "Sunday")
```

```
ana@vm:~/sw/l03$ swift Defaults.swift
Monday: Swift for 30 min
Monday: Swift for 45 min
Friday: Swift for 30 min
Sunday: Swift for 60 min
```

Four calls, one function. Because each argument has a label, the call can skip `minutes:` and still give
`on:` without anybody being confused about which number went where. **Put parameters with defaults
after the ones without**, so the required arguments always come first at the call.

## Any number of arguments

A **variadic** parameter, written with `...` after its type, accepts zero or more values and sees them as
an array:

```swift
// Variadic.swift
func total(_ sessions: Int...) -> Int {
    var sum = 0
    for minutes in sessions {
        sum += minutes
    }
    return sum
}
print(total())
print(total(45))
print(total(45, 30, 60))
```

```
ana@vm:~/sw/l03$ swift Variadic.swift
0
45
135
```

`print` itself is variadic, which is why `print(total, hours(total))` in section 02 printed two values
with a space between them.

## Parameters are constants

Inside the function, every parameter is a `let`. Trying to change one is an error:

```swift
// ParamLet.swift
func extend(_ minutes: Int) -> Int {
    minutes += 5
    return minutes
}
print(extend(45))
```

```
ana@vm:~/sw/l03$ swiftc ParamLet.swift -o paramlet
ParamLet.swift:3:13: error: left side of mutating operator isn't mutable: 'minutes' is a 'let' constant
1 | // ParamLet.swift
2 | func extend(_ minutes: Int) -> Int {
3 |     minutes += 5
  |             `- error: left side of mutating operator isn't mutable: 'minutes' is a 'let' constant
4 |     return minutes
5 | }
```

**The compiler is protecting the caller.** The caller passed a value, and nothing the function does
reaches back to change the caller's copy of it. When a function needs a working copy, it writes `var
longer = minutes` and changes that.

## inout, when changing the caller's variable is the point

Sometimes the caller wants its variable changed. `inout` marks such a parameter, and **the call has to
write `&`**, so that reading the call alone tells you the variable may come back different:

```swift
// Inout.swift
func addSession(_ minutes: Int, to total: inout Int) {
    total += minutes
}
var week = 0
addSession(45, to: &week)
addSession(30, to: &week)
print(week)
```

```
ana@vm:~/sw/l03$ swift Inout.swift
75
```

`week` went in as 0 and came back as 75. Under the hood the value is copied in, changed, and copied back
out when the function ends. `inout` is useful and rare: a function that returns a new value, `week =
week + 45`, is easier to follow, and most Swift code does that instead.
