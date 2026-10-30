---
title: A struct is copied
version: 1
---

The picture most people bring from other languages is that a variable "points to" an object, so two
variables can point to the same one. **For a struct that picture is wrong.** A struct variable holds
the value itself, and assigning it to another variable makes a second, independent value. Changing
one never changes the other:

```schooling-example
{"language": "swift", "file": "Copies.swift", "parts": [{"code": "// Copies.swift\nstruct StudySession {\n    var course: String\n    var minutes: Int\n}\n", "note": "A struct with two stored properties. Swift writes its initialiser for you, with one argument per property, in the order they are declared."}, {"code": "var monday = StudySession(course: \"Swift\", minutes: 45)\nvar tuesday = monday\ntuesday.minutes = 60\nprint(monday.minutes, tuesday.minutes)\n", "note": "`tuesday = monday` copies the whole value. Changing the copy leaves the original at 45: the first line of output."}, {"code": "func extend(_ session: StudySession) -> StudySession {\n    var longer = session\n    longer.minutes += 15\n    return longer\n}\nlet longer = extend(monday)\nprint(monday.minutes, longer.minutes)\n", "note": "A function receives a copy too, and the parameter is a constant. To change it, the function copies it into a `var` of its own and hands the new value back."}, {"code": "var week = [monday, tuesday]\nvar copy = week\ncopy[0].minutes = 0\nprint(week[0].minutes, copy[0].minutes)", "note": "An array of structs is a value as well, and so is every element in it. The copy's first session went to 0 and the week's did not."}], "output": "45 60\n45 60\n45 0"}
```

The program is cut into its four parts, with a note beside each, and the copy button above it
takes the whole file without the notes. Three pairs of numbers, and in every pair the first one did
not move. **Copying is the rule everywhere a struct goes**: an assignment, a parameter, a return
value and an element of an array.

## A parameter is a constant copy

The function `extend` did not change its parameter directly. It could not:

```swift
// Param.swift
struct StudySession {
    var course: String
    var minutes: Int
}
func extend(_ session: StudySession) {
    session.minutes += 15
}
```

```
ana@vm:~/sw/l05$ swiftc Param.swift -o param
Param.swift:7:21: error: left side of mutating operator isn't mutable: 'session' is a 'let' constant
5 | }
6 | func extend(_ session: StudySession) {
7 |     session.minutes += 15
  |                     `- error: left side of mutating operator isn't mutable: 'session' is a 'let' constant
8 | }
9 | 
```

**A parameter is a `let`**, so a function cannot change the value it was given, whatever its type.
For a struct that is also the only thing it could change: the caller's value was copied on the way
in, so changing the copy would not reach the caller anyway. The function in `Copies.swift` says what
it means instead: it builds a new value and returns it, and the caller decides what to do with it.
Lesson 3's `inout` is the other way, and the `&` at the call site is there to make the exception
visible.

## Why copying is the default

A value that nobody else can change is a value you can reason about locally. When `monday` is 45
minutes on one line, nothing elsewhere in the program can make it 60 behind your back, because
nothing elsewhere holds it. **Every bug of the kind "somebody else changed my data" is impossible
for a struct**, which is the property lesson 15 builds on when two tasks run at once.

The obvious worry is cost: copying an array of a thousand sessions on every assignment sounds
expensive. Section 07 shows that Swift does not actually copy until somebody writes, and that the
copy you reason about is usually never made.
