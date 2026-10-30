---
title: Trailing closures
version: 1
---

When the last argument of a call is a closure, Swift lets you **close the brackets first and write the
closure after them**. It is called a trailing closure, and it is the reason most Swift code that passes
a function looks like a block of code rather than an argument list.

```swift
// Trailing.swift
func repeatTwice(_ action: () -> Void) {
    action()
    action()
}
func applyAll(_ values: [Int], _ f: (Int) -> Int) -> [Int] {
    var out: [Int] = []
    for value in values {
        out.append(f(value))
    }
    return out
}
repeatTwice({ print("review chapter 3") })
repeatTwice {
    print("review chapter 4")
}
let doubled = applyAll([45, 30]) { $0 * 2 }
print(doubled)
```

```
ana@vm:~/sw/l03$ swift Trailing.swift
review chapter 3
review chapter 3
review chapter 4
review chapter 4
[90, 60]
```

`repeatTwice({ … })` and `repeatTwice { … }` are the same call. When the closure is the only argument,
the brackets disappear entirely. `applyAll([45, 30]) { $0 * 2 }` keeps the brackets for the first
argument and writes the closure after them. `() -> Void` is the type of a function that takes nothing and
gives nothing back, which is what an action is.

**Read a trailing closure as the last argument**, not as a block that runs immediately. Whether it runs
now, twice, later or never is up to the function it was given to. `repeatTwice` runs it twice. Lesson 4's
`map`, `filter` and `sorted` take closures written exactly this way, and that lesson is where the shape
pays for itself.

## More than one

A function that takes several closures can have them all trailing. The first is written with no label,
and the rest with theirs:

```swift
// TwoClosures.swift
func load(course: String, onSuccess: (Int) -> Void, onFailure: (String) -> Void) {
    if course == "Swift" {
        onSuccess(135)
    } else {
        onFailure("no sessions for \(course)")
    }
}
load(course: "Swift") { minutes in
    print("loaded \(minutes) minutes")
} onFailure: { message in
    print("failed: \(message)")
}
load(course: "Kotlin") { minutes in
    print("loaded \(minutes) minutes")
} onFailure: { message in
    print("failed: \(message)")
}
```

```
ana@vm:~/sw/l03$ swift TwoClosures.swift
loaded 135 minutes
failed: no sessions for Kotlin
```

The shape, a closure for success and a closure for failure, is the one older networking code used before
`async`/`await` existed, and lesson 14 starts from it. It is also exactly how SwiftUI's buttons and lists
are written in `ios-apps`: `Button("Add") { … }` is a call whose last argument is a trailing closure.
