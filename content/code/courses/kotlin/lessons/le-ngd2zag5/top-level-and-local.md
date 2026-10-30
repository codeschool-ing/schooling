---
title: Top-level, local and private functions
version: 1
---

Section 02 said the top of a file is the normal place for a function. Two more places matter, and
one modifier decides who can see each of them.

## A function inside a function

A function declared inside another one is a **local function**. It can be called only from the body
that declares it, and it can read that body's parameters and `val`s without having them passed in:

```kotlin
// Report.kt
fun report(course: String, sessions: List<Int>): String {
    fun line(label: String, value: Int) = "$course  ${label.padEnd(8)} $value min"
    return line("total", sessions.sum()) + "\n" + line("longest", sessions.max())
}

fun main() {
    println(report("Kotlin", listOf(45, 30, 60)))
}
```

```
ana@vm:~/kt/l03$ kotlinc Report.kt -include-runtime -d report.jar && java -jar report.jar
Kotlin  total    135 min
Kotlin  longest  60 min
```

`line` uses `course`, which belongs to `report`, and nobody passed it. **A local function is the
right size for a helper that has no meaning outside one function**: formatting a line of this
report, here. It cannot be called from anywhere else, so it cannot be misused from anywhere else,
and a reader looking for its callers finds them all on the screen.

`padEnd(8)` pads a string with spaces to eight characters, which is what lines up the numbers.

## `private` at the top of a file

A top-level function is visible from every file in the module by default. **`private` on a
top-level function makes it visible only inside its own file**, which is the Kotlin equivalent of a
private static helper in a Java class:

```kotlin
// Planner.kt
private fun format(minutes: Int) = "${minutes / 60} h ${minutes % 60} min"

fun weekSummary(minutes: List<Int>) = "this week: " + format(minutes.sum())
```

```kotlin
// Main.kt
fun main() {
    println(weekSummary(listOf(45, 30, 60)))
    println(format(135))
}
```

```
ana@vm:~/kt/l03$ kotlinc Planner.kt Main.kt -include-runtime -d planner.jar
Main.kt:4:13: error: cannot access 'fun format(minutes: Int): String': it is private in file.
    println(format(135))
            ^^^^^^
```

Two files, compiled together by naming both. `weekSummary` is public, so `Main.kt` can call it.
`format` is private to `Planner.kt`, and the compiler refuses the call from `Main.kt` by name. Take
that line out and the program builds:

```kotlin
// Main.kt
fun main() {
    println(weekSummary(listOf(45, 30, 60)))
}
```

```
ana@vm:~/kt/l03$ kotlinc Planner.kt Main.kt -include-runtime -d planner.jar && java -jar planner.jar
this week: 2 h 15 min
```

Lesson 7 covers the four visibility modifiers properly, including `internal`, which is the one that
matters once a project has modules in lesson 19.

## The order of declarations does not matter

`main` can call `weekSummary` whether it is declared above or below it, in the same file or another.
Kotlin reads all the declarations of a file, and of every file compiled with it, before it checks a
single call. Arrange a file for the reader: the function that explains the file first, and the
helpers after it.
