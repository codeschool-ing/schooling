---
title: Two types where Java has one
version: 1
---

In Java, any variable of an object type can hold `null`, and nothing in the type says whether it
might. The compiler accepts `name.length()` whatever `name` holds, and the program finds out at run
time, with a `NullPointerException`. On Android that exception is the commonest crash there is, and
it was the commonest long before Kotlin. **Kotlin's answer is to split every type in two**: `String`,
which can never hold `null`, and `String?`, which can.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l02-two-types\" aria-label=\"Two boxes. The left, String, holds strings such as &quot;Kotlin&quot;, &quot;&quot; and &quot;read chapter 3&quot;. The right, String?, holds the same strings and null as well. An arrow from String to String? is marked free: every String is a String?. An arrow back from String? to String is marked: needs an answer for null, with the four answers ?., ?:, if != null and !!.\"><defs><marker id=\"l02-two-types-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-two-types-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"40\" width=\"230\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">String</text><text x=\"145\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"Kotlin\"</text><text x=\"145\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"\"</text><text x=\"145\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"read chapter 3\"</text><text x=\"145\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">never null</text><rect x=\"460\" y=\"40\" width=\"230\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">String?</text><rect x=\"480\" y=\"78\" width=\"190\" height=\"82\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"575\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"Kotlin\"</text><text x=\"575\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"\"</text><text x=\"575\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"read chapter 3\"</text><text x=\"575\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">null</text><path d=\"M262 100 L456 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-two-types-ah-phosphor)\"></path><text x=\"359\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">free: every String is a String?</text><path d=\"M456 150 L262 150\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-two-types-ah-amber)\"></path><text x=\"359\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">needs an answer for null</text><text x=\"359\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">?.   ?:   if (x != null)   !!</text><text x=\"360\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Kotlin's two types: the compiler knows which one a value has</text></svg>", "caption": "Every String is a String?, so one direction is free. The way back needs an answer for null, and Kotlin has four."}
```

The planner has a value of each kind. Every study session belongs to a course, so the course name is
always there; a note on the session is optional, so it can be missing:

```kotlin
// Nulls.kt
fun main() {
    val course: String = "Kotlin"
    val note: String? = null
    println(course.length)
    println(note)
}
```

```
ana@vm:~/kt/l02$ kotlinc Nulls.kt -include-runtime -d nulls.jar && java -jar nulls.jar
6
null
```

`println(note)` printed the word `null`, which is fine: printing a missing value is not an error.
What the two types change is what the compiler lets you **do** with each.

## The two refusals

Put `null` into a `String`, and the program does not compile:

```kotlin
// NullAssign.kt
fun main() {
    val course: String = null
    println(course)
}
```

```
ana@vm:~/kt/l02$ kotlinc NullAssign.kt -include-runtime -d nullassign.jar
NullAssign.kt:3:26: error: null cannot be a value of a non-null type 'String'.
    val course: String = null
                         ^^^^
```

And ask a `String?` for its length directly, and the compiler refuses that too, because the value
it would ask might not be there:

```kotlin
// NoteLength.kt
fun main() {
    val note: String? = "read chapter 3"
    println(note.length)
}
```

```
ana@vm:~/kt/l02$ kotlinc NoteLength.kt -include-runtime -d notelength.jar
NoteLength.kt:4:17: error: only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'String?'.
    println(note.length)
                ^
```

Look at what the second refusal says, because it is the menu for the rest of this lesson: **only
safe (`?.`) or non-null asserted (`!!.`) calls are allowed**. The note in this program is not even
missing. The compiler refuses anyway, because the type says it could be, and a type is a promise
about every value, not about this one.

## One direction is free

Every `String` is also a `String?`, so a `String` goes into a `String?` with nothing written:
`val maybe: String? = course` compiles. The other direction, from `String?` to `String`, is the one
that needs an answer to the question "and if it is null?". Kotlin gives four ways to answer it, and
each section that follows is one of them:

| you write | it means | section |
|---|---|---|
| `note?.length` | if `note` is null, the whole expression is null | 03 |
| `note ?: "none"` | if `note` is null, use this instead | 04 |
| `if (note != null) note.length` | inside the check, `note` is a `String` | 05 |
| `note!!.length` | I promise it is not null, and crash if I am wrong | 06 |

The first three handle the missing case. The fourth gives the crash back. Section 07 shows where
the protection ends, which is the line where Kotlin calls Java.
