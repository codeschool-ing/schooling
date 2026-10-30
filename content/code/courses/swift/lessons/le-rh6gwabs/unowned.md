---
title: unowned, and the crash when it is wrong
version: 1
---

`weak` costs an optional on every read. When one object can never outlive another, Swift offers a
reference that also does not count and is not optional: **`unowned`**. It is a promise that the
object will still be there whenever this reference is used. If the promise is broken, the program
does not read freed memory quietly. It stops.

```swift
// Unowned.swift
final class Course {
    let name: String
    init(name: String) { self.name = name }
    deinit { print("\(name): course freed") }
}

final class StudySession {
    let minutes: Int
    unowned let course: Course
    init(minutes: Int, course: Course) {
        self.minutes = minutes
        self.course = course
    }
}

var swift: Course? = Course(name: "Swift")
let session = StudySession(minutes: 45, course: swift!)
print("\(session.minutes) minutes of \(session.course.name)")
swift = nil
print("\(session.minutes) minutes of \(session.course.name)")
```

```
ana@vm:~/sw/l11$ swiftc Unowned.swift -o unowned
ana@vm:~/sw/l11$ SWIFT_BACKTRACE=enable=no ./unowned
45 minutes of Swift
Swift: course freed
Fatal error: Attempted to read an unowned reference but object 0x55cc4b7b6e30 was already destroyed
Current stack trace:
0    libswiftCore.so                    0x00007f3b6f962cd0 swift_reportError + 33
1    libswiftCore.so                    0x00007f3b6fc77e17 <unavailable> + 4685335
2    libswiftCore.so                    0x00007f3b6fc77e9b <unavailable> + 4685467
3    libswiftCore.so                    0x00007f3b6fc77f82 <unavailable> + 4685698
4    libswiftCore.so                    0x00007f3b6fc76104 <unavailable> + 4677892
5    unowned                            0x000055cc18385d09 <unavailable> + 7433
6    libc.so.6                          0x00007f3b6f42a1ca <unavailable> + 172490
7    libc.so.6                          0x00007f3b6f42a200 __libc_start_main + 139
8    unowned                            0x000055cc183852f5 <unavailable> + 4853
```

The first `print` works: the course exists, and `session.course.name` reads it with no `?`. Then
`swift = nil` drops the only strong reference, and the course is freed, as its `deinit` says. **The
second `print` reads an unowned reference to an object that is gone, and the runtime ends the
program** with a message that says exactly that, `Attempted to read an unowned reference but object
… was already destroyed`. A stack trace of where it happened follows: frames in the Swift runtime
first, then `unowned` itself, the program that read the reference.

`SWIFT_BACKTRACE=enable=no` before the command turns off Swift's full crash report, which on Linux runs
to some fifty lines of registers and memory, and keeps the short stack trace you see. It changes the
report and nothing else; without it the program crashes on the same line.

## Choosing between them

| | `weak` | `unowned` |
|---|---|---|
| adds to the count | no | no |
| type | always an optional `var` | not optional, `let` or `var` |
| when the object is gone | reads `nil` | stops the program |
| use it when | the other object can go first | the other object never goes first |

**When in doubt, use `weak`.** An unowned reference that was right when it was written becomes a crash
the day somebody changes who holds what, and the crash happens far from the change. The classic
honest case is an object created by its owner and never handed elsewhere: a session created inside a
course's own method, for instance, whose course by construction outlives it. Even there, `weak` costs
one `?`, and that `?` is cheaper than a crash nobody can reproduce.
