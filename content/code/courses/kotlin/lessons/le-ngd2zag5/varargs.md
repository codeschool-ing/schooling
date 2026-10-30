---
title: vararg, and the spread operator
version: 1
---

Some functions take any number of values of one kind. `listOf` is one: `listOf()`, `listOf(45)` and
`listOf(45, 30, 60)` are all the same function. **`vararg` marks the parameter that collects them**,
and inside the function it is an array.

```kotlin
// Vararg.kt
fun total(vararg minutes: Int): Int = minutes.sum()

fun main() {
    println(total())
    println(total(45))
    println(total(45, 30, 60))
    val week = intArrayOf(20, 25)
    println(total(*week))
    println(total(10, *week, 5))
}
```

```
ana@vm:~/kt/l03$ kotlinc Vararg.kt -include-runtime -d vararg.jar && java -jar vararg.jar
0
45
135
45
60
```

`vararg minutes: Int` is an `IntArray` inside the function, an array of plain `int` values on the
JVM, which is cheaper than a list of boxed `Integer` objects. For a `vararg` of any other type, such
as `String`, it is an `Array<String>`.

## The spread operator

An array you already have does not go into a `vararg` as it is: `total(week)` would be one argument,
an array, where the function wants `Int`s. **`*week` spreads it**, passing its elements as if they
had been written one by one, and the last line shows it can sit among other arguments. The `*` here
is not multiplication and has nothing to do with pointers; it means "unpack this array into the
argument list".

A `List` does not spread directly. `*week.toIntArray()` converts it first, which copies the list. That
copy is the reason library functions that expect to be handed a collection take a `List` parameter
rather than a `vararg`: the caller then passes what it has, with nothing copied.

## One per function, and usually last

A function may have one `vararg` parameter. It can sit anywhere in the list, but every parameter
after it then has to be passed by name, because the compiler cannot tell where the variable part
ends. **Put it last, or think twice about having it**:

```kotlin
// VarargFirst.kt
fun log(vararg lines: String, prefix: String = "> ") {
    for (line in lines) println(prefix + line)
}

fun main() {
    log("planned", "done")
    log("planned", "done", prefix = "* ")
}
```

```
ana@vm:~/kt/l03$ kotlinc VarargFirst.kt -include-runtime -d varargfirst.jar && java -jar varargfirst.jar
> planned
> done
* planned
* done
```

Without the name, `"* "` would have been a third line rather than a prefix. The default rescues the
first call; the second has to say `prefix =` because nothing else marks where the lines stop.
