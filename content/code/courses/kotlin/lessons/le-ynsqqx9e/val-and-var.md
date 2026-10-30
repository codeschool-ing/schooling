---
title: val and var
version: 1
---

Kotlin has two words for a name that holds a value, and the difference is one question: **can this
name be pointed at something else later?** `val` says no. `var` says yes. Most programmers arriving
from another language reach for the one that changes, because every variable they have used could;
Kotlin's habit is the opposite, and the compiler is what makes the habit cheap.

The study planner this course builds from lesson to lesson starts here, with one course and the
minutes studied this week:

```schooling-example
{"language": "kotlin", "file": "Week.kt", "parts": [{"code": "fun main() {\n    val course = \"Kotlin\"", "note": "`val`: the name `course` will always mean this string. Nothing later in the function can point it somewhere else."}, {"code": "    var minutes = 0\n    minutes += 45\n    minutes += 30", "note": "`var`: a running total has to change, so it is the one place a `var` earns its keep. `+=` reads the old value, adds and stores the new one."}, {"code": "    println(\"$course: $minutes minutes this week\")\n}", "note": "`$name` inside a string puts the value in; section 07 covers the rest of the syntax."}], "output": "Kotlin: 75 minutes this week"}
```

```
ana@vm:~/kt/l01$ kotlinc Week.kt -include-runtime -d week.jar && java -jar week.jar
Kotlin: 75 minutes this week
```

## What the compiler does with a second assignment

Point a `val` somewhere else and the program does not compile:

```kotlin
// Reassign.kt
fun main() {
    val course = "Kotlin"
    course = "Swift"
    println(course)
}
```

```
ana@vm:~/kt/l01$ kotlinc Reassign.kt -include-runtime -d reassign.jar
Reassign.kt:4:5: error: 'val' cannot be reassigned.
    course = "Swift"
    ^^^^^^
```

**This is the point of `val`**: the refusal happens before anything runs, on your machine, rather
than as a wrong value on somebody's phone. A program written mostly with `val` can be read from
top to bottom with a promise attached to every name, and the few `var`s left stand out as the
places where something actually changes.

The rule the Kotlin documentation and the Android code style both give is the same: **declare with
`val`, and change it to `var` only when the compiler tells you that you need to.**

## A `val` is a fixed name, not a frozen value

`val` fixes which object the name points at. It says nothing about whether that object can change
inside:

```kotlin
// Sessions.kt
fun main() {
    val sessions = mutableListOf(45, 30)
    sessions.add(60)
    println(sessions)
    println(sessions.sum())
}
```

```
ana@vm:~/kt/l01$ kotlinc Sessions.kt -include-runtime -d sessions.jar && java -jar sessions.jar
[45, 30, 60]
135
```

`sessions` is a `val`, and the list it names grew from two items to three. What the `val` forbids
is `sessions = mutableListOf()`, a second list under the same name. Whether a list itself can
change is decided by its type, and lesson 5 puts the two kinds of list side by side.

So a `val` holding a mutable list is a common and correct thing to write. A `var` holding a
mutable list is usually one change too many: two different ways for the same data to move, and a
reader has to follow both.
