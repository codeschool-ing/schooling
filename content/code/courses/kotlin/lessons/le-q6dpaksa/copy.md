---
title: copy, and changing a value without changing it
version: 1
---

A session's properties are `val`s, so marking one as done cannot be `s.done = true`. **`copy` makes
a new session with every property the same except the ones you name**, and leaves the original
untouched:

```kotlin
// Copy.kt
data class Session(val course: String, val minutes: Int, val done: Boolean = false)

fun main() {
    val planned = Session("Kotlin", 45)
    val finished = planned.copy(done = true)
    val longer = planned.copy(minutes = 60)
    println(planned)
    println(finished)
    println(longer)
}
```

```
ana@vm:~/kt/l08$ kotlinc Copy.kt -include-runtime -d copy.jar && java -jar copy.jar
Session(course=Kotlin, minutes=45, done=false)
Session(course=Kotlin, minutes=45, done=true)
Session(course=Kotlin, minutes=60, done=false)
```

`copy` has one parameter per property, each with the current value as its default, so a call names
only what changes: lesson 3's named and default arguments doing exactly what they were made for.

## Why not a `var`

`var done` would let any code holding a session change it, and every other holder would see the
change without being told. **With `val` and `copy`, a session somebody gave you cannot change under
you**; a changed session is a new object, and whoever needs it has to be handed it. Lesson 17 builds
on this: an app's state is a data class, every change is a `copy`, and the screen redraws when it is
given a new value. That only works because the old value never changed.

## A copy is shallow

`copy` copies the properties, and **a property that refers to an object is copied as a reference**:
the new data class points at the same object as the old one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l08-shallow\" aria-label=\"Two data class objects, w44 with label week 44 and w45 with label week 45, made by copy. Each has its own label, but the minutes property of both points with an arrow at one and the same MutableList holding 45, 30 and 60. Adding to the list through w45 is therefore seen through w44.\"><defs><marker id=\"l08-shallow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">w44</text><text x=\"150\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">label = \"week 44\"</text><text x=\"150\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">minutes =</text><rect x=\"40\" y=\"130\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">w45 = w44.copy(…)</text><text x=\"150\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">label = \"week 45\"</text><text x=\"150\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">minutes =</text><path d=\"M262 92 C 350 92 350 118 450 118\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-shallow-ah-amber)\"></path><path d=\"M262 192 C 350 192 350 128 450 128\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-shallow-ah-amber)\"></path><rect x=\"452\" y=\"84\" width=\"230\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"567\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">MutableList&lt;Int&gt;</text><text x=\"567\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[45, 30, 60]</text><text x=\"567\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">one list, two owners</text></svg>", "caption": "copy copies the reference to the list, not the list: both weeks hold the same one."}
```

```kotlin
// Shallow.kt
data class Week(val label: String, val minutes: MutableList<Int>)

fun main() {
    val w44 = Week("week 44", mutableListOf(45, 30))
    val w45 = w44.copy(label = "week 45")
    w45.minutes.add(60)
    println(w44)
    println(w45)
}
```

```
ana@vm:~/kt/l08$ kotlinc Shallow.kt -include-runtime -d shallow.jar && java -jar shallow.jar
Week(label=week 44, minutes=[45, 30, 60])
Week(label=week 45, minutes=[45, 30, 60])
```

Week 44 gained a session of 60 minutes that was only ever added to week 45, because both weeks hold
the same list. **The fix is to keep data classes made of values that cannot change**: a `List`, not a
`MutableList`, so the only way to a different list is to make one, and the copy cannot be changed in
place. Mutable things inside a data class make `copy`, `equals` and `hashCode` all depend on state that
moves.
