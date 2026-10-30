---
title: Sealed interfaces
version: 1
---

`sealed class` has one limit from being a class: a type can extend only one class, so it can belong to
only one sealed class hierarchy. **A `sealed interface` has the same closed set of implementations, and
a type can implement several interfaces.** It is also the more common form in current Kotlin code,
because most hierarchies have no state to share in a base class anyway.

The planner reads minutes from text a student types, and reading can go wrong in two ways that need
different messages:

```kotlin
// SealedInterface.kt
sealed interface ParseError {
    data class NotANumber(val text: String) : ParseError
    data class OutOfRange(val minutes: Int) : ParseError
}

sealed interface Parsed {
    data class Ok(val minutes: Int) : Parsed
    data class Failed(val error: ParseError) : Parsed
}

fun parse(text: String): Parsed {
    val n = text.trim().toIntOrNull() ?: return Parsed.Failed(ParseError.NotANumber(text))
    if (n !in 1..600) return Parsed.Failed(ParseError.OutOfRange(n))
    return Parsed.Ok(n)
}

fun message(p: Parsed): String = when (p) {
    is Parsed.Ok -> "${p.minutes} min"
    is Parsed.Failed -> when (val e = p.error) {
        is ParseError.NotANumber -> "'${e.text}' is not a number"
        is ParseError.OutOfRange -> "${e.minutes} is outside 1 to 600"
    }
}

fun main() {
    for (input in listOf("45", "forty", "900")) println(message(parse(input)))
}
```

```
ana@vm:~/kt/l09$ kotlinc SealedInterface.kt -include-runtime -d sealedinterface.jar && java -jar sealedinterface.jar
45 min
'forty' is not a number
900 is outside 1 to 600
```

`: ParseError` with no parentheses: an interface has no constructor to call. `when (val e = p.error)`
names the value being tested inside the `when` itself, so the branches can smart cast `e` without a
separate line declaring it.

**`parse` returns a value that says what went wrong, instead of throwing.** The caller cannot forget a
failure, because the `when` over `Parsed` does not compile without the `Failed` branch, and inside it
the `when` over `ParseError` does not compile without both kinds. Lesson 13 compares this with
exceptions and with the standard library's `Result`, and this shape is the one it recommends for
failures a caller is expected to handle.

## Sealed class or sealed interface

**A sealed interface, unless the subtypes share state or a constructor**, in which case the base can
be a sealed class holding it. Both give the same exhaustive `when`, and that is the feature you came
for.
