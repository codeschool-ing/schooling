---
title: The @ in front of a property
version: 1
---

The first SwiftUI screen anybody writes has a line like this in it. It is shown here as Apple's
documentation shows it, and it is **not run in this course**: SwiftUI is one of Apple's frameworks
and does not exist on Linux, which lesson 1 said and lesson 20 comes back to.

```swift
struct TimerView: View {
    @State private var minutes = 45

    var body: some View {
        Stepper("\(minutes) minutes", value: $minutes, in: 0...600, step: 5)
    }
}
```

`@State` in front of `var minutes`, and `$minutes` further down: two pieces of syntax this course has
not met. **`@State` is a property wrapper**, and `$minutes` is the value it **projects**. Neither is
special to SwiftUI. Both are features of the language, and they are worth understanding from the
outside before you use them every day in `ios-apps`, because a property wrapper changes what reading
and writing a property does, and nothing at the place you read it says so.

## The repetition a wrapper removes

Start with a problem the planner really has. A study session's minutes must stay between 0 and 600,
and so must the week's goal, and so must a break. Lesson 6 gave you the tools to do it by hand: a
private stored property and a computed one in front of it.

```swift
// ByHand.swift
struct StudySession {
    private var storedMinutes = 0
    var minutes: Int {
        get { storedMinutes }
        set { storedMinutes = min(max(newValue, 0), 600) }
    }
}

var session = StudySession()
session.minutes = 45
print(session.minutes)
session.minutes = 900
print(session.minutes)
session.minutes = -5
print(session.minutes)
```

```
ana@vm:~/sw/l16$ swift ByHand.swift
45
600
0
```

It works: 900 became 600 and −5 became 0. **It costs six lines per property**, and the rule, 0 to
600, is written inside the setter of each one. A second property that needs the same rule is six more
lines and a second copy of the rule, and the day somebody changes 600 to 720 in one copy and not the
other is the day the two disagree.

A property wrapper is that pattern, the stored value and the code that guards it, written **once** as
a type, and applied with an `@` to as many properties as need it. Section 03 writes it.

## What the compiler does with the @

When the compiler sees `@Something var x`, it generates, from your one line, what `ByHand.swift` wrote
by hand: a hidden stored property, `_x`, holding an instance of `Something`, and a computed `x` whose
getter and setter go through that instance. **Reading `x` calls code.** In SwiftUI the code behind
`@State` stores the value outside the view and tells SwiftUI to redraw when it changes, which is why
assigning to `minutes` in a SwiftUI view updates the screen. Section 04 shows where `$minutes` comes
from.
