---
title: When a class is still the right tool
version: 1
---

None of this makes classes wrong. Lesson 5 named what only a class has: **identity**, one object
that several parts of a program share and see change. Section 02's mistake was using inheritance to
describe capabilities, not using a class.

## When to reach for a class

- **Something is shared on purpose.** One planner object that the list, the week view and the sync
  code all read and update, where a change made by one must be seen by the others. Lesson 15 adds
  that a shared mutable object is usually an actor today.
- **Something has a lifetime.** A connection, a file handle, a timer: an object that must be closed
  when the last user lets go of it. Lesson 11's `deinit` exists only on classes.
- **A framework hands you a base class.** UIKit's `UIViewController` is subclassed by every
  UIKit screen ever written, and you do not get to choose otherwise. That is Apple's platform and is
  not run in this course; `ios-apps` uses SwiftUI, which is built from structs and protocols, and
  shows where UIKit still turns up.

## final by default

When a class is right, inheritance usually is not. **Marking a class `final` says nothing may
subclass it**, the compiler holds everyone to that, and it can call the class's methods directly, since
no override can exist:

```swift
// Final.swift
final class Planner {
    var owner: String
    init(owner: String) { self.owner = owner }
}

class SharedPlanner: Planner {}
```

```
ana@vm:~/sw/l10$ swiftc Final.swift -o final
Final.swift:7:7: error: inheritance from a final class 'Planner'
5 | }
6 | 
7 | class SharedPlanner: Planner {}
  |       `- error: inheritance from a final class 'Planner'
8 | 
```

`final` is the cheap default and removing it later is easy, while adding it once other code has
subclassed the class is not. Lesson 8's `Planner` was `final` for that reason.

## A rule of thumb

| you need | reach for |
|---|---|
| a capability several types share | a protocol, with an extension for the behaviour |
| a plain value: a session, a course, a week | a struct |
| one shared thing with identity or a lifetime | a `final class`, or an actor from lesson 15 |
| a subclass | only when a framework asks for one |

Apple's own guidance for Swift says the same in fewer words: **use structures by default, use
protocols to share behaviour, and use a class when you need identity or Objective-C interoperability.**
