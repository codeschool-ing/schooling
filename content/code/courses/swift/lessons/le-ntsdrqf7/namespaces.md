---
title: Namespaces without a keyword
version: 1
---

Swift has no `namespace` keyword, and does not need one. **A module is already a namespace**: every
name it declares can be written in full as `ModuleName.Name`, and two modules may each have a
`Week` without either one breaking. Inside a module, **types nest**, and a type with no cases and no
instances is how Swift groups names that belong together.

## Grouping constants in an enum

The planner has a few numbers that every part of it agrees on. Loose global constants would work
and would crowd every file's completions; a struct would work and could be created by mistake. An
enum with **no cases** cannot be created at all, which makes it the conventional container:

```swift
// Sources/PlannerCore/Goals.swift
public enum Goals {
    public static let weekly = 300
    public static let daily = 60

    public enum Level: String {
        case light, steady, intense
    }

    public static func level(for minutes: Int) -> Level {
        switch minutes {
        case ..<weekly: .light
        case weekly..<(weekly * 2): .steady
        default: .intense
        }
    }
}
```

Every name inside is reached through `Goals`: `Goals.weekly`, `Goals.level(for:)`, and the nested
type `Goals.Level`, whose full name says where it belongs. `Level` could have been a top-level enum,
and the nesting costs nothing at run time; it only says that a level means nothing outside goals.

## Two Weeks in one program

The executable now declares a `Week` of its own, a label for the screen, and still needs the
library's:

```swift
// Sources/plan/main.swift
import PlannerCore

struct Week {
    let label: String
}

let mine = Week(label: "week 44")
var theirs = PlannerCore.Week()
theirs.add(200)
theirs.add(150)

print(mine.label, theirs.total, Goals.level(for: theirs.total))
print(String(reflecting: Week.self), String(reflecting: PlannerCore.Week.self))
print(Goals.weekly - theirs.total)
let goals = Goals()
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[6 / 10] PlannerCore
[12 / 13] PlannerCore
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:16:13: error: 'Goals' cannot be constructed because it has no accessible initializers
14 | print(String(reflecting: Week.self), String(reflecting: PlannerCore.Week.self))
15 | print(Goals.weekly - theirs.total)
16 | let goals = Goals()
   |             `- error: 'Goals' cannot be constructed because it has no accessible initializers
17 | 
error: SwiftCompile normal x86_64 /home/ana/sw/l17/planner/Sources/plan/main.swift failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    builtin-SwiftPerFileCompile main.swift
/home/ana/sw/l17/planner/Sources/plan/main.swift:16:13: error: 'Goals' cannot be constructed because it has no accessible initializers
14 | print(String(reflecting: Week.self), String(reflecting: PlannerCore.Week.self))
15 | print(Goals.weekly - theirs.total)
16 | let goals = Goals()
   |             `- error: 'Goals' cannot be constructed because it has no accessible initializers
17 | 
error: Build failed
```

The last line is the point of the empty enum: `'Goals' cannot be constructed because it has no
accessible initializers`. Remove it and the program runs:

```swift
// Sources/plan/main.swift
import PlannerCore

struct Week {
    let label: String
}

let mine = Week(label: "week 44")
var theirs = PlannerCore.Week()
theirs.add(200)
theirs.add(150)

print(mine.label, theirs.total, Goals.level(for: theirs.total))
print(String(reflecting: Week.self), String(reflecting: PlannerCore.Week.self))
print(Goals.weekly - theirs.total)
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[3 / 7] plan-product
[7 / 8] plan-product
[8 / 8] plan-product
Build complete! (0.99 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
week 44 350 steady
plan.Week PlannerCore.Week
-50
```

**A plain `Week` in `plan` means `plan`'s own.** A name declared in the current module wins over an
imported one, and `PlannerCore.Week` reaches past it. `String(reflecting:)` prints the full name of
each type, `plan.Week` and `PlannerCore.Week`: one name, two modules, no clash. 350 minutes is
`steady`, and printing an enum case prints its name.

## When the module name is the clash

Full names need one thing: no type with the same name as its module. In a module called `Planner`
that declares a type called `Planner`, the word `Planner.` in another file is read as the type, and
the module's full names stop being reachable. That is why this package's library is `PlannerCore`.
**Name a module after what it contains as a whole, and its types after what each one is.**

The standard library is a module like any other, called `Swift`. `Swift.print` and `Swift.max`
are the full names of functions you have used since lesson 1, and writing them out is how a type
with a `max` method of its own calls the global one.
