---
title: groupBy, associate and partition
version: 1
---

The planner's weekly screen shows a total per course. That is the question "group the sessions by
course, then sum each group", and **`groupBy` is the first half of it**: it returns a map from each
key to the list of items that had it.

```kotlin
// Grouping.kt
fun main() {
    val sessions = listOf("Kotlin" to 45, "Android" to 30, "Kotlin" to 60, "Go" to 20)

    val byCourse = sessions.groupBy { it.first }
    println(byCourse)
    println(byCourse.mapValues { (_, list) -> list.sumOf { it.second } })

    val (long, short) = sessions.partition { it.second >= 45 }
    println(long)
    println(short)

    println(sessions.associate { it.first to it.second })
    println(sessions.groupingBy { it.first }.eachCount())
}
```

```
ana@vm:~/kt/l05$ kotlinc Grouping.kt -include-runtime -d grouping.jar && java -jar grouping.jar
{Kotlin=[(Kotlin, 45), (Kotlin, 60)], Android=[(Android, 30)], Go=[(Go, 20)]}
{Kotlin=105, Android=30, Go=20}
[(Kotlin, 45), (Kotlin, 60)]
[(Android, 30), (Go, 20)]
{Kotlin=60, Android=30, Go=20}
{Kotlin=2, Android=1, Go=1}
```

Read the first two lines of output together. **`groupBy` keeps every session**, filed under its
course, and the courses appear in the order each was first seen. `mapValues` then turns each list
into its total. The lambda takes the map's entry apart into its key and value, `(_, list)`, with
`_` for the key it does not need; lesson 8 explains that syntax, called destructuring.

## partition

`partition` is a `filter` that keeps both halves: the items that passed, and the ones that did not.
It returns a `Pair` of two lists, and `val (long, short) = …` takes the pair apart into two names,
the same destructuring again.

## associate, and the key that appears twice

`associate` builds a map with one entry per item. The sessions have `Kotlin` twice, and **a map
holds one value per key**, so the output has `Kotlin=60`: the second session replaced the first,
without a word. That is the right behaviour when keys are unique, an id per session for example,
and a silent loss of data when they are not. When you are not sure the keys are unique, `groupBy`
is the one that cannot lose anything.

## groupingBy

`groupingBy { … }.eachCount()` counts per key without building the lists `groupBy` would. It is the
efficient form of `groupBy { … }.mapValues { it.value.size }`, and `groupingBy` has `fold` and
`reduce` per group too, which is the next section's subject.
