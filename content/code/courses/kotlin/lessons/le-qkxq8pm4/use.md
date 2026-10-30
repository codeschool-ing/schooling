---
title: use: closing what was opened, even on failure
version: 1
---

A file, a network connection or a database cursor has to be closed when the program is done with it,
and "done" includes "failed halfway". Java's answer is try-with-resources. **Kotlin's is `use`, an
inline function on anything `AutoCloseable`**, which runs a block and closes the resource afterwards,
whether the block finished or threw.

```kotlin
// Use.kt
class Log(private val name: String) : AutoCloseable {
    init {
        println("open $name")
    }

    fun write(line: String) {
        if (line.isEmpty()) throw IllegalArgumentException("empty line")
        println("write $line")
    }

    override fun close() = println("close $name")
}

fun main() {
    Log("week.log").use { it.write("45 min Kotlin") }
    try {
        Log("bad.log").use { it.write("") }
    } catch (e: IllegalArgumentException) {
        println("caught: ${e.message}")
    }
}
```

```
ana@vm:~/kt/l13$ kotlinc Use.kt -include-runtime -d use.jar && java -jar use.jar
open week.log
write 45 min Kotlin
close week.log
open bad.log
close bad.log
caught: empty line
```

In the second block `write` threw, and `close bad.log` still printed, **before** the exception reached
the `catch`. That is the guarantee: a resource handed to `use` is closed on every path out of the
block. `use` returns the block's value, so it reads like a `let` that cleans up.

## Files

The standard library adds `use`-style helpers to Java's file classes, so reading and writing a small
file is a line each:

```kotlin
// Files.kt
import java.io.File

fun main() {
    val file = File("week.txt")
    file.writeText("45\n30\n60\n")
    val total = file.useLines { lines -> lines.sumOf { it.toInt() } }
    println(total)
    println(file.readLines())
}
```

```
ana@vm:~/kt/l13$ kotlinc Files.kt -include-runtime -d files.jar && java -jar files.jar
135
[45, 30, 60]
```

`useLines` opens the file, hands the block a lazy sequence of its lines, lesson 5's sequences, and
closes the file when the block returns. **The sequence is valid only inside the block**: returning it
and reading it later would read a closed file. `readLines()` reads the whole file into a list and
closes it at once, which is fine for a small file and wasteful for a large one.

Android adds a reason to care. An app that leaks file handles or cursors runs out of them after a
while, and the failure appears far from the code that leaked them. `use` makes the leak impossible to
write by accident.
