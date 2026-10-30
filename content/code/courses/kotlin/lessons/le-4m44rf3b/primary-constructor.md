---
title: A class and its primary constructor
version: 1
---

Until now a study session was a `Pair` of a course and a number, and `it.second` said nothing about
what the number was. **A class gives the planner's data names of its own.** In Kotlin the shortest
useful class is one line:

```kotlin
// Course.kt
class Course(val name: String, val weeklyGoal: Int)

fun main() {
    val kotlin = Course("Kotlin", 300)
    println(kotlin.name)
    println(kotlin.weeklyGoal)
    println(kotlin)
}
```

```
ana@vm:~/kt/l07$ kotlinc Course.kt -include-runtime -d course.jar && java -jar course.jar
Kotlin
300
Course@677327b6
```

The parentheses after the class name are its **primary constructor**, and the `val` in front of each
parameter makes it a property as well: one line declares the parameters, the fields that hold them,
the getters that read them, and the code that copies one into the other. The Java class that does
the same is about fifteen lines. There is no `new`: a class is constructed by calling it like a
function, `Course("Kotlin", 300)`.

The last line printed `Course@` and a number, which is the JVM's default text for an object: its
class and a hash code. Lesson 8's data classes replace it with something readable.

## `val`, `var`, or neither

Each constructor parameter can be one of three things:

```kotlin
// Session.kt
class Session(val course: String, val minutes: Int, var done: Boolean = false, date: String) {
    val label = "$date $course"
}

fun main() {
    val s = Session("Kotlin", 45, date = "2026-11-02")
    println(s.label)
    println(s.done)
    s.done = true
    println(s.done)
}
```

```
ana@vm:~/kt/l07$ kotlinc Session.kt -include-runtime -d session.jar && java -jar session.jar
2026-11-02 Kotlin
false
true
```

| parameter | becomes |
|---|---|
| `val course: String` | a read-only property |
| `var done: Boolean = false` | a property that can change, with a default like any function parameter |
| `date: String` | a plain parameter: usable while the object is built, then gone |

`date` is used to compute `label` and is not kept; `s.date` would not compile. **Mark a parameter
`val` only if the object needs it after construction.** And, as everywhere in this course, `val`
until something has to change: a session's course and length are fixed when it is planned, and
whether it is done is the one thing that moves.

## Named and default arguments work here too

A constructor is a function, so lesson 3 applies whole: defaults, names, and the trailing comma. The
call above names `date` because it comes after a parameter with a default, which is exactly the
case lesson 3 said to name.
