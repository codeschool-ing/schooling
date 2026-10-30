---
title: in: a type that only consumes T
version: 1
---

The opposite case is a type that only takes `T` in and never hands one out. A `Comparator<T>` is one:
it receives two `T`s and returns an `Int`. **A comparator that can compare any two `CharSequence`s can
certainly compare two `String`s**, so a `Comparator<CharSequence>` should be usable where a
`Comparator<String>` is wanted. That is the arrow pointing the other way, called contravariance, and
`in` declares it:

```kotlin
// In.kt
interface Sink<in T> {
    fun put(value: T)
}

class Printer : Sink<Any> {
    override fun put(value: Any) = println("got $value")
}

fun deliver(sink: Sink<Int>, minutes: Int) = sink.put(minutes)

fun main() {
    deliver(Printer(), 45)

    val byLength = Comparator<CharSequence> { a, b -> a.length - b.length }
    println(listOf("Kotlin", "Go", "Android").sortedWith(byLength))
}
```

```
ana@vm:~/kt/l12$ kotlinc In.kt -include-runtime -d in.jar && java -jar in.jar
got 45
[Go, Kotlin, Android]
```

`deliver` wants a `Sink<Int>` and got a `Printer`, which is a `Sink<Any>`. Something that accepts any
value accepts an `Int`, and `in` is what tells the compiler so. `sortedWith` on a list of `String`
wants a `Comparator<in String>`, and a comparator of `CharSequence` fits.

## The rule in one line

| declared | the type | which way it goes |
|---|---|---|
| `out T` | only produces `T` | an `X<Int>` works where an `X<Number>` is wanted |
| `in T` | only consumes `T` | an `X<Number>` works where an `X<Int>` is wanted |
| neither | produces and consumes | an `X<Int>` works only where an `X<Int>` is wanted |

Joshua Bloch's mnemonic for Java's version is "producer extends, consumer super"; Kotlin's words make
it shorter. **A type you read from is `out`; a type you write into is `in`.**

## Variance at the use site

A class that is invariant, such as `MutableList`, can still be used covariantly in one place:
`fun total(values: MutableList<out Number>)` accepts a `MutableList<Int>`, and inside the function
`values.add(…)` is refused, because through that parameter the list is only read. Java writes the same
thing as `List<? extends Number>`.
