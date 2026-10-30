---
title: weak, the reference that does not count
version: 1
---

The fix for section 03 is to decide which of the two references **owns** and which only **points**.
A course owns its sessions: when the course goes, its sessions go with it. A session only needs to
find its course while the course exists. **`weak` marks a reference that does not add to the count**,
and Swift sets it to `nil` when the object it pointed to is freed.

```swift
// Weak.swift
final class Course {
    let name: String
    var sessions: [StudySession] = []
    init(name: String) { self.name = name }
    deinit { print("\(name): course freed") }
}

final class StudySession {
    let minutes: Int
    weak var course: Course?
    init(minutes: Int) { self.minutes = minutes }
    deinit { print("\(minutes)-minute session freed") }
}

var kept: StudySession?

func plan() {
    let swift = Course(name: "Swift")
    let session = StudySession(minutes: 45)
    swift.sessions.append(session)
    session.course = swift
    kept = session
    print("inside plan(): course is \(session.course?.name ?? "gone")")
}

plan()
print("after plan(): course is \(kept?.course?.name ?? "gone")")
kept = nil
print("the program goes on")
```

```
ana@vm:~/sw/l11$ swift Weak.swift
inside plan(): course is Swift
Swift: course freed
after plan(): course is gone
45-minute session freed
the program goes on
```

One word changed in the class, `weak` before `var course`. To show what `weak` does when its object
leaves, the program keeps the session alive after `plan()` in a global, `kept`, which the cycle
program did not have.

Read the output in order. Inside `plan()` the session reaches its course. When `plan()` returns, the
local `swift` was the only strong reference to the course, because the session's reference does not
count, so **the course is freed at once**, and with it the array that held the session. The session
survives, held by `kept`, and its `course` is now `nil`: `?? "gone"` printed `gone`. Then `kept = nil`
frees the session too.

## Why weak is always an optional var

A weak reference has to be able to become `nil` on its own, at a moment no line of your code chose.
So it must be an optional, and it must be a `var`: `weak let course: Course` does not compile. Every
use then goes through the optional tools of lesson 2, `?.`, `if let`, `guard let`, which is the
point. **Code that follows a weak reference has to say what happens when the other object is gone.**

## Which side gets the weak

The rule of thumb is the ownership one: **the parent holds the child strongly and the child holds the
parent weakly.** A course holds sessions; a session points back weakly. A screen holds the parts it
draws; a part that tells the screen about a tap points back weakly. In Apple's frameworks that second
shape has a name, the delegate, and a delegate property is declared `weak` for exactly this reason.
