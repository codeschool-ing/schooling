---
title: Class delegation with by
version: 1
---

Sometimes a class wants to be a `MutableList` with one behaviour changed, say a list that logs each
addition. Inheriting from `ArrayList` ties it to one implementation and to every internal call
`ArrayList` makes. **Delegation implements the interface by handing every call to an object you
choose, and lets you replace only the ones you care about.** Kotlin writes the handing-over for you:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l11-delegation\" aria-label=\"A call arrives at LoggingList. If it is add, the override in LoggingList runs, prints a line and then calls inner.add. Every other member of MutableList, size, get, remove and the rest, is forwarded by code the compiler generated straight to the inner list. toString, equals and hashCode are not members of the interface and are not forwarded.\"><defs><marker id=\"l11-delegation-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-delegation-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"70\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a call</text><rect x=\"150\" y=\"20\" width=\"250\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">LoggingList</text><rect x=\"170\" y=\"60\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"275\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">override fun add</text><text x=\"275\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">prints, then inner.add</text><rect x=\"170\" y=\"116\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"275\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">generated forwarding:</text><text x=\"275\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">size, get, remove, …</text><text x=\"275\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">toString: not forwarded</text><path d=\"M40 82 L168 82\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-delegation-ah-amber)\"></path><path d=\"M40 138 L168 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-delegation-ah-paper-dim)\"></path><text x=\"70\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add(45)</text><text x=\"70\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">size</text><rect x=\"500\" y=\"60\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">inner</text><text x=\"595\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">MutableList&lt;Int&gt;</text><path d=\"M380 82 L498 90\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-delegation-ah-amber)\"></path><path d=\"M380 138 L498 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-delegation-ah-paper-dim)\"></path></svg>", "caption": "by inner forwards every member of the interface; the class overrides only the ones it changes."}
```

```kotlin
// Delegation.kt
class LoggingList(
    private val inner: MutableList<Int> = mutableListOf(),
) : MutableList<Int> by inner {
    override fun add(element: Int): Boolean {
        println("adding $element")
        return inner.add(element)
    }
}

fun main() {
    val log = LoggingList()
    log.add(45)
    log.add(30)
    println(log.size)
    println(log.sum())
    println(log)
}
```

```
ana@vm:~/kt/l11$ kotlinc Delegation.kt -include-runtime -d delegation.jar && java -jar delegation.jar
adding 45
adding 30
2
75
LoggingList@4617c264
```

`: MutableList<Int> by inner` says: implement `MutableList` by forwarding to `inner`. The interface
has about thirty members, and the compiler wrote a forwarding method for each, except `add`, which
the class overrides. `size` and `sum()` went straight to the inner list.

## What `by` does not forward

The last line printed `LoggingList@` and a hash code, not `[45, 30]`. **Delegation forwards the
members of the interface, and `toString` is not one of them**: it comes from `Any`, which every class
inherits, and `LoggingList` has the default. The same is true of `equals` and `hashCode`. When the
wrapper should print or compare like the thing it wraps, it overrides those three itself:
`override fun toString() = inner.toString()`.

The second trap is subtler. A forwarded call runs on `inner`, so if `inner`'s own `addAll` calls its
own `add`, that call goes to the inner list's `add`, not to the override. **An override catches calls
made on the wrapper, and only those.** With inheritance it would be the other way round, which is
exactly the hidden coupling delegation avoids.

## Why this matters on Android

"Prefer composition over inheritance" is advice in every style guide, and in Java it means writing
the forwarding methods by hand. In Kotlin it is one word, which is why Kotlin code reaches for it
where Java code would have subclassed.
