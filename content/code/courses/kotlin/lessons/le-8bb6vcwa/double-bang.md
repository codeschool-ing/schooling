---
title: The !! nobody should write
version: 1
---

`!!` converts a `String?` into a `String` by assertion: it tells the compiler "this is not null",
and if it is, it throws a `NullPointerException` on the spot. **It is the one operator that gives
back exactly the crash the two types exist to remove**, and it gets written because it is the
shortest way to make a refusal go away.

```kotlin
// Bang.kt
fun main() {
    val input = "forty"
    val minutes = input.toIntOrNull()!!
    println(minutes)
}
```

```
ana@vm:~/kt/l02$ kotlinc Bang.kt -include-runtime -d bang.jar && java -jar bang.jar
Exception in thread "main" java.lang.NullPointerException
	at BangKt.main(Bang.kt:4)
	at BangKt.main(Bang.kt)
```

The stack trace names the file and the line, `Bang.kt:4`, which is more than a Java
`NullPointerException` from a deep call usually gives you. That is the whole of the improvement.
The program still crashed, and on a phone a crash closes the app in front of the person using it.

## Why it gets written anyway

The compiler refuses `note.length` on a `String?`, and the message lists two fixes: `?.` and `!!.`.
**The second is two characters long and makes the red underline vanish**, and that is the whole
reason it spreads. Each `!!` is a small bet that a value is present, placed by somebody who was
in a hurry, and nothing records the bet.

Code reviews in Kotlin teams read `!!` the way they read a `catch` block that does nothing. It is
allowed, and it needs a reason. There are a few honest ones:

- **a test**, where a crash with a line number is exactly the failure you want;
- **a value that a previous line has made certain** in a way the compiler cannot follow, for
  example a key you just put into a map and read back. Even then, a local `val` with a check is
  usually as short;
- **a quick program you will throw away**, which is most programs in a course and few programs in
  an app.

## What to write instead

Each of the other three answers says something `!!` does not:

```kotlin
// NoBang.kt
fun main() {
    val input = "forty"
    val a = input.toIntOrNull() ?: 0
    val b = input.toIntOrNull() ?: error("minutes must be a number, got '$input'")
    println(a)
    println(b)
}
```

```
ana@vm:~/kt/l02$ kotlinc NoBang.kt -include-runtime -d nobang.jar && java -jar nobang.jar
Exception in thread "main" java.lang.IllegalStateException: minutes must be a number, got 'forty'
	at NoBangKt.main(NoBang.kt:5)
	at NoBangKt.main(NoBang.kt)
```

`error(…)` is a standard library function that throws `IllegalStateException` with the message you
give it. The program still stops, as with `!!`, but **the message says what was expected and what
arrived**, which is what the person reading the log needs. When a crash is the right behaviour,
make it a crash with a sentence in it.
