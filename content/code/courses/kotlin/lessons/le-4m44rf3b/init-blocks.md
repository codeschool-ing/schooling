---
title: init blocks, and the order an object is built in
version: 1
---

A primary constructor has no body of its own. **Code that must run when an object is built goes in
an `init` block**, and a class can have several. They run together with the property initialisers,
in the order they appear in the class, top to bottom.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l07-init\" aria-label=\"Building Planner(&quot;Ana&quot;) as a timeline from left to right. First the constructor parameter owner is assigned. Then, in the order they appear in the class: the property greeting, the first init block, the property sessions, the second init block. Then the object is handed to the caller. A note says a block can only use what is to its left.\"><defs><marker id=\"l07-init-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-init-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l07-init-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">owner = \"Ana\"</text><text x=\"80\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">constructor</text><rect x=\"160\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"220\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">val greeting</text><text x=\"220\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">property</text><path d=\"M140 98 L160 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-amber)\"></path><rect x=\"290\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">init { … }</text><text x=\"350\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">block</text><path d=\"M280 98 L290 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-amber)\"></path><rect x=\"420\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"480\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">val sessions</text><text x=\"480\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">property</text><path d=\"M410 98 L420 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-amber)\"></path><rect x=\"550\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">init { … }</text><text x=\"610\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">block</text><path d=\"M540 98 L550 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-amber)\"></path><text x=\"220\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1.</text><text x=\"350\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2.</text><text x=\"480\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3.</text><text x=\"610\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">4.</text><path d=\"M670 98 L700 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-phosphor)\"></path><text x=\"600\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">then the object is handed back</text><path d=\"M30 190 L690 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-paper-dim)\"></path><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">order in the file = order of execution</text><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">a block can only use what is to its left</text></svg>", "caption": "The constructor's parameters first, then every property initialiser and init block in the order they are written."}
```

```kotlin
// Order.kt
class Planner(val owner: String) {
    val greeting = "planner of $owner".also { println("1. property: $it") }

    init {
        println("2. init: owner is $owner")
    }

    val sessions = mutableListOf<Int>().also { println("3. property: sessions") }

    init {
        println("4. init: ${sessions.size} sessions")
    }
}

fun main() {
    Planner("Ana")
}
```

```
ana@vm:~/kt/l07$ kotlinc Order.kt -include-runtime -d order.jar && java -jar order.jar
1. property: planner of Ana
2. init: owner is Ana
3. property: sessions
4. init: 0 sessions
```

The constructor's parameters are assigned first, which is why every block can use `owner`. After
that, **the order on the screen is the order in the file**. That is simple, and it has one trap: a
block can only use what is above it.

```kotlin
// TooEarly.kt
class Planner(val owner: String) {
    init {
        println("${sessions.size} sessions")
    }

    val sessions = mutableListOf<Int>()
}

fun main() {
    Planner("Ana")
}
```

```
ana@vm:~/kt/l07$ kotlinc TooEarly.kt -include-runtime -d tooearly.jar
TooEarly.kt:4:20: error: variable 'sessions' must be initialized.
        println("${sessions.size} sessions")
                   ^^^^^^^^
```

`sessions` is declared below the `init`, so at that moment it has not been given a value, and the
compiler refuses. **Declare properties first and `init` blocks after them**, and the trap does not
arise.

## Checking what came in

The most common `init` block checks the arguments, so an object that exists is an object that makes
sense:

```kotlin
// Checked.kt
class Session(val course: String, val minutes: Int) {
    init {
        require(course.isNotBlank()) { "a session needs a course" }
        require(minutes in 1..600) { "minutes out of range: $minutes" }
    }
}

fun main() {
    println(Session("Kotlin", 45).minutes)
    Session("Kotlin", 0)
}
```

```
ana@vm:~/kt/l07$ kotlinc Checked.kt -include-runtime -d checked.jar && java -jar checked.jar
45
Exception in thread "main" java.lang.IllegalArgumentException: minutes out of range: 0
	at Session.<init>(Checked.kt:5)
	at CheckedKt.main(Checked.kt:11)
	at CheckedKt.main(Checked.kt)
```

`require` throws `IllegalArgumentException` with the message from its lambda. **An invalid session
now cannot be built at all**, so no code that receives a `Session` has to ask whether its minutes are
sensible. That is the same trade lesson 2 made with `null`: one check where the value is made,
instead of a doubt everywhere it is used.
