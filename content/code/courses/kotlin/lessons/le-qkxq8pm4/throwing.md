---
title: Exceptions in Kotlin: no checked exceptions
version: 1
---

An exception stops the function that throws it, and the one that called it, and so on up the calls,
**until something catches it or the program ends**. That part is the same as Java. What Kotlin
removed is Java's checked exceptions: no function declares what it throws, and no caller is forced to
catch anything.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l13-unwind\" aria-label=\"Four stacked calls, main at the bottom, then total, then minutesFrom, then toInt at the top. toInt throws NumberFormatException. An arrow shows the exception going back down through minutesFrom, total and main, none of which catches it, and leaving the program, which ends with a stack trace listing the same calls from the innermost outwards.\"><defs><marker id=\"l13-unwind-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"60\" y=\"20\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">toInt()</text><rect x=\"60\" y=\"70\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">minutesFrom(\"forty\")</text><rect x=\"60\" y=\"120\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">total(lines)</text><rect x=\"60\" y=\"170\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main()</text><text x=\"470\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">throws NumberFormatException</text><path d=\"M330 40 C 360 40 360 190 330 190\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-unwind-ah-amber)\"></path><text x=\"470\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">no catch here</text><text x=\"470\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">no catch here</text><text x=\"470\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">no catch here</text><path d=\"M190 200 L190 236\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-unwind-ah-amber)\"></path><text x=\"470\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">program ends: stack trace</text></svg>", "caption": "An uncaught exception leaves every call on its way out, innermost first, until something catches it or the program ends."}
```

```kotlin
// Throw.kt
fun minutesFrom(text: String): Int = text.trim().toInt()

fun total(lines: List<String>): Int = lines.sumOf { minutesFrom(it) }

fun main() {
    println(total(listOf("45", "30")))
    println(total(listOf("45", "forty")))
}
```

```
ana@vm:~/kt/l13$ kotlinc Throw.kt -include-runtime -d throw.jar && java -jar throw.jar
75
Exception in thread "main" java.lang.NumberFormatException: For input string: "forty"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at java.base/java.lang.Integer.parseInt(Integer.java:778)
	at ThrowKt.minutesFrom(Throw.kt:2)
	at ThrowKt.total(Throw.kt:4)
	at ThrowKt.main(Throw.kt:8)
	at ThrowKt.main(Throw.kt)
```

`toInt()` threw `NumberFormatException` for `"forty"`. Nothing in `minutesFrom`, `total` or `main`
caught it, so it went up through all three, which the stack trace lists from the innermost call
outwards, and the program ended. **The trace is read bottom to top for the path, and top line for the
cause**: the first line names the exception and the input.

## Why Kotlin dropped checked exceptions

In Java, a method that can fail with `IOException` must declare `throws IOException`, and every caller
must catch it or declare it in turn. The intention was that no failure could be forgotten. The effect,
in large codebases, was layers of `catch (Exception e) {}` written to make the compiler stop asking,
which forget every failure at once. **Kotlin's view is that a failure the caller must handle should be
in the return type**, as lesson 9's `Parsed` was and section 06's `Result` is, and that exceptions are
for the failures a caller cannot sensibly handle on the spot.

## `throw` is an expression

Lesson 3 showed `throw` has the type `Nothing`, so it fits anywhere a value is expected:
`val minutes = text.toIntOrNull() ?: throw IllegalArgumentException("not a number: $text")`. That is
the common shape: **turn a missing or wrong value into an exception, with a message, at the line
where it is first known to be wrong**.
