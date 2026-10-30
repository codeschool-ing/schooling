---
title: Read from anywhere, written from one place
version: 1
---

Section 03 made `minutes` public, and with it came something the planner did not mean to offer:
`plan` appended to the array directly. **Any module can now put any number into the week**, a
negative one included, and nothing in `PlannerCore` gets the chance to say no. The property should
be readable everywhere and changeable only through a method the library controls.

**An access level can be given to a property's setter alone**, by writing it in brackets after the
word `set`. `public private(set) var minutes` reads as: anybody may get it, only this type may set
it:

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public private(set) var minutes: [Int] = []
    public var total: Int { minutes.reduce(0, +) }

    public init() {}

    public mutating func add(_ session: Int) {
        guard session > 0 else { return }
        minutes.append(session)
    }
}
```

The executable is unchanged from section 03:

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
week.minutes.append(45)
print(week.total)
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[3 / 6] PlannerCore
[10 / 10] PlannerCore-product
error: SwiftCompile normal x86_64 /home/ana/sw/l17/planner/Sources/plan/main.swift failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    builtin-SwiftPerFileCompile main.swift
/home/ana/sw/l17/planner/Sources/plan/main.swift:5:14: error: cannot use mutating member on immutable value: 'minutes' setter is inaccessible
3 | 
4 | var week = Week()
5 | week.minutes.append(45)
  |              `- error: cannot use mutating member on immutable value: 'minutes' setter is inaccessible
6 | print(week.total)
7 | 
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:5:14: error: cannot use mutating member on immutable value: 'minutes' setter is inaccessible
3 | 
4 | var week = Week()
5 | week.minutes.append(45)
  |              `- error: cannot use mutating member on immutable value: 'minutes' setter is inaccessible
6 | print(week.total)
7 | 
error: Build failed
```

The same error is printed twice. The build compiles a module's interface and its code in two
separate steps, each step reports what it found, and when both trip on one line you read it twice.
The message is worth reading slowly: `cannot use mutating member on immutable value: 'minutes'
setter is inaccessible`. Appending changes the array, so it needs the setter, and from `plan` the
setter is not there. For this caller, `week.minutes` behaves exactly as if it had been declared with
`let`. **The fix is the method the library offers:**

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
week.add(45)
week.add(-30)
week.add(60)
print(week.minutes, week.total)
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Provisioning 1 / 4]
[3 / 7] plan-product
[8 / 8] plan-product
Build complete! (0.90 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
[45, 60] 105
```

`add(-30)` was turned away by the `guard`, and the array shows only the two sessions that made
sense. The rule about negative sessions now lives in one place, inside the module, and no caller
can go round it.

## The other combinations

The bracket takes any level narrower than the property's own. `internal private(set)` is the same
idea inside one module, and is written `private(set) var` because `internal` is the default.
`public internal(set)` lets the library's own files change the value freely while other modules
only read it, which suits a value several types in the library update together.

**`private(set)` is not immutability.** The value still changes; it changes only where the type
decides. A `let` property cannot change at all once the initialiser has set it, as lesson 6 showed.
Choose `let` when the value is fixed for the life of the
instance, and `private(set) var` when it moves under the type's own rules.
