---
title: Maps and sets
version: 1
---

A list keeps items in order and allows repeats. **A set allows no repeats**, and a **map** files each
value under a key. Both come in a read-only and a mutable version, as lists do.

```kotlin
// MapsSets.kt
fun main() {
    val goals = mapOf("Kotlin" to 300, "Android" to 240)
    println(goals["Kotlin"])
    println(goals["Swift"])
    println(goals.getOrDefault("Swift", 0))
    println(goals.getValue("Android"))

    val done = mutableMapOf<String, Int>()
    done["Kotlin"] = 45
    done["Kotlin"] = done.getOrDefault("Kotlin", 0) + 60
    done.merge("Android", 30, Int::plus)
    println(done)

    for ((course, goal) in goals) {
        val left = goal - (done[course] ?: 0)
        println("$course: $left min to go")
    }

    val studied = setOf("Kotlin", "Android", "Kotlin")
    println(studied)
    println("Swift" in studied)
}
```

```
ana@vm:~/kt/l05$ kotlinc MapsSets.kt -include-runtime -d mapssets.jar && java -jar mapssets.jar
300
null
0
240
{Kotlin=105, Android=30}
Kotlin: 195 min to go
Android: 210 min to go
[Kotlin, Android]
false
```

## Reading a map gives a nullable value

`goals["Swift"]` printed `null`, and its type is `Int?`. **A map cannot promise a key is there**, so
every plain read is nullable, and lesson 2's tools answer it: `getOrDefault`, or `?: 0` as in the
loop. `getValue` is the read that promises: it returns an `Int` and throws
`NoSuchElementException` when the key is missing, which is right when a missing key is a bug.

## Writing to a mutable map

`done["Kotlin"] = 45` puts a value under a key, replacing any value already there. Adding to an
existing value is a read and a write, and `merge` does both: put 30 under `Android` if nothing is
there, or combine it with what is there using the function given, here `Int::plus`, a reference to
the `+` of `Int`.

`for ((course, goal) in goals)` walks the map's entries and takes each apart into its key and value.

## Sets

`setOf("Kotlin", "Android", "Kotlin")` has two items: the second `Kotlin` was dropped. **`in` asks
whether an item is there**, and on a set it does that without walking every item, which is what a
set is for. `in` works on lists and maps too, where `"Kotlin" in goals` asks about the keys; on a
list it has to look at each item in turn.

## The order of a map or set

`mapOf`, `mutableMapOf` and `setOf` keep the order items were added in, which is why the output
reads in the order the program wrote. That is a property of the default implementations, a
`LinkedHashMap` and a `LinkedHashSet` on the JVM, and not of every map: `HashMap` makes no promise
about order, and code that depends on order should say so by choosing the type that keeps it.
