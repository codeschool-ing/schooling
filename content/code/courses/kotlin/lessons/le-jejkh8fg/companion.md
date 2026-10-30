---
title: Companion objects: what belongs to the class, not to an instance
version: 1
---

Kotlin has no `static`. **What Java declares static, Kotlin puts in a `companion object`**: an object
declared inside a class, reached through the class's name, and allowed to see the class's private
members. Lesson 7 left `parseSession` as a loose function and promised it a home; this is it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l10-companion\" aria-label=\"On the left, the class Session, containing its one companion object, which holds MAX_MINUTES, the counter created, and the functions of and parse. On the right, three Session instances, each with its own course and minutes. Arrows from the companion's of function to each instance: every instance was built through it. The companion exists once per class; the instances, as many as there are sessions.\"><defs><marker id=\"l10-companion-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">class Session</text><rect x=\"40\" y=\"60\" width=\"260\" height=\"140\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">companion object</text><text x=\"170\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MAX_MINUTES = 600</text><text x=\"170\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">created = 2</text><text x=\"170\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fun of(…)</text><text x=\"170\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fun parse(…)</text><text x=\"170\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">one per class</text><rect x=\"470\" y=\"30\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Session</text><text x=\"585\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Kotlin\", 45</text><path d=\"M300 150 L468 55\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-companion-ah-amber)\"></path><rect x=\"470\" y=\"96\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Session</text><text x=\"585\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Android\", 30</text><path d=\"M300 150 L468 121\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-companion-ah-amber)\"></path><rect x=\"470\" y=\"162\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Session</text><text x=\"585\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Kotlin\", 60</text><path d=\"M300 150 L468 187\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-companion-ah-amber)\"></path><text x=\"585\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">one per session</text></svg>", "caption": "One companion object for the class, however many instances it builds."}
```

```schooling-example
{"language": "kotlin", "file": "Companion.kt", "parts": [{"code": "class Session private constructor(val course: String, val minutes: Int) {", "note": "`private constructor`: nothing outside the class can call `Session(…)`. The only ways in are the companion's functions."}, {"code": "    companion object {\n        const val MAX_MINUTES = 600\n        private var created = 0", "note": "One companion per class, however many sessions exist. `const val` is a compile-time constant, section 04. `created` is shared by the whole class."}, {"code": "        fun of(course: String, minutes: Int): Session? {\n            if (minutes !in 1..MAX_MINUTES) return null\n            created++\n            return Session(course, minutes)\n        }", "note": "A factory: it can call the private constructor because it is inside the class, and it can refuse by returning `null`, which a constructor cannot do."}, {"code": "        fun parse(line: String): Session? {\n            val minutes = line.substringAfter(\",\").trim().toIntOrNull() ?: return null\n            return of(line.substringBefore(\",\").trim(), minutes)\n        }", "note": "Lesson 7's parser, now inside the class it builds, and going through `of` so the range check lives in one place."}, {"code": "        val count: Int\n            get() = created\n    }\n}", "note": "A read-only view of the private counter."}, {"code": "fun main() {\n    println(Session.of(\"Kotlin\", 45)?.minutes)\n    println(Session.of(\"Kotlin\", 900))\n    println(Session.parse(\"Android, 30\")?.course)\n    println(Session.count)\n    println(Session.MAX_MINUTES)\n}", "note": "Everything is called on the class name, as a Java static would be."}]}
```

```
ana@vm:~/kt/l10$ kotlinc Companion.kt -include-runtime -d companion.jar && java -jar companion.jar
45
null
Android
2
600
```

Two sessions were built and one refused, and `count` says 2. With the constructor private, **every
session in the program went through `of`**, so the range check cannot be skipped and the count cannot
be wrong. Call the constructor from outside and the compiler refuses:

```kotlin
// Direct.kt
class Session private constructor(val course: String, val minutes: Int)

fun main() {
    println(Session("Kotlin", 45).minutes)
}
```

```
ana@vm:~/kt/l10$ kotlinc Direct.kt -include-runtime -d direct.jar
Direct.kt:5:13: error: cannot access 'constructor(course: String, minutes: Int): Session': it is private in 'Session'.
    println(Session("Kotlin", 45).minutes)
            ^^^^^^^
```

## Factory names

The standard library and Android use a few names for companion factories, and following them makes a
class read like the rest of Kotlin: **`of` for building from parts, `parse` or `from` for converting
from another form**, and `create` when building has a side effect. `listOf`, `Duration.parse` and
`Uri.parse` are all this pattern.
