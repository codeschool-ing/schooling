---
title: Destructuring, and why it is by position
version: 1
---

Lesson 5 used `val (long, short) = sessions.partition { … }` and `{ (_, list) -> … }` and promised an
explanation. **Destructuring takes an object apart into several names in one declaration**, and for a
data class it works out of the box:

```kotlin
// Destructure.kt
data class Session(val course: String, val minutes: Int, val done: Boolean = false)

fun main() {
    val s = Session("Kotlin", 45, done = true)
    val (course, minutes) = s
    println("$course $minutes")

    val (_, m, done) = s
    println("$m $done")

    val sessions = listOf(Session("Kotlin", 45), Session("Android", 30))
    for ((c, min) in sessions) println("$c: $min")
    println(sessions.map { (c, min) -> "$c=$min" })
}
```

```
ana@vm:~/kt/l08$ kotlinc Destructure.kt -include-runtime -d destructure.jar && java -jar destructure.jar
Kotlin 45
45 true
Kotlin: 45
Android: 30
[Kotlin=45, Android=30]
```

`val (course, minutes) = s` is `val course = s.component1()` and `val minutes = s.component2()`. The
data class generated one `componentN` per constructor property, **in the order they are declared**,
and destructuring calls them in that order. Names you do not want can be left out at the end, or
skipped with `_` anywhere. The same syntax works in a `for` loop and in a lambda's parameters, which is
what lesson 5 used: `Pair` and map entries have `component1` and `component2` too.

## The names you write do not matter

This is the part that surprises people, and it is the reason to use destructuring with care:

```kotlin
// Swap.kt
data class Note(val title: String, val course: String)

fun main() {
    val (course, title) = Note("Read chapter 3", "Kotlin")
    println("course=$course title=$title")
}
```

```
ana@vm:~/kt/l08$ kotlinc Swap.kt -include-runtime -d swap.jar && java -jar swap.jar
course=Read chapter 3 title=Kotlin
```

The names on the left are new local names, chosen by the person writing that line. **They are matched
to the properties by position, not by name**, so `course` received the title. Both are `String`, so
the compiler had no reason to object, and the program printed a sentence that is wrong. The same
happens to every destructuring in a codebase when somebody reorders the properties of a data class.

So: destructure where the order is obvious and stable, a `Pair`, a map entry, a two-property class
that will stay that way, and **read properties by name, `s.course`, everywhere else**. A join by
position is the kind of connection that keeps working after it has started to be wrong.
