---
title: Object expressions: an object made on the spot
version: 1
---

An `object` declaration names a single instance for the whole program. **An object expression makes
a new, unnamed object right where it is written**, usually to implement an interface once without
declaring a class for it. It is Kotlin's version of Java's anonymous class.

```kotlin
// Anonymous.kt
fun main() {
    val byLength = object : Comparator<String> {
        override fun compare(a: String, b: String): Int = a.length - b.length
    }
    println(listOf("Kotlin", "Go", "Android").sortedWith(byLength))

    var clicks = 0
    val counter = object {
        fun click() {
            clicks++
        }
    }
    counter.click()
    counter.click()
    println(clicks)
}
```

```
ana@vm:~/kt/l10$ kotlinc Anonymous.kt -include-runtime -d anonymous.jar && java -jar anonymous.jar
[Go, Kotlin, Android]
2
```

`object : Comparator<String> { … }` builds an object that implements Java's `Comparator` interface,
with its one method written inline; `override` says the method fulfils the interface, which lesson 11
covers. `sortedWith` uses it to order the courses by length.

The second object implements nothing and has a function of its own. Like lesson 4's lambdas, **it can
read and change the variables around it**: `clicks` belongs to `main`, and the object's function
increments it.

## A lambda is usually shorter

`Comparator` has a single abstract method, so Kotlin accepts a lambda in its place, and the standard
library has helpers that build one:

```kotlin
// Shorter.kt
fun main() {
    val courses = listOf("Kotlin", "Go", "Android")
    println(courses.sortedWith { a, b -> a.length - b.length })
    println(courses.sortedWith(compareBy { it.length }))
    println(courses.sortedBy { it.length })
}
```

```
ana@vm:~/kt/l10$ kotlinc Shorter.kt -include-runtime -d shorter.jar && java -jar shorter.jar
[Go, Kotlin, Android]
[Go, Kotlin, Android]
[Go, Kotlin, Android]
```

All three lines print the same order. **An object expression earns its place when the interface has
more than one method to implement, or when the object needs state of its own**; for one method, the
lambda says the same in a line. Java interfaces with one method get this conversion automatically, and
a Kotlin interface gets it when declared as `fun interface`.
