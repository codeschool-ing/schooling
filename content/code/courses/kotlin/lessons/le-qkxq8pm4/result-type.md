---
title: Result: a failure as a value
version: 1
---

`Result<T>` holds either a value of type `T` or the exception that prevented it. **`runCatching { … }`
runs a block and wraps whatever happened**, and the caller then decides what a failure means, with
the failure in its hand as a value rather than flying past it.

```schooling-example
{"language": "kotlin", "file": "ResultDemo.kt", "parts": [{"code": "fun parseMinutes(text: String): Result<Int> = runCatching { text.trim().toInt() }", "note": "The exception `toInt` throws becomes a `Result.failure`; a number becomes a `Result.success`. The function's type now says it can fail."}, {"code": "fun main() {\n    val ok = parseMinutes(\"45\")\n    val bad = parseMinutes(\"forty\")\n    println(ok)\n    println(bad)", "note": "A `Result` prints as `Success(…)` or `Failure(…)` with the exception inside."}, {"code": "    println(ok.map { it * 60 }.getOrElse { -1 })\n    println(bad.map { it * 60 }.getOrElse { -1 })", "note": "`map` transforms the value if there is one and passes a failure through untouched; `getOrElse` unwraps it, with a fallback computed from the exception."}, {"code": "    println(bad.exceptionOrNull()?.message)\n    val text = bad.fold(\n        onSuccess = { \"$it min\" },\n        onFailure = { \"could not read: ${it.message}\" },\n    )\n    println(text)", "note": "`fold` handles both cases at once and returns one value, the `when` of a `Result`."}, {"code": "    val total = listOf(\"45\", \"x\", \"30\").map(::parseMinutes).filter { it.isSuccess }.sumOf { it.getOrThrow() }\n    println(total)\n}", "note": "Parse many, keep the ones that worked. `getOrThrow` is safe here only because of the `filter` before it."}]}
```

```
ana@vm:~/kt/l13$ kotlinc ResultDemo.kt -include-runtime -d resultdemo.jar && java -jar resultdemo.jar
Success(45)
Failure(java.lang.NumberFormatException: For input string: "forty")
2700
-1
For input string: "forty"
could not read: For input string: "forty"
75
```

## Where `runCatching` goes wrong

`runCatching` catches **everything**, every `Throwable`, which section 03 warned against. A bug inside
the block becomes a failure value exactly like an expected one:

```kotlin
// CatchesAll.kt
fun firstSession(minutes: List<Int>): Result<Int> = runCatching { minutes[0] }

fun main() {
    println(firstSession(emptyList()))
    println(firstSession(emptyList()).getOrElse { 0 })
}
```

```
ana@vm:~/kt/l13$ kotlinc CatchesAll.kt -include-runtime -d catchesall.jar && java -jar catchesall.jar
Failure(java.lang.IndexOutOfBoundsException: Empty list doesn't contain element at index 0.)
0
```

Reading the first item of an empty list is a bug, and `runCatching` turned it into a tidy `Failure`
that `getOrElse` turned into `0`. **Keep the block of a `runCatching` to the one call that is expected
to fail**, the parse, the file read, and nothing more. In coroutine code it also catches cancellation,
which lesson 15 shows breaking a scope.

## `Result` or a sealed type

`Result` carries an exception, and an exception carries a message and a stack trace, which is the
right payload for a failure from Java or I/O code you did not write. **For failures your own code
defines, lesson 9's sealed interface is better**: `ParseError.OutOfRange(900)` says what went wrong in
the type, and a `when` over it is checked for completeness, which a `Result`'s `Throwable` never is.
