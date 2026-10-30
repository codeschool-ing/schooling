---
title: Two ways to define a type
version: 1
---

Every program so far has used types somebody else wrote: `Int`, `String`, `Double`. Swift gives you
two keywords for writing your own type with stored fields, `struct` and `class`, and **they look
almost identical on the page**. The difference is what happens when a value is assigned, passed or
stored, and the rest of this lesson is that difference. This section shows what each one asks of you
before you can make one.

A study session has a course and a number of minutes. Here it is written both ways, side by side:

```swift
// Kinds.swift
struct SessionValue {
    var course: String
    var minutes: Int
}
class SessionRef {
    var course: String
    var minutes: Int
}
let first = SessionValue(course: "Swift", minutes: 45)
print(first)
```

```
ana@vm:~/sw/l05$ swiftc Kinds.swift -o kinds
Kinds.swift:6:7: error: class 'SessionRef' has no initializers
 4 |     var minutes: Int
 5 | }
 6 | class SessionRef {
   |       `- error: class 'SessionRef' has no initializers
 7 |     var course: String
   |         `- note: stored property 'course' without initial value prevents synthesized initializers
 8 |     var minutes: Int
   |         `- note: stored property 'minutes' without initial value prevents synthesized initializers
 9 | }
10 | let first = SessionValue(course: "Swift", minutes: 45)
```

**The struct compiled and the class did not.** The compiler names the class, says it has no
initialiser, and adds a note under each stored property: a property without an initial value
prevents the compiler from writing one. A struct in the same situation gets a **memberwise
initialiser** for free, `SessionValue(course:minutes:)`, which is why line 10 was not an error. A
class gets no such gift and you write `init` yourself:

```swift
// KindsFixed.swift
struct SessionValue {
    var course: String
    var minutes: Int
}
final class SessionRef {
    var course: String
    var minutes: Int
    init(course: String, minutes: Int) {
        self.course = course
        self.minutes = minutes
    }
}
let first = SessionValue(course: "Swift", minutes: 45)
let second = SessionRef(course: "Swift", minutes: 45)
print(first)
print(second)
```

```
ana@vm:~/sw/l05$ swiftc KindsFixed.swift -o kindsfixed && ./kindsfixed
SessionValue(course: "Swift", minutes: 45)
kindsfixed.SessionRef
```

`self.course = course` assigns the parameter `course` to the property of the same name; `self` is
the instance being built, and lesson 6 has more to say about initialisers. `final` says no other
class may inherit from this one, which is the right default for a class nobody designed to be
extended; lesson 10 is about inheritance and when it earns its place.

The two `print` lines differ too. **A struct prints its contents**, field by field, because Swift
can describe a value by what is in it. A class prints only its name, prefixed with the module the
program was compiled into, `kindsfixed`, which `swiftc` named after the output file, because what identifies an instance is not its contents but
which instance it is. Section 06 makes that distinction exact.

## What else differs

| | `struct` | `class` |
|---|---|---|
| assigning it, or passing it to a function | copies the value | copies a reference to the same instance |
| an initialiser | written for you, one argument per property | you write `init` |
| changing a property from a method | the method must be `mutating` | always allowed |
| inheritance | none | one superclass, unless `final` |
| `===`, "is it the same instance?" | not available | available |
| `deinit`, code that runs when it goes away | none | yes, lesson 11 |

Most of the standard library is on the left. `Int`, `String`, `Array`, `Dictionary` and `Optional`
are all structs or enums, and so are most of the types you will write in an iPhone app's model
layer. That is a decision Swift's designers made on purpose, and section 08 gives their reasons.
