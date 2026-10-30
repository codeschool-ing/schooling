---
title: The first program, and what kotlinc made of it
version: 1
---

A Kotlin program starts at a function called `main`. It does not have to live inside a class, it
takes no arguments unless you ask for them, and it returns nothing. Make a directory for this
lesson's programs, `~/kt/l01`, and save this as `Hello.kt` in it:

```kotlin
// Hello.kt
fun main() {
    println("Hello, Kotlin")
}
```

`fun` declares a function. `println` prints a line, and it comes from Kotlin's standard library,
which every Kotlin file can use without an import. There is no semicolon: Kotlin ends a statement
at the end of the line, and accepts a semicolon only where two statements share one.

## Compile, then run

`kotlinc` compiles the file. `-d hello.jar` says where to put the result, and
`-include-runtime` says to put Kotlin's standard library in the same file. Then `java`, the
program the JDK installed, runs it:

```
ana@vm:~/kt/l01$ kotlinc Hello.kt -include-runtime -d hello.jar
ana@vm:~/kt/l01$ ls -lh hello.jar
-rw-r--r-- 1 ana ana 5.5M Oct 30 03:01 hello.jar
ana@vm:~/kt/l01$ java -jar hello.jar
Hello, Kotlin
```

The compiler took a few seconds and printed nothing, which is what success looks like. **The jar is
5.5 MB for a program of three lines**, and almost all of it is the standard library. That is the
price of a jar that runs anywhere a JVM does, with nothing else installed.

## What the jar holds

A jar is a zip file. Leave the runtime out and look inside:

```
ana@vm:~/kt/l01$ kotlinc Hello.kt -d small.jar
ana@vm:~/kt/l01$ ls -lh small.jar
-rw-r--r-- 1 ana ana 1020 Oct 30 03:01 small.jar
ana@vm:~/kt/l01$ unzip -l small.jar
Archive:  small.jar
  Length      Date    Time    Name
---------  ---------- -----   ----
       76  1979-12-31 21:00   META-INF/MANIFEST.MF
      636  1979-12-31 21:00   HelloKt.class
       37  1979-12-31 21:00   META-INF/main.kotlin_module
---------                     -------
      749                     3 files
ana@vm:~/kt/l01$ java -jar small.jar
Hello, Kotlin
```

The program became one class, `HelloKt`: Kotlin puts the functions of `Hello.kt` that are outside
any class into a class named after the file. And this small jar of about a kilobyte still ran with
plain `java`, which is a surprise worth explaining. `println` is one of the standard library's
**inline** functions: the compiler copied its body, a call to Java's own `System.out.println`, into
`HelloKt`, so nothing from Kotlin's library is needed at run time. Lesson 4 says what `inline` is
for.

Most of the library is not inlined. Two lines that use a list are enough to need it:

```kotlin
// Courses.kt
fun main() {
    val courses = listOf("Kotlin", "Android")
    println(courses.joinToString(" then "))
}
```

```
ana@vm:~/kt/l01$ kotlinc Courses.kt -d courses-small.jar
ana@vm:~/kt/l01$ java -jar courses-small.jar 2>&1 | head -2
Exception in thread "main" java.lang.NoClassDefFoundError: kotlin/collections/CollectionsKt
	at CoursesKt.main(Courses.kt:3)
ana@vm:~/kt/l01$ kotlin courses-small.jar 2>&1 | head -2
Exception in thread "main" java.lang.NoClassDefFoundError: kotlin/collections/CollectionsKt
	at CoursesKt.main(Courses.kt:3)
ana@vm:~/kt/l01$ kotlin -cp courses-small.jar CoursesKt
Kotlin then Android
ana@vm:~/kt/l01$ java -cp courses-small.jar:$HOME/.local/share/kotlinc/lib/kotlin-stdlib.jar CoursesKt
Kotlin then Android
```

`NoClassDefFoundError: kotlin/collections/CollectionsKt` is the JVM saying it went looking for the
class that holds `listOf` and found nothing. **The fix is the class path, not the code.** The
`kotlin` runner that came with the compiler does not rescue a jar handed to it whole, and fails the
same way `java` does. Given the jar as a class path and the class to start, it adds the standard
library to the class path for you, and the same small jar runs. Or say it to `java` yourself, with
`-cp` naming both jars, separated by a colon.

This course uses `-include-runtime` and `java -jar` throughout, because a file that carries its own
library is one less thing to get wrong. `android-apps` never sees either: Gradle packages the
standard library into the app.

## When the compiler refuses

Most of what this course teaches is what the compiler refuses to let through, so it is worth
reading one refusal now. A typo:

```kotlin
// Typo.kt
fun main() {
    printn("Hello, Kotlin")
}
```

```
ana@vm:~/kt/l01$ kotlinc Typo.kt -include-runtime -d typo.jar; echo $?
Typo.kt:3:5: error: unresolved reference 'printn'.
    printn("Hello, Kotlin")
    ^^^^^^
1
ana@vm:~/kt/l01$ ls typo.jar
ls: cannot access 'typo.jar': No such file or directory
```

**The message starts with the file, the line and the column**, `Typo.kt:3:5`, then the kind,
`error`, then the reason, then the line itself with the name underlined. Line 3, because the
comment naming the file is line 1. An unresolved reference is a name the compiler could not find
anywhere it looked. The `1` is `kotlinc`'s exit status, and `ls` confirms the rest: **a file with
an error produces no jar at all**, not a jar with the broken part left out.
