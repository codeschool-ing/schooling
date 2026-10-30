---
title: Variance: why a list of Int is a list of Number
version: 1
---

An `Int` is a `Number`. Is a list of `Int` a list of `Number`? **For a list you can only read, yes;
for a list you can change, no**, and Kotlin's types say exactly that.

```kotlin
// Variance.kt
fun total(values: List<Number>): Double = values.sumOf { it.toDouble() }

fun main() {
    val minutes: List<Int> = listOf(45, 30)
    println(total(minutes))

    val log: MutableList<Int> = mutableListOf(45, 30)
    val numbers: MutableList<Number> = log
}
```

```
ana@vm:~/kt/l12$ kotlinc Variance.kt -include-runtime -d variance.jar
Variance.kt:9:38: error: initializer type mismatch: expected 'MutableList<Number>', actual 'MutableList<Int>'.
    val numbers: MutableList<Number> = log
                                     ^
```

`List<Int>` went into a `List<Number>` parameter. `MutableList<Int>` was refused as a
`MutableList<Number>`, and the reason is what the second could do: **a `MutableList<Number>` accepts
`add(2.5)`**, and if `numbers` and `log` were the same list, a `Double` would now be sitting in a list
of `Int`, and the next line reading `log[2]` as an `Int` would fail. A read-only `List` has no `add`,
so the danger does not exist, and the compiler allows it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-variance\" aria-label=\"Three rows. List&lt;Int&gt; to List&lt;Number&gt;: allowed, because List is out and only hands values out. MutableList&lt;Int&gt; to MutableList&lt;Number&gt;: refused, because a MutableList&lt;Number&gt; would accept add(2.5) into a list of Int. Comparator&lt;Number&gt; to Comparator&lt;Int&gt;: allowed in the opposite direction, because Comparator is in and only takes values in.\"><defs><marker id=\"l12-variance-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-variance-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">List&lt;Int&gt;</text><rect x=\"330\" y=\"30\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">List&lt;Number&gt;</text><path d=\"M222 50 L328 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-variance-ah-phosphor)\"></path><text x=\"275\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">fits</text><text x=\"625\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">out: only hands values out</text><rect x=\"20\" y=\"102\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MutableList&lt;Int&gt;</text><rect x=\"330\" y=\"102\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"430\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">MutableList&lt;Number&gt;</text><path d=\"M222 122 L328 122\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-variance-ah-amber)\"></path><text x=\"275\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">no</text><text x=\"625\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refused: add(2.5) would get in</text><rect x=\"20\" y=\"174\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Comparator&lt;Number&gt;</text><rect x=\"330\" y=\"174\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Comparator&lt;Int&gt;</text><path d=\"M222 194 L328 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-variance-ah-phosphor)\"></path><text x=\"275\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">fits</text><text x=\"625\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">in: only takes values in</text></svg>", "caption": "Whether X<Int> fits where X<Number> is wanted depends on whether X only produces values, only consumes them, or both."}
```

## `out`: a type that only produces T

`List` is declared `interface List<out E>`. **`out` on a type parameter promises that the type only
hands `E` out**, as results, and never takes one in, and that promise is what makes `List<Int>` usable
as `List<Number>`. This is called covariance. The compiler holds a class to the promise:

```kotlin
// Out.kt
class Source<out T>(private val item: T) {
    fun get(): T = item
    fun put(value: T) {}
}

fun main() {
    println(Source(45).get())
}
```

```
ana@vm:~/kt/l12$ kotlinc Out.kt -include-runtime -d out.jar
Out.kt:4:20: error: type parameter 'T' is declared as 'out' but occurs in 'in' position in type 'T (of class Source<out T>)'.
    fun put(value: T) {}
                   ^
```

`put` takes a `T` as a parameter, an **in** position, which the `out` forbids. Remove `put` and
`Source<Int>` becomes usable wherever a `Source<Number>` is expected, for the same reason as `List`.
`MutableList<E>` has no `out` because it has `add(element: E)`, and so it is **invariant**: a
`MutableList<Int>` is a `MutableList<Int>` and nothing else.
