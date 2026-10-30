---
title: open, for the classes others may extend
version: 1
---

`public` lets another module **use** a class. It does not let that module **subclass** it, or
override its methods, and that surprises everybody who arrives from a language where any visible
class can be extended. **In Swift, extending a class from outside its module is a separate
permission, and it is called `open`.**

The planner's library gains a reminder, a class because lesson 10 kept inheritance for exactly this
kind of thing, a default behaviour other code may refine:

```swift
// Sources/PlannerCore/Reminder.swift
public class Reminder {
    public init() {}
    public func text() -> String { "study today" }
}
```

and the executable tries to make a louder one:

```swift
// Sources/plan/main.swift
import PlannerCore

final class Loud: Reminder {
    override func text() -> String { "STUDY TODAY" }
}

let reminders: [Reminder] = [Reminder(), Loud()]
for reminder in reminders {
    print(reminder.text())
}
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Provisioning 1 / 4]
[Planning deferred tasks]
[6 / 10] PlannerCore
error: SwiftCompile normal x86_64 /home/ana/sw/l17/planner/Sources/plan/main.swift failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    builtin-SwiftPerFileCompile main.swift
/home/ana/sw/l17/planner/Sources/plan/main.swift:5:19: error: overriding non-open instance method outside of its defining module
 3 | 
 4 | final class Loud: Reminder {
 5 |     override func text() -> String { "STUDY TODAY" }
   |                   `- error: overriding non-open instance method outside of its defining module
 6 | }
 7 | 

/home/ana/sw/l17/planner/Sources/plan/main.swift:4:13: error: cannot inherit from non-open class 'Reminder' outside of its defining module
 2 | import PlannerCore
 3 | 
 4 | final class Loud: Reminder {
   |             `- error: cannot inherit from non-open class 'Reminder' outside of its defining module
 5 |     override func text() -> String { "STUDY TODAY" }
 6 | }
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:5:19: error: overriding non-open instance method outside of its defining module
 3 | 
 4 | final class Loud: Reminder {
 5 |     override func text() -> String { "STUDY TODAY" }
   |                   `- error: overriding non-open instance method outside of its defining module
 6 | }
 7 | 

/home/ana/sw/l17/planner/Sources/plan/main.swift:4:13: error: cannot inherit from non-open class 'Reminder' outside of its defining module
 2 | import PlannerCore
 3 | 
 4 | final class Loud: Reminder {
   |             `- error: cannot inherit from non-open class 'Reminder' outside of its defining module
 5 |     override func text() -> String { "STUDY TODAY" }
 6 | }
error: Build failed
```

Two refusals, each printed twice for the reason section 04 gave, and they are two decisions. The class may not be subclassed outside `PlannerCore`,
because it is `public` and not `open`; and even if it could be, `text()` may not be overridden,
because the method is only `public` too. **A class that is `open` still keeps every method closed
unless that method is `open` as well.** Make both open:

```swift
// Sources/PlannerCore/Reminder.swift
open class Reminder {
    public init() {}
    open func text() -> String { "study today" }
}
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[4 / 7] PlannerCore
[13 / 17] plan-product
[18 / 18] plan-product
Build complete! (1.00 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
study today
STUDY TODAY
```

The array holds two `Reminder` values, and the loop calls `text()` on each: the second one runs the
override from `plan`, a module `PlannerCore` knows nothing about.

## Why the default is closed

A class that can be subclassed from outside has two audiences: code that calls it, and code that
replaces parts of it. The second is the harder promise to keep. If `Reminder` later calls `text()`
from a new method, every subclass anywhere now runs inside that method, and a library author who did
not plan for that has changed other people's programs without touching them. **So Swift asks the
author to say, per class and per method, which parts were designed to be replaced.**

Inside one module, nothing changes: an `internal` or `public` class can be subclassed and its
methods overridden by any code in the same module, and `open` would add nothing. To forbid that too,
mark the class `final`, as `Loud` is: a `final` class cannot be subclassed anywhere, including its
own module, and the compiler can call its methods directly rather than looking them up.

`open` applies only to classes and their members. Structs, enums and protocols have no subclasses,
so for them `public` is the widest level there is.
