---
title: Function references
version: 1
---

A lambda that only calls an existing function, `{ m -> isLong(m) }`, says the same thing twice.
**`::isLong` is a reference to the function itself**, and it can go anywhere a lambda of the same
type can.

```kotlin
// References.kt
fun isLong(minutes: Int) = minutes >= 60

fun format(minutes: Int) = "${minutes / 60} h ${minutes % 60} min"

fun main() {
    val week = listOf(45, 30, 60, 90)
    println(week.count(::isLong))
    val toText: (Int) -> String = ::format
    println(toText(135))

    val courses = listOf("Kotlin", "Android", "Go")
    println(courses.map(String::length))

    val prefix = "Kot"
    val startsWithPrefix: (String) -> Boolean = { it.startsWith(prefix) }
    val kotlin = "Kotlin"
    val kotlinStartsWith: (String) -> Boolean = kotlin::startsWith
    println(courses.count(startsWithPrefix))
    println(kotlinStartsWith("Kot"))
}
```

```
ana@vm:~/kt/l04$ kotlinc References.kt -include-runtime -d references.jar && java -jar references.jar
2
2 h 15 min
[6, 7, 2]
1
true
```

Three shapes of reference appear here:

| reference | what it refers to | its type here |
|---|---|---|
| `::isLong` | a top-level function | `(Int) -> Boolean` |
| `String::length` | a member of a type; the object becomes the first parameter | `(String) -> Int` |
| `kotlin::startsWith` | a member of one particular object, **bound** to it | `(String) -> Boolean` |

`String::length` takes the string as its parameter: `map(String::length)` asks each course for its
length. `kotlin::startsWith` already has its object, the string `"Kotlin"`, so the function it
gives takes only the prefix to test. That one is a **bound reference**, and lesson 7 meets the same
shape with an object of a class you wrote.

## Lambda or reference

A reference is shorter only when a lambda would do nothing but forward its arguments. **Once the
lambda adds anything, a second argument, a negation, a conversion, the lambda is clearer**:
`{ !isLong(it) }` cannot be written as a reference, and `{ it.startsWith(prefix) }` above reads
better than any reference could. Reach for `::` when the name of the function says everything the
lambda would have said.
