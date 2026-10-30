---
title: const, @JvmStatic, and what Java sees
version: 1
---

A companion object is a real object, which is a detail Kotlin code never notices and Java code
always does. `javap`, which the JDK installed in lesson 1, prints what a compiled class declares.
Compile `Companion.kt` from section 03 into a directory of class files and ask it:

```
ana@vm:~/kt/l10$ kotlinc Companion.kt -d classes
ana@vm:~/kt/l10$ ls classes
CompanionKt.class
META-INF
Session$Companion.class
Session.class
ana@vm:~/kt/l10$ javap -cp classes Session
Compiled from "Companion.kt"
public final class Session {
  public static final Session$Companion Companion;
  public static final int MAX_MINUTES;
  public final java.lang.String getCourse();
  public final int getMinutes();
  public static final int access$getCreated$cp();
  public static final void access$setCreated$cp(int);
  public Session(java.lang.String, int, kotlin.jvm.internal.DefaultConstructorMarker);
  static {};
}
ana@vm:~/kt/l10$ javap -cp classes 'Session$Companion'
Compiled from "Companion.kt"
public final class Session$Companion {
  public final Session of(java.lang.String, int);
  public final Session parse(java.lang.String);
  public final int getCount();
  public Session$Companion(kotlin.jvm.internal.DefaultConstructorMarker);
}
```

The class `Session` holds a **static field called `Companion`**, the companion's single instance, of
type `Session$Companion`. Every function lives on that inner class, not on `Session`. From Java,
`Session.of("Kotlin", 45)` therefore does not compile; it has to be `Session.Companion.of(…)`.

`MAX_MINUTES` is the exception: it is a `public static final int` directly on `Session`. **`const val`
is a value known when the program is compiled**, a number, a `String` or a `Boolean` written as a
literal, and the compiler copies it into every place that uses it, the way Java does with a
`static final` constant. A plain `val` in a companion is a property, read through a getter.

## Making Java's call site look like Kotlin's

`@JvmStatic` on a companion function asks the compiler to also put a static method on the outer class,
which forwards to the companion:

```kotlin
// Static.kt
class Session private constructor(val course: String, val minutes: Int) {
    companion object {
        @JvmStatic
        fun of(course: String, minutes: Int): Session = Session(course, minutes)
    }
}
```

```
ana@vm:~/kt/l10$ kotlinc Static.kt -d static
ana@vm:~/kt/l10$ javap -cp static Session
Compiled from "Static.kt"
public final class Session {
  public static final Session$Companion Companion;
  public final java.lang.String getCourse();
  public final int getMinutes();
  public static final Session of(java.lang.String, int);
  public Session(java.lang.String, int, kotlin.jvm.internal.DefaultConstructorMarker);
  static {};
}
```

`Session` now declares `public static Session of(…)` itself, so Java can write `Session.of(…)`.
**From Kotlin, nothing changed.** That is the rule for all of the `@Jvm…` annotations: they change
only what the JVM, and so Java, sees. Write them on a library a Java codebase calls, and leave them off
everywhere else.

## The rules for `const`

`const val` is allowed at the top level of a file, in an `object` and in a companion, and only for a
primitive or a `String` initialised with a value the compiler can compute. `const val TODAY =
LocalDate.now()` is refused, because the value is not known until the program runs; a plain `val` is
the right declaration for it.
