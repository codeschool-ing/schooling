---
title: inline, and the return that leaves the outer function
version: 1
---

Section 02 showed a lambda as an object with an `invoke` method. Passing one costs an object, and
calling it costs a call through that object. **An `inline` function asks the compiler to copy its
body, and the body of the lambda passed to it, into every place it is called**, so neither the
object nor the call exists at run time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-inline\" aria-label=\"Two columns compare one call, repeat(2) { println(it) }. On the left, without inline: main creates a Function1 object holding the lambda, calls repeat, which calls invoke on the object twice. On the right, with inline: the compiler copies the loop and the println into main, so main contains the loop directly and no object or extra call exists at run time.\"><defs><marker id=\"l04-inline-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">repeat(2) { println(it) }</text><text x=\"180\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">without inline</text><text x=\"540\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">with inline</text><rect x=\"40\" y=\"66\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">main: new lambda object</text><path d=\"M180 106 L180 128\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inline-ah-amber)\"></path><rect x=\"40\" y=\"130\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">repeat(2, lambda)</text><path d=\"M180 170 L180 192\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inline-ah-amber)\"></path><rect x=\"40\" y=\"194\" width=\"280\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lambda.invoke(0)</text><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lambda.invoke(1)</text><text x=\"180\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">an object, and a call per item</text><rect x=\"400\" y=\"66\" width=\"280\" height=\"186\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">main, after the compiler copied</text><rect x=\"420\" y=\"104\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">for (i in 0 until 2) {</text><text x=\"540\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">    println(i)</text><text x=\"540\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"540\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">no object, no extra call</text><text x=\"540\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the code itself, where the call was</text></svg>", "caption": "An inline function is not called: its body, and the lambda's, are copied into the caller."}
```

Lesson 1 met this without the name: `println` is inline, which is why its body ended up in `HelloKt`.
Every collection function in lesson 5 is inline for the same reason, and `repeat` is too.

## The `return` that inlining allows

Copying the lambda's body into the caller has a consequence for `return`. Inside an inline function's
lambda, **a bare `return` leaves the function the lambda was written in**, because after inlining
that is literally where the code sits. This is called a non-local return:

```kotlin
// Inline.kt
fun firstLong(week: List<Int>): Int? {
    week.forEach { if (it >= 60) return it }
    return null
}

fun printUntilLong(week: List<Int>) {
    week.forEach {
        if (it >= 60) return@forEach
        println("short: $it")
    }
    println("done")
}

fun main() {
    println(firstLong(listOf(45, 90, 30)))
    println(firstLong(listOf(20)))
    printUntilLong(listOf(45, 90, 30))
}
```

```
ana@vm:~/kt/l04$ kotlinc Inline.kt -include-runtime -d inline.jar && java -jar inline.jar
90
null
short: 45
short: 30
done
```

`forEach` is inline, so `return it` in `firstLong` returns from `firstLong`, which reads like the loop
it replaces. In `printUntilLong`, **`return@forEach` returns from the lambda only**: it skips 90 and
carries on with 30, as `continue` would in a loop, and then `done` prints. The label is the name of
the function the lambda was passed to.

## Why a plain lambda refuses it

A function that is not inline keeps its lambda as an object, which can be stored and called later,
after the outer function has long returned. A `return` from inside it would have nowhere to go:

```kotlin
// NotInline.kt
fun twice(action: () -> Unit) {
    action()
    action()
}

fun stopEarly() {
    twice { return }
    println("unreachable?")
}

fun main() {
    stopEarly()
}
```

```
ana@vm:~/kt/l04$ kotlinc NotInline.kt -include-runtime -d notinline.jar
NotInline.kt:8:13: error: 'return' is prohibited here.
    twice { return }
            ^^^^^^
```

**This is the rule from section 03, explained**: a bare `return` belongs to the nearest `fun`, and
it is allowed in a lambda only when the lambda is inlined into that `fun`. Declare `twice` as
`inline fun` and the same file compiles.

## When to write `inline` yourself

Rarely. It pays when a function takes a lambda and is called often, and the standard library has
already done it for the functions you call most. Inlining a large function copies it into every
caller, which grows the program, and the compiler warns when `inline` buys nothing, on a function
with no function parameters. Lesson 12 meets the one case where `inline` is required rather than
an optimisation: `reified` type parameters.
