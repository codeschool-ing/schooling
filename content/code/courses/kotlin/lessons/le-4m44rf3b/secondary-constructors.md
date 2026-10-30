---
title: Secondary constructors, and why they are rare
version: 1
---

A class can have more ways to be built than its primary constructor. **A secondary constructor is
declared in the class body with `constructor`, and it must call the primary one**, directly or
through another secondary, with `: this(…)`. That rule guarantees the property initialisers and
`init` blocks of the previous section run however the object is made.

The planner reads sessions from lines of text, `Kotlin, 45`, as well as building them from values:

```kotlin
// Secondary.kt
class Session(val course: String, val minutes: Int) {
    init {
        require(minutes in 1..600) { "minutes out of range: $minutes" }
    }

    constructor(line: String) : this(
        line.substringBefore(",").trim(),
        line.substringAfter(",").trim().toInt(),
    )
}

fun main() {
    val a = Session("Kotlin", 45)
    val b = Session("Android, 30")
    println("${a.course} ${a.minutes}")
    println("${b.course} ${b.minutes}")
    Session("Go, 900")
}
```

```
ana@vm:~/kt/l07$ kotlinc Secondary.kt -include-runtime -d secondary.jar && java -jar secondary.jar
Kotlin 45
Android 30
Exception in thread "main" java.lang.IllegalArgumentException: minutes out of range: 900
	at Session.<init>(Secondary.kt:4)
	at Session.<init>(Secondary.kt:7)
	at SecondaryKt.main(Secondary.kt:18)
	at SecondaryKt.main(Secondary.kt)
```

The third session came in through the secondary constructor and was still refused by the `init`
block's check. **Every path into the object goes through the primary constructor**, so a rule
written once in `init` covers them all.

## Usually a default or a function instead

Lesson 3's default arguments remove most of the reasons Java needs several constructors. A
`Session(course, minutes = 30)` covers what a second constructor without `minutes` would. And
parsing, as above, often reads better as a function with a name that says what it does:

```kotlin
// Parse.kt
class Session(val course: String, val minutes: Int)

fun parseSession(line: String): Session? {
    val parts = line.split(",")
    if (parts.size != 2) return null
    val minutes = parts[1].trim().toIntOrNull() ?: return null
    return Session(parts[0].trim(), minutes)
}

fun main() {
    println(parseSession("Kotlin, 45")?.minutes)
    println(parseSession("Kotlin, forty"))
}
```

```
ana@vm:~/kt/l07$ kotlinc Parse.kt -include-runtime -d parse.jar && java -jar parse.jar
45
null
```

**A constructor must produce an object or throw.** A function can return `null` for input that is
merely wrong, which for text a student typed is usually the honest answer. Lesson 10 moves functions
like `parseSession` into the class itself, as a companion object, which is where Kotlin code keeps
its factories.
