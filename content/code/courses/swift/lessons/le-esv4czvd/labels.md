---
title: Argument labels, and calls that read like sentences
version: 1
---

Most languages give a parameter one name. **Swift gives it two: an argument label, written at the
call, and a parameter name, used inside the function.** The point is the call site, which is read many
more times than the function is written:

```swift
// Labels.swift
func add(minutes: Int, to course: String) {
    print("\(minutes) minutes of \(course)")
}
func describe(_ course: String, for minutes: Int) -> String {
    "\(course): \(minutes) min"
}
add(minutes: 45, to: "Swift")
print(describe("Swift", for: 30))
```

```
ana@vm:~/sw/l03$ swift Labels.swift
45 minutes of Swift
Swift: 30 min
```

In `to course: String`, `to` is the label and `course` the name. The call reads `add(minutes: 45, to:
"Swift")`, which is close to an English sentence, and the body reads `course`, which is what the value
is. Writing `to` inside the body would make no sense, and writing `course:` at the call would read
worse. A parameter written with one word, `minutes: Int`, uses that word as both.

`_` as a label means **no label at the call**: `describe("Swift", for: 30)`. Use it when the
function's name already says what the first argument is, as `describe` does here and `weekTotal` did
in section 02.

## Labels are part of the name

A call has to write the labels the function declared, in the declared order:

```swift
// NoLabels.swift
func add(minutes: Int, to course: String) {
    print("\(minutes) minutes of \(course)")
}
add(45, "Swift")
```

```
ana@vm:~/sw/l03$ swiftc NoLabels.swift -o nolabels
NoLabels.swift:5:4: error: missing argument labels 'minutes:to:' in call
3 |     print("\(minutes) minutes of \(course)")
4 | }
5 | add(45, "Swift")
  |    `- error: missing argument labels 'minutes:to:' in call
6 | 
```

The compiler names the labels it wanted. That is a stronger statement than it looks: **in Swift the
labels are part of the function's identity.** The full name of this function is `add(minutes:to:)`,
which is how documentation and the compiler refer to it, and two functions called `add` with different
labels are two different functions. Lesson 2's `minutes(from:)` was written that way on purpose.

## Choosing labels

Apple's API design guidelines, which most Swift code follows, come down to a few rules:

- **name a function by what it does, and let the first label continue the sentence**: `add(minutes:to:)`,
  `remove(at:)`, `index(of:)`;
- **leave out a label that only repeats the type**: `print(total)`, not `print(value: total)`;
- **prefer clarity at the call over brevity in the declaration**. A label costs one word once, in the
  declaration, and saves a reader every time the call is read.

A useful test is to read the call aloud without looking at the declaration. If it does not say what
happens, a label is missing or misnamed.
