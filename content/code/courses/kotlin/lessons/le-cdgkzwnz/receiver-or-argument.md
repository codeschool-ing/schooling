---
title: Five functions, two questions
version: 1
---

`let`, `run`, `with`, `apply` and `also` all do the same thing: **run a block of code with an object
in hand**. That is why they confuse everybody, and why they are worth learning as a set rather than
one by one. Two questions tell them apart, and each has two answers.

1. **Inside the block, how do you refer to the object?** As `it`, a lambda parameter, or as `this`,
   the block's receiver, which can be left out entirely: `sum()` instead of `it.sum()`.
2. **What does the call give back?** The object itself, or whatever the block's last expression is.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l06-scope\" aria-label=\"A two by two grid. Columns: the object is it, a parameter; the object is this, a receiver. Rows: the call returns the block's result; the call returns the object. Cells: let in it and result; run and with in this and result; also in it and object; apply in this and object.\"><defs></defs><text x=\"345\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the object is it</text><text x=\"565\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the object is this</text><text x=\"130\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">returns the</text><text x=\"130\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">block's result</text><text x=\"130\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">returns the</text><text x=\"130\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">object</text><rect x=\"240\" y=\"55\" width=\"210\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"345\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">let</text><text x=\"345\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">x?.let { it.length }</text><rect x=\"460\" y=\"55\" width=\"210\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">run   with</text><text x=\"565\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">x.run { length }</text><rect x=\"240\" y=\"145\" width=\"210\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"345\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--phosphor)\">also</text><text x=\"345\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">x.also { log(it) }</text><rect x=\"460\" y=\"145\" width=\"210\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--phosphor)\">apply</text><text x=\"565\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">x.apply { append(\"…\") }</text><text x=\"455\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">two questions: what is the object called inside, and what comes back</text></svg>", "caption": "The five scope functions on two axes: how the block names the object, and what the call returns."}
```

One program runs all five over the same list and prints what each returned:

```kotlin
// Scope.kt
fun main() {
    val sessions = mutableListOf(45, 30)
    val a = sessions.let { it.sum() }
    val b = sessions.run { sum() }
    val c = with(sessions) { sum() }
    val d = sessions.apply { add(60) }
    val e = sessions.also { it.add(20) }
    println("let   $a")
    println("run   $b")
    println("with  $c")
    println("apply $d")
    println("also  $e")
}
```

```
ana@vm:~/kt/l06$ kotlinc Scope.kt -include-runtime -d scope.jar && java -jar scope.jar
let   75
run   75
with  75
apply [45, 30, 60, 20]
also  [45, 30, 60, 20]
```

`let`, `run` and `with` returned the block's result, the sum, and they ran before anything was
added. `apply` and `also` returned **the list itself**, and that is why both lines print all four
items: `d` and `e` are the same list, which by the time of printing had been given 60 by `apply`
and 20 by `also`.

## What a receiver is

In `run { sum() }`, `sum()` is called on the list without naming it. The block is a **lambda with a
receiver**: its type is written `MutableList<Int>.() -> Int`, and inside it `this` is the list, just
as inside a method `this` is the object. Lesson 4's lambdas had parameters; this kind has an object
it works on, and lesson 11's extension functions are the same idea declared with a name.

`buildList { add(45) }` from lesson 5 was one of these, and so is every block in a Gradle build
script in lesson 19. **When `this` can be left out, a block reads like a small language for one
object**, and that is the reason all of this exists.
