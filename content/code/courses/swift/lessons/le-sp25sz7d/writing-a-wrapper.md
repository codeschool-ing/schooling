---
title: Writing a property wrapper
version: 1
---

**A property wrapper is a type marked `@propertyWrapper` with a property called `wrappedValue`.**
That is the whole contract. Everything else, such as what it stores, what it checks and how it is
initialised, is ordinary Swift from lessons 5 and 6:

```schooling-example
{"language": "swift", "file": "Clamped.swift", "parts": [{"code": "@propertyWrapper\nstruct Clamped {\n    private var value: Int\n    let range: ClosedRange<Int>", "note": "**`@propertyWrapper` makes the type usable after an `@`.** What it stores is up to it: here the value and the range it must stay in."}, {"code": "    init(wrappedValue: Int, _ range: ClosedRange<Int>) {\n        self.range = range\n        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)\n    }", "note": "The initialiser the compiler calls. **`wrappedValue:` receives the property's initial value**, the `= 45` below, and the other parameter is whatever is written in brackets after `@Clamped`."}, {"code": "    var wrappedValue: Int {\n        get { value }\n        set { value = min(max(newValue, range.lowerBound), range.upperBound) }\n    }\n}", "note": "The one required member. Every read of a wrapped property calls this getter and every write calls this setter, so **the rule lives here, once**."}, {"code": "struct StudySession {\n    @Clamped(0...600) var minutes = 45\n    @Clamped(0...1200) var weeklyGoal = 300\n}", "note": "Two properties, two ranges, one rule. Each `@Clamped(…)` creates its own `Clamped` instance."}, {"code": "var session = StudySession()\nsession.minutes = 900\nsession.weeklyGoal = 2000\nprint(session.minutes, session.weeklyGoal)\nsession.minutes = -5\nprint(session.minutes)", "note": "Callers read and write `minutes` as a plain `Int`. Nothing at the call site shows that a wrapper is involved, which is the convenience and the risk in one."}]}
```

```
ana@vm:~/sw/l16$ swift Clamped.swift
600 1200
0
```

**One rule, written once, applied to two properties with different ranges**, and the behaviour of
`ByHand.swift` with none of its repetition: 900 minutes became 600, a goal of 2,000 became the 1,200
its range allows, and −5 became 0.

## The hidden storage is real

The compiler's `_minutes` is an ordinary stored property, and code inside the type can use it. It is
`private`, so code outside cannot, which keeps every write going through `wrappedValue`. Inside, it is
the way to reach the wrapper rather than the value:

```swift
// Storage.swift
@propertyWrapper
struct Clamped {
    private var value: Int
    let range: ClosedRange<Int>

    init(wrappedValue: Int, _ range: ClosedRange<Int>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }

    var wrappedValue: Int {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
}

struct StudySession {
    @Clamped(0...600) var minutes = 45

    func describe() -> String {
        "\(minutes) minutes, allowed \(_minutes.range)"
    }
}

let session = StudySession()
print(session.describe())
print(session._minutes.range)
```

```
ana@vm:~/sw/l16$ swiftc Storage.swift -o storage && ./storage
Storage.swift:28:15: error: '_minutes' is inaccessible due to 'private' protection level
17 | 
18 | struct StudySession {
19 |     @Clamped(0...600) var minutes = 45
   |                           `- note: '_minutes' declared here
20 | 
21 |     func describe() -> String {
   :
26 | let session = StudySession()
27 | print(session.describe())
28 | print(session._minutes.range)
   |               `- error: '_minutes' is inaccessible due to 'private' protection level
29 | 
```

**One error, and it is about line 28, outside the type.** `describe()` reads `_minutes.range` on line
22, inside the type, and the compiler had nothing to say about it. The last line asks for the same
thing from outside and is refused, with the reason in lesson 17's vocabulary: `_minutes` is
**inaccessible due to `private` protection level**, and the note points back at the `@Clamped` line
that declared it. Delete line 28 and the program prints the sentence `describe()` builds.

## Three rules worth knowing before writing many

- **The initial value goes through the wrapper.** `= 45` is passed to `init(wrappedValue:)`, which is
  why that initialiser clamps too: `@Clamped(0...600) var minutes = 900` starts at 600, not 900.
- **A wrapper cannot be applied to a `let`.** It needs a setter to mean anything, and the compiler
  refuses `@Clamped(0...600) let minutes = 45`.
- **Wrapped properties of a struct still appear in its memberwise initialiser**, by their plain name:
  `StudySession(minutes: 900)` works, and clamps.

A wrapper is the right tool for a rule about **one value**, the same in every type that has such a
value. A rule that relates two properties, such as a break that must be shorter than the session, is
not one property's business; it belongs in a method of the type, or in its initialiser.
