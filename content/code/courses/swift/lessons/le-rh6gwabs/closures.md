---
title: Closures that hold on to self
version: 1
---

A closure that uses a name from around it **captures** it: it keeps the value, or the reference,
alive for as long as the closure itself is alive (lesson 3). When the closure is stored in a property
of a class and uses `self`, that is a loop of two: the object holds the closure, and the closure holds
the object. **It is the commonest retain cycle in Swift code, because nothing in the line that makes
it looks like a reference.**

The planner's countdown runs a closure when a study block ends. Two versions of the same class, one
capturing `self` strongly and one weakly:

```swift
// Closures.swift
final class Countdown {
    let course: String
    var onFinish: (() -> Void)?
    init(course: String) { self.course = course }
    deinit { print("\(course) countdown freed") }

    func strongReport() {
        onFinish = { print("finished \(self.course)") }
    }

    func weakReport() {
        onFinish = { [weak self] in
            guard let self else { return }
            print("finished \(self.course)")
        }
    }
}

func run(_ name: String, weakly: Bool) {
    let countdown = Countdown(course: name)
    if weakly { countdown.weakReport() } else { countdown.strongReport() }
    countdown.onFinish?()
}

run("Swift", weakly: false)
run("Kotlin", weakly: true)
print("both functions returned")
```

```
ana@vm:~/sw/l11$ swift Closures.swift
finished Swift
finished Kotlin
Kotlin countdown freed
both functions returned
```

Both closures ran and printed. Only one countdown was freed: **the Swift countdown, whose closure
captured `self` strongly, is still in memory** after `run` returned, held by its own closure, which it
holds. The Kotlin countdown's closure captured `self` weakly, so when `run` returned nothing held the
object and it went.

## The capture list

`[weak self] in` is a **capture list**: square brackets before `in`, saying how each name is captured.
Without it, `self` is captured strongly. With `weak`, the closure holds a weak reference, `self`
inside it is an optional, and `guard let self else { return }` turns it back into a strong reference
for the rest of the closure, or leaves quietly if the object is already gone. `[unowned self]` exists
too, with section 05's promise and section 05's crash.

The compiler helps with one half of this. Inside a closure stored for later, an **escaping** closure,
Swift makes you write `self.course` rather than `course`, so that every use of `self` is visible on
the page. That `self.` is the place to stop and ask who holds whom.

## Closures that cannot leak

A closure passed to `map`, `filter` or `sorted` runs during the call and is gone when the call
returns; it is **non-escaping**, and it can use `self` freely, without `self.`, because it cannot
outlive the line. Only a closure that is stored, in a property, an array, a timer or a task, can
take part in a cycle. Lesson 14's `Task { }` is one of those, and the same capture list works there.
