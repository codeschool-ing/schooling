---
title: The star projection: a list of something
version: 1
---

Sometimes a function does not care what a list holds, only that it is a list. `List<Any?>` looks
right and is too narrow in one direction, and `MutableList<Any?>` is wrong for the reason the previous
sections gave. **`List<*>` means "a list of some type I do not know"**, and the compiler allows exactly
what is safe without knowing it:

```kotlin
// Star.kt
fun describe(items: List<*>): String = "${items.size} items, first is ${items.firstOrNull()}"

fun clearAll(items: MutableList<*>) {
    items.clear()
}

fun main() {
    println(describe(listOf(45, 30)))
    println(describe(listOf("Kotlin")))
    val log = mutableListOf(45, 30)
    clearAll(log)
    println(log)
}
```

```
ana@vm:~/kt/l12$ kotlinc Star.kt -include-runtime -d star.jar && java -jar star.jar
2 items, first is 45
1 items, first is Kotlin
[]
```

From a `List<*>` you can read, and what comes out is `Any?`, since it could be anything. From a
`MutableList<*>` you can also call what needs no element, such as `clear` and `size`. What you cannot
do is put anything in:

```kotlin
// StarAdd.kt
fun addZero(items: MutableList<*>) {
    items.add(0)
}

fun main() {
    addZero(mutableListOf("Kotlin"))
}
```

```
ana@vm:~/kt/l12$ kotlinc StarAdd.kt -include-runtime -d staradd.jar
StarAdd.kt:3:15: error: receiver type 'MutableList<*>' contains star projection which prohibits the use of 'fun add(element: E): Boolean'.
    items.add(0)
              ^
```

The compiler cannot know the list holds `Int`s, and in `main` it holds `String`s, so `add(0)` is
refused. **The star is the honest type for "I accept any list and promise not to add to it"**, and
the place you will meet it most is in `when` branches such as lesson 9's `is List<*>`, which is the
next section's subject.
