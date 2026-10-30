---
title: What one word generates
version: 1
---

Lesson 7's `Course` printed as `Course@677327b6`, and two courses with the same name and goal were
not equal. Both are the JVM's defaults for an object, and both are wrong for a class whose whole job
is to hold values. **`data` in front of `class` tells the compiler the class is its values**, and it
writes the functions that follow from that:

```kotlin
// Data.kt
data class Session(val course: String, val minutes: Int, val done: Boolean = false)

fun main() {
    val a = Session("Kotlin", 45)
    val b = Session("Kotlin", 45)
    println(a)
    println(a == b)
    println(a.hashCode() == b.hashCode())
    println(setOf(a, b).size)
}
```

```
ana@vm:~/kt/l08$ kotlinc Data.kt -include-runtime -d data.jar && java -jar data.jar
Session(course=Kotlin, minutes=45, done=false)
true
true
1
```

The same program with `data` removed:

```kotlin
// Plain.kt
class Session(val course: String, val minutes: Int, val done: Boolean = false)

fun main() {
    val a = Session("Kotlin", 45)
    val b = Session("Kotlin", 45)
    println(a)
    println(a == b)
    println(a.hashCode() == b.hashCode())
    println(setOf(a, b).size)
}
```

```
ana@vm:~/kt/l08$ kotlinc Plain.kt -include-runtime -d plain.jar && java -jar plain.jar
Session@677327b6
false
false
2
```

Four lines, four differences, all from one word. What the compiler generated, from the properties
in the primary constructor:

| function | what it does |
|---|---|
| `toString()` | `Session(course=Kotlin, minutes=45, done=false)`: the class and every property |
| `equals()` | two sessions are equal when every property is equal |
| `hashCode()` | equal sessions have equal hash codes, so sets and map keys work |
| `copy()` | a new session with some properties changed, section 04 |
| `component1()`, `component2()`, … | one per property, in order, for destructuring, section 05 |

**The set is the line that matters most.** Without `data`, a set of sessions holds two identical
sessions, a map keyed by session never finds the key it was given a moment ago, and `distinct()`
removes nothing. Those are bugs that show no error: the program runs and the numbers are wrong.

## When a class should be a data class

When two objects with the same values are the same thing. Two planned sessions of 45 minutes of
Kotlin on the same day are interchangeable, and so are two money amounts or two dates. A
`Tracker` from lesson 7, holding a log that changes, is not: two trackers with equal totals are
still two different trackers, and a data class would say they were equal. **Data classes are for
values; ordinary classes are for things with an identity of their own.** Most of what an Android app
passes between its layers is the first kind, which is why `android-apps` declares data classes
everywhere.
