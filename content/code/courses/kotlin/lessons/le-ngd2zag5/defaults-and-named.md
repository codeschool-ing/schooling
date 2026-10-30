---
title: Default arguments and named arguments
version: 1
---

A study session has a course, a length, a date and whether it is done. Most sessions are planned
for today, are not yet done, and last half an hour. **A default value on a parameter lets a caller
leave it out**, and a named argument lets a caller say which parameter a value is for. Together
they replace the overloads Java needs, one method per combination of arguments.

```schooling-example
{"language": "kotlin", "file": "Describe.kt", "parts": [{"code": "fun describe(\n    course: String,\n    minutes: Int = 30,\n    done: Boolean = false,\n    date: String = \"2026-11-02\",\n): String =\n    \"$date  $course  $minutes min  ${if (done) \"done\" else \"planned\"}\"", "note": "Three parameters with defaults after one without. The comma after the last parameter is allowed, and makes adding a fifth a one-line change in a diff."}, {"code": "fun main() {\n    println(describe(\"Kotlin\"))\n    println(describe(\"Kotlin\", 45))", "note": "Positional arguments fill parameters from the left. Everything not given takes its default."}, {"code": "    println(describe(\"Kotlin\", done = true))", "note": "A named argument skips `minutes` and sets `done` alone, which positions cannot do."}, {"code": "    println(describe(date = \"2026-11-03\", course = \"Android\"))\n}", "note": "Every argument named, in any order."}]}
```

```
ana@vm:~/kt/l03$ kotlinc Describe.kt -include-runtime -d describe.jar && java -jar describe.jar
2026-11-02  Kotlin  30 min  planned
2026-11-02  Kotlin  45 min  planned
2026-11-02  Kotlin  30 min  done
2026-11-03  Android  30 min  planned
```

## Name the arguments a reader cannot guess

`describe("Kotlin", 45, true)` compiles, and a reader has to look up what `true` means.
`describe("Kotlin", 45, done = true)` says it at the call. **Name a `Boolean`, name a number whose
unit is not obvious, and name any argument that comes after a default you skipped.** The Kotlin
standard library does this itself, as in `equals("KOTLIN", ignoreCase = true)` from lesson 1.

Once an argument is named, the ones after it can stay positional only if they are in their own
positions. Put a positional argument where the compiler cannot tell which parameter it fills, and it
refuses:

```kotlin
// Mixed.kt
fun describe(course: String, minutes: Int = 30, done: Boolean = false): String =
    "$course $minutes $done"

fun main() {
    println(describe(minutes = 45, "Kotlin"))
}
```

```
ana@vm:~/kt/l03$ kotlinc Mixed.kt -include-runtime -d mixed.jar
Mixed.kt:6:13: error: no value passed for parameter 'course'.
    println(describe(minutes = 45, "Kotlin"))
            ^^^^^^^^
Mixed.kt:6:36: error: mixing named and positional arguments is not allowed unless the order of the arguments matches the order of the parameters.
    println(describe(minutes = 45, "Kotlin"))
                                   ^^^^^^^^
```

## What defaults compile to

The JVM has no default arguments. The compiler makes one method that takes every parameter, and a
second, hidden one that fills in the defaults and calls the first. **From Kotlin you never see the
difference.** From Java, you see only the method with every parameter, and have to pass them all.
`@JvmOverloads` on the function asks the compiler to also generate the Java-style overloads, one per
default left out, which is what an Android library written in Kotlin does for its Java callers.

## A default is evaluated at each call

`date: String = today()` would call `today()` every time the default is used, not once when the
program starts. That is what makes a default safe to compute from something that changes, and it
is also why a default that does something expensive is expensive at every call that leaves it out.
