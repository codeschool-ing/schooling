---
title: Questions with one answer: sums, counts, extremes
version: 1
---

`map` and `filter` give back lists. Many questions about a list want a single value: how many, how
much in total, which one is longest, is there any at all. The standard library has a function for
each, and **knowing their names is most of what writing Kotlin quickly is**.

```kotlin
// Aggregates.kt
fun main() {
    val sessions = listOf("Kotlin" to 45, "Android" to 30, "Kotlin" to 60, "Go" to 20)

    println(sessions.sumOf { it.second })
    println(sessions.count { it.first == "Kotlin" })
    println(sessions.any { it.second > 90 })
    println(sessions.all { it.second >= 20 })
    println(sessions.none { it.first == "Swift" })
    println(sessions.maxBy { it.second })
    println(sessions.minOf { it.second })
    println(sessions.sortedByDescending { it.second }.take(2))
    println(sessions.map { it.first }.distinct())
    println(sessions.firstOrNull { it.first == "Swift" })
}
```

```
ana@vm:~/kt/l05$ kotlinc Aggregates.kt -include-runtime -d aggregates.jar && java -jar aggregates.jar
155
2
false
true
true
(Kotlin, 60)
20
[(Kotlin, 60), (Kotlin, 45)]
[Kotlin, Android, Go]
null
```

| function | answers |
|---|---|
| `sumOf { … }` | the total of a number taken from each item |
| `count { … }` | how many items pass the test |
| `any`, `all`, `none` | whether at least one, every one, or no item passes |
| `maxBy { … }`, `minBy { … }` | the item with the largest or smallest value |
| `maxOf { … }`, `minOf { … }` | that largest or smallest value itself |
| `sortedBy { … }`, `sortedByDescending { … }` | a new list in that order |
| `take(n)`, `drop(n)` | the first `n` items, or all but them |
| `distinct()` | the items with repeats removed, first occurrence kept |
| `first { … }`, `firstOrNull { … }` | the first item that passes |

## `By` and `Of`

The pairs `maxBy`/`maxOf` and `minBy`/`minOf` are easy to mix up, and the output shows the
difference. **`maxBy` returns an item; `maxOf` returns a value computed from one.** The longest
session is `(Kotlin, 60)`, and the shortest length is `20`.

## The ones that fail on an empty list

`first`, `maxBy` and `minBy` have no answer for an empty list, and they throw
`NoSuchElementException` rather than invent one. Each has an `OrNull` sibling, which returns
`null` instead and so returns a nullable type:

```kotlin
// Empty.kt
fun main() {
    val none = listOf<Pair<String, Int>>()
    println(none.sumOf { it.second })
    println(none.maxByOrNull { it.second })
    println(none.maxBy { it.second })
}
```

```
ana@vm:~/kt/l05$ kotlinc Empty.kt -include-runtime -d empty.jar && java -jar empty.jar
0
null
Exception in thread "main" java.util.NoSuchElementException
	at EmptyKt.main(Empty.kt:25)
	at EmptyKt.main(Empty.kt)
```

The sum of nothing is 0, which is a real answer. The longest of nothing is `null` with the `OrNull`
form, and an exception without it. **Use the `OrNull` form whenever the list can be empty**, which
for a student's sessions in a new week is the first thing that happens, and answer the `null` with
lesson 2's tools.
