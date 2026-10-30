---
title: Read-only lists and mutable lists
version: 1
---

Lesson 1 left a promise: whether a list can change is decided by its type. Kotlin has **two list
types where Java has one**. `List<Int>` has `get`, `size`, `contains` and every reading function,
and no `add`. `MutableList<Int>` has all of those, plus `add`, `remove` and `set`. The same split
exists for sets and maps.

```kotlin
// Lists.kt
fun main() {
    val week: List<Int> = listOf(45, 30, 60)
    val log: MutableList<Int> = mutableListOf(45, 30)
    log.add(60)
    log.removeAt(0)
    println(week)
    println(log)
    println(week[1])
    println(week.size)
}
```

```
ana@vm:~/kt/l05$ kotlinc Lists.kt -include-runtime -d lists.jar && java -jar lists.jar
[45, 30, 60]
[30, 60]
30
3
```

`week[1]` is `week.get(1)` written with brackets, and positions start at 0. Ask the read-only list to
change, and the compiler does not even find the function:

```kotlin
// AddToList.kt
fun main() {
    val week: List<Int> = listOf(45, 30, 60)
    week.add(90)
}
```

```
ana@vm:~/kt/l05$ kotlinc AddToList.kt -include-runtime -d addtolist.jar
AddToList.kt:4:10: error: unresolved reference 'add' on receiver of type 'List<Int>'.
    week.add(90)
         ^^^
```

## Read-only is not immutable

`List` means **you** cannot change it through this name. It does not promise that nobody can:

```kotlin
// View.kt
fun main() {
    val log = mutableListOf(45, 30)
    val view: List<Int> = log
    log.add(60)
    println(view)
}
```

```
ana@vm:~/kt/l05$ kotlinc View.kt -include-runtime -d view.jar && java -jar view.jar
[45, 30, 60]
```

`view` and `log` are the same list, seen through two types. `view` has no `add`, and the list grew
anyway, because `log` has one. **A `List` parameter is a promise by the function not to change what
it was given**, which is useful and is not the same as the data being frozen. When a function must
hand out a list that nobody can change afterwards, it hands out a copy: `log.toList()` builds a new
list with the same items.

## Which one to declare

The rule is lesson 1's rule one level down. **Declare `List` and expose `List`; keep a
`MutableList` private to the code that fills it.** A function that builds a list uses a
`MutableList` inside and returns it as a `List`, and the standard library's `buildList { … }` does
exactly that in one call:

```kotlin
// Build.kt
fun plannedWeek(): List<Int> = buildList {
    add(45)
    add(30)
    if (true) add(60)
}

fun main() {
    println(plannedWeek())
}
```

```
ana@vm:~/kt/l05$ kotlinc Build.kt -include-runtime -d build.jar && java -jar build.jar
[45, 30, 60]
```

Inside the braces `add` is available, because the block is working on a `MutableList`. What comes
out is typed `List<Int>`, so no caller can add to it. Lesson 17 uses the same pattern for state an
app observes: a private mutable value, and a read-only one handed out.
