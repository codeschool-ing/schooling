---
title: fold and reduce
version: 1
---

`sumOf`, `count` and `maxOf` are each a loop that carries one value from item to item, an
accumulator, and returns it at the end. **`fold` is that loop with nothing decided**: you give the
starting value and the step, and it carries the accumulator through the list.

```kotlin
// Fold.kt
fun main() {
    val minutes = listOf(45, 30, 60, 20)

    val total = minutes.fold(0) { acc, m -> acc + m }
    println(total)

    val report = minutes.fold("week:") { acc, m -> "$acc $m" }
    println(report)

    val longestRun = minutes.fold(0 to 0) { (best, run), m ->
        val now = if (m >= 30) run + 1 else 0
        maxOf(best, now) to now
    }
    println(longestRun.first)

    println(minutes.reduce { acc, m -> acc + m })
    println(minutes.runningFold(0) { acc, m -> acc + m })
}
```

```
ana@vm:~/kt/l05$ kotlinc Fold.kt -include-runtime -d fold.jar && java -jar fold.jar
155
week: 45 30 60 20
3
155
[0, 45, 75, 135, 155]
```

`fold(0) { acc, m -> acc + m }` starts at 0 and adds each item, which is `sum()` written out. The
second fold shows that **the accumulator can be any type**, here a `String` that grows. The third is
where `fold` earns its place: the longest run of sessions of half an hour or more, which no named
function answers. Its accumulator is a pair, the best run so far and the current one, and every
step returns the next pair.

## reduce

`reduce` is `fold` that uses the first item as the starting value. It is shorter when the answer has
the same type as the items, and it has the empty-list problem of section 04: with no first item
there is no starting value, and it throws.

```kotlin
// Reduce.kt
fun main() {
    val none = emptyList<Int>()
    println(none.fold(0) { acc, m -> acc + m })
    println(none.reduceOrNull { acc, m -> acc + m })
    println(none.reduce { acc, m -> acc + m })
}
```

```
ana@vm:~/kt/l05$ kotlinc Reduce.kt -include-runtime -d reduce.jar && java -jar reduce.jar
0
null
Exception in thread "main" java.lang.UnsupportedOperationException: Empty collection can't be reduced.
	at ReduceKt.main(Reduce.kt:20)
	at ReduceKt.main(Reduce.kt)
```

**`fold` has an answer for an empty list, because you gave it one.** That makes it the safer default,
and `reduce` the shorthand for lists you know are not empty.

## runningFold

The last line of `Fold.kt` printed every intermediate accumulator, not only the final one:
`runningFold` is `fold` that keeps its working. For the planner it is a cumulative total across the
week, the line a progress chart draws, and it has one more item than the list, because it includes
the starting value.
