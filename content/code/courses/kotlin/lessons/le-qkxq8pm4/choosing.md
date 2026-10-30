---
title: Choosing how a function fails
version: 1
---

The planner now has four ways to say something went wrong, and each says something different to the
caller. The choice is not about style; **it is about who is expected to deal with the failure, and
when**.

| the failure | how to report it | example |
|---|---|---|
| absence is normal and has no reason | a nullable result, `T?` | `toIntOrNull()`, `firstOrNull()` |
| expected, with reasons the caller handles differently | a sealed result | `Parsed.Failed(ParseError.OutOfRange(900))` |
| expected, from Java or I/O code with its own exceptions | `Result<T>` with `runCatching` | reading a file that may be missing |
| a bug: the program is wrong if this happens | throw, with `require`, `check` or `error` | stopping a timer that is not running |

The same program, written with each in its place:

```kotlin
// Planner.kt
import java.io.File

sealed interface Parsed {
    data class Ok(val minutes: Int) : Parsed
    data class Bad(val line: String, val reason: String) : Parsed
}

fun parse(line: String): Parsed {
    val n = line.trim().toIntOrNull() ?: return Parsed.Bad(line, "not a number")
    if (n !in 1..600) return Parsed.Bad(line, "outside 1 to 600")
    return Parsed.Ok(n)
}

fun load(path: String): Result<List<String>> = runCatching { File(path).readLines() }

fun weekTotal(parsed: List<Parsed>): Int {
    require(parsed.isNotEmpty()) { "weekTotal needs at least one line" }
    return parsed.filterIsInstance<Parsed.Ok>().sumOf { it.minutes }
}

fun main() {
    File("week.txt").writeText("45\nforty\n900\n30\n")
    for (path in listOf("week.txt", "missing.txt")) {
        load(path).fold(
            onSuccess = { lines ->
                val parsed = lines.map(::parse)
                parsed.filterIsInstance<Parsed.Bad>().forEach { println("skipped '${it.line}': ${it.reason}") }
                println("$path: ${weekTotal(parsed)} min")
            },
            onFailure = { println("$path: could not read (${it::class.simpleName})") },
        )
    }
}
```

```
ana@vm:~/kt/l13$ kotlinc Planner.kt -include-runtime -d planner.jar && java -jar planner.jar
skipped 'forty': not a number
skipped '900': outside 1 to 600
week.txt: 75 min
missing.txt: could not read (FileNotFoundException)
```

A bad line is a `Parsed.Bad`: expected, reported with its reason, and the week goes on. A missing file
is a `Result.failure`, because the exception came from Java's file code and its type says what
happened. An empty week passed to `weekTotal` would be a `require` failure: none of the code above can
produce one, and if a future change did, it would be a bug that should stop the program and be seen.

**The test for each case is one question: if this happens, whose code is wrong?** If nobody's, return
it as a value. If the caller's, throw.
