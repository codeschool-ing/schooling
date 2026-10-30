---
title: also, for doing something on the way past
version: 1
---

`also` passes the object as `it` and returns the object. **It runs a side effect without changing
what flows through**: a log line, a check, a copy saved somewhere, in the middle of a chain.

```kotlin
// Also.kt
fun main() {
    val long = listOf(45, 30, 60, 90, 20)
        .also { println("loaded ${it.size} sessions") }
        .filter { it >= 45 }
        .also { println("kept ${it.size}") }
        .sorted()
    println(long)

    val minutes = "75".toInt().also { require(it in 1..600) { "out of range: $it" } }
    println(minutes)

    val wrong = "900".toInt().also { require(it in 1..600) { "out of range: $it" } }
    println(wrong)
}
```

```
ana@vm:~/kt/l06$ kotlinc Also.kt -include-runtime -d also.jar && java -jar also.jar
loaded 5 sessions
kept 3
[45, 60, 90]
75
Exception in thread "main" java.lang.IllegalArgumentException: out of range: 900
	at AlsoKt.main(Also.kt:13)
	at AlsoKt.main(Also.kt)
```

The two log lines report the size of the list at two points of the chain, and **take the `also`s out
and the chain computes the same result**, which is the test of a good one. The second use is a check:
`require` throws `IllegalArgumentException` with the message from its lambda when its condition is
false, and lesson 13 returns to it. Here it lets a value be checked at the moment it is made, and the
third case shows the check firing.

## Why `it` and not `this`

`also` and `apply` both return the object. The difference is the name inside, and it follows from
what each is for. `apply` configures the object, so its members should need no prefix. `also` does
something **with** the object, often passing it to somebody else, `log(it)` or `cache.save(it)`, and
an explicit `it` makes that read naturally. Mixing them up still compiles, and makes the code say
something it does not mean.

## A debugging tool, too

`.also { println(it) }` is the quickest way to see what is passing through a chain without breaking
it into named steps. It is worth knowing for exactly that, and worth removing once the bug is
found.
