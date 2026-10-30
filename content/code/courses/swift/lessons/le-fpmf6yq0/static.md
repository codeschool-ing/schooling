---
title: Properties of the type itself
version: 1
---

Every property so far belonged to an instance: each session has its own minutes. Some facts belong
to the type instead, one value shared by every instance: the weekly goal of the planner, the number
of sessions created so far. **A `static` property belongs to the type**, is read through the type's
name, and exists once however many instances there are, including none:

```swift
// Static.swift
struct StudySession {
    static let weeklyGoal = 300
    static var created = 0
    var minutes: Int
    init(minutes: Int) {
        self.minutes = minutes
        StudySession.created += 1
    }
    func share() -> Double {
        Double(minutes) / Double(StudySession.weeklyGoal)
    }
}
print(StudySession.weeklyGoal, StudySession.created)
let monday = StudySession(minutes: 45)
let tuesday = StudySession(minutes: 60)
print(StudySession.created, monday.share(), tuesday.share())
```

```
ana@vm:~/sw/l06$ swift Static.swift
300 0
2 0.15 0.2
```

`StudySession.weeklyGoal` was readable before any session existed, and `created` counted two
instances. Writing the initialiser by hand, as here, removes the memberwise one, and section 07 says
how to keep both. Inside the type, `Self.weeklyGoal` works too: `Self` with a capital S names the
type the code is in.

A static property is not reachable through an instance, and the compiler says so:

```swift
// StaticSelf.swift
struct StudySession {
    static let weeklyGoal = 300
    var minutes: Int
    func share() -> Double {
        Double(minutes) / Double(weeklyGoal)
    }
}
```

```
ana@vm:~/sw/l06$ swiftc StaticSelf.swift -o staticself
StaticSelf.swift:6:34: error: static member 'weeklyGoal' cannot be used on instance of type 'StudySession'
4 |     var minutes: Int
5 |     func share() -> Double {
6 |         Double(minutes) / Double(weeklyGoal)
  |                                  `- error: static member 'weeklyGoal' cannot be used on instance of type 'StudySession'
7 |     }
8 | }
```

**Static properties are lazy by nature**: each is initialised the first time anything reads it, and
Swift guarantees that happens once even when two threads read it at once. That makes a `static let`
the natural place for a constant shared by a whole program, and the reason `static var` deserves
care. A `static var` is a global variable with a type's name on it, and lesson 15 shows the Swift 6
compiler refusing exactly that kind of shared, changeable state.
