---
title: Where the protection ends: Java's values
version: 1
---

Kotlin's two types exist only in Kotlin. **A value that comes from Java code has no `?` and no
absence of one**, because Java never wrote it down. Android itself is mostly Java, and so is much
of what a Kotlin program on a computer calls, so this boundary is crossed constantly.

Kotlin's compromise is a third kind of type that you can read but never write: the **platform
type**. A method from Java that returns a `String` gives Kotlin a `String!`, which means "a string,
and nobody knows whether it can be null". The compiler then lets you treat it either way, and
checks nothing.

`System.getenv` is Java. It returns the value of an environment variable, or `null` when the
variable is not set:

```kotlin
// Platform.kt
fun main() {
    val home = System.getenv("STUDY_HOME")
    println("STUDY_HOME has ${home.length} characters")
}
```

```
ana@vm:~/kt/l02$ kotlinc Platform.kt -include-runtime -d platform.jar
ana@vm:~/kt/l02$ STUDY_HOME=/home/ana/study java -jar platform.jar
STUDY_HOME has 15 characters
ana@vm:~/kt/l02$ java -jar platform.jar
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.length()" because "home" is null
	at PlatformKt.main(Platform.kt:4)
	at PlatformKt.main(Platform.kt)
```

**It compiled without a word, and the second run crashed.** `home` was inferred with the platform
type, so `home.length` was allowed exactly as it would be in Java, and it failed exactly as it
would in Java. The message is the JVM's own, naming the Java method that was called on nothing.

## Decide at the border

The fix is to give the value a Kotlin type as soon as it arrives, and to choose the honest one.
The variable can be unset, so its type is `String?`, and the compiler is back in charge:

```kotlin
// PlatformFixed.kt
fun main() {
    val home: String? = System.getenv("STUDY_HOME")
    val dir = home ?: "~/study"
    println("studying in $dir")
}
```

```
ana@vm:~/kt/l02$ kotlinc PlatformFixed.kt -include-runtime -d platformfixed.jar
ana@vm:~/kt/l02$ STUDY_HOME=/home/ana/study java -jar platformfixed.jar
studying in /home/ana/study
ana@vm:~/kt/l02$ java -jar platformfixed.jar
studying in ~/study
```

**Write the type on every value that comes from Java**, and let it be nullable unless the Java
documentation promises otherwise. Declaring `String` instead is also allowed, and Kotlin then
inserts a check at that very line:

```kotlin
// PlatformStrict.kt
fun main() {
    val home: String = System.getenv("STUDY_HOME")
    println("studying in $home")
}
```

```
ana@vm:~/kt/l02$ kotlinc PlatformStrict.kt -include-runtime -d platformstrict.jar && java -jar platformstrict.jar
Exception in thread "main" java.lang.NullPointerException: getenv(...) must not be null
	at PlatformStrictKt.main(PlatformStrict.kt:3)
	at PlatformStrictKt.main(PlatformStrict.kt)
```

A `null` now fails at the border, with a message naming the call it came from, rather than three
calls later at whatever line first used it. That is better than the platform type and worse than
`String?`, which does not fail at all.

## Annotations close part of the gap

Java libraries that care about this mark their methods with annotations such as `@Nullable` and
`@NonNull`, and the Kotlin compiler reads them: an annotated method gives a real `String?` or
`String` rather than a platform type. Android's own libraries are annotated this way, which is why
much of `android-apps` meets proper nullable types rather than `!`-types. An unannotated library is
where the old crash still lives, and the habit above is what keeps it out.
