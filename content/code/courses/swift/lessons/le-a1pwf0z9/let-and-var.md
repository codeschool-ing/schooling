---
title: let and var
version: 1
---

Swift has two words for giving a value a name, and the difference between them is the first thing
the compiler will hold you to. **`let` names a constant: once it has a value, it keeps that
value.** `var` names a variable, which can be given a new value as often as you like.

A student sets a weekly goal of 300 minutes and then tries to raise it:

```swift
// Goal.swift
let goal = 300
goal = 360
print(goal)
```

```
ana@vm:~/sw/l01$ swiftc Goal.swift -o goal
Goal.swift:3:1: error: cannot assign to value: 'goal' is a 'let' constant
1 | // Goal.swift
2 | let goal = 300
  | `- note: change 'let' to 'var' to make it mutable
3 | goal = 360
  | `- error: cannot assign to value: 'goal' is a 'let' constant
4 | print(goal)
5 | 
```

**The compiler refuses, and no program is written.** Read the message from the top. The first line
gives the file, the line and the column, `Goal.swift:3:1`, then the kind of message, `error`, then
what is wrong. Below it the compiler reprints the lines around the problem, with a mark under the
place it means, and a `note` that points at line 2, where `goal` was declared, with the fix: change
`let` to `var`. Most Swift errors have this shape, and the note is often the answer.

## When a value has to change

Minutes studied during the week are a running total, so they belong in a `var`:

```swift
// Week.swift
let goal = 300
var studied = 0
studied += 45
studied += 30
studied += 60
print("\(studied) of \(goal) minutes")
```

```
ana@vm:~/sw/l01$ swiftc Week.swift -o week && ./week
135 of 300 minutes
```

`+=` adds to a variable in place: `studied += 45` is `studied = studied + 45`. Both `goal` and
`studied` are numbers, and only one of them is allowed to move.

## The compiler's opinion about var

Swift prefers `let`, and says so. Inside a function, a `var` that is never given a new value earns
a warning:

```swift
// Warn.swift
func weekReport() {
    var goal = 300
    var studied = 0
    studied += 45
    print("\(studied) of \(goal) minutes")
}
weekReport()
```

```
ana@vm:~/sw/l01$ swiftc Warn.swift -o warn && ./warn
Warn.swift:3:9: warning: variable 'goal' was never mutated; consider changing to 'let' constant [#VariableNeverMutated]
1 | // Warn.swift
2 | func weekReport() {
3 |     var goal = 300
  |         `- warning: variable 'goal' was never mutated; consider changing to 'let' constant [#VariableNeverMutated]
4 |     var studied = 0
5 |     studied += 45

[#VariableNeverMutated]: <https://docs.swift.org/compiler/documentation/diagnostics/variable-never-mutated>
45 of 300 minutes
```

This time the program was written and it ran: a **warning** is advice, and only an `error` stops
the build. The compiler noticed that `goal` is declared with `var` and never reassigned, and
suggests `let`. The last line of the warning is a link to a page that explains the diagnostic,
and every warning with a name in square brackets has one.

The warning appears here and did not in `Week.swift` because the compiler checks names inside a
function this way, where it can see every use. A name at the top level of a file is visible to the
rest of the program, and the compiler does not try. Lesson 3 is about functions.

**Why the preference matters.** A `let` is a promise to the reader: whatever this value was on line
2, it still is. When you read a hundred lines later that `goal` is 300, you do not have to search
for a line that changed it. In an app, where a value can be read by several parts of the code at
once, lesson 15 shows that a value nobody can change is also a value nobody can change at the wrong
moment. **Write `let` by default, and change it to `var` when the compiler or the program asks.**

## let does not freeze everything

`let` fixes the name to a value. What that means for a list or a record depends on whether the value
is a value type or a reference type, which is lesson 5's subject. For the numbers and text in this
lesson, the two ideas coincide: a `let` number cannot change at all.
