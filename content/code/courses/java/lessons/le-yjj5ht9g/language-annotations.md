---
title: The annotations the language reads itself
version: 1
---

An annotation is a name with an `@` in front of it, written above a declaration: `@Override` above a
method, `@Deprecated` above a class. **By itself an annotation does nothing at all.** It is a label,
and something has to read it: the compiler, a tool, or a framework while the program runs. This
section is about the handful the compiler reads, which turn a mistake that would compile into one that
does not.

## `@Override`: say what you meant

Lesson 24 met `@Override` as the label on a method that overrides one from a superclass. Here is the
case it exists for, a `toString` with one letter in the wrong case:

```java
// Book.java
public class Book {
    private final String title;

    public Book(String title) {
        this.title = title;
    }

    @Override
    public String tostring() {
        return "Book[" + title + "]";
    }
}
```

```
ana@vm:~/annot$ javac Book.java
Book.java:9: error: method does not override or implement a method from a supertype
    @Override
    ^
1 error
```

Without the annotation this compiles. `tostring` is a perfectly legal new method, nothing calls it, and
printing a `Book` shows `Book@` and a hash code, as in lesson 12, with no hint why. **`@Override` turns
an intention into something the compiler can check**: this method replaces one from above, and if
there is no such method, refuse. Put it on every method you mean to override, `equals`, `hashCode` and
`toString` included.

## `@Deprecated`: say a method is on its way out

A library cannot delete a method the day it finds a better one, because other people's code calls it.
It marks it instead, and the compiler warns every caller. Two forms, one stronger than the other:

```java
// OldDesk.java
public class OldDesk {
    @Deprecated(since = "2.0", forRemoval = true)
    public static void lendBook(String isbn) {
        System.out.println("lent " + isbn);
    }

    @Deprecated
    public static void returnBook(String isbn) {
        System.out.println("returned " + isbn);
    }
}
```

```java
// Counter.java
public class Counter {
    public static void main(String[] args) {
        OldDesk.lendBook("978-0-13-468599-1");
        OldDesk.returnBook("978-0-13-468599-1");
    }
}
```

```
ana@vm:~/annot$ javac OldDesk.java Counter.java
Counter.java:4: warning: [removal] lendBook(String) in OldDesk has been deprecated and marked for removal
        OldDesk.lendBook("978-0-13-468599-1");
               ^
Note: Counter.java uses or overrides a deprecated API.
Note: Recompile with -Xlint:deprecation for details.
1 warning
ana@vm:~/annot$ javac -Xlint:deprecation Counter.java
Counter.java:4: warning: [removal] lendBook(String) in OldDesk has been deprecated and marked for removal
        OldDesk.lendBook("978-0-13-468599-1");
               ^
Counter.java:5: warning: [deprecation] returnBook(String) in OldDesk has been deprecated
        OldDesk.returnBook("978-0-13-468599-1");
               ^
2 warnings
ana@vm:~/annot$ java Counter
lent 978-0-13-468599-1
returned 978-0-13-468599-1
```

The two forms are treated differently, and the difference is the point:

| annotation | what `javac` says by default | meaning |
|---|---|---|
| `@Deprecated` | a two-line `Note:` for the whole file | there is a better way; this one stays |
| `@Deprecated(forRemoval = true)` | a `warning: [removal]` on every call | this will be deleted in a future version |

The first `javac` warned at line 4 and only noted that something in the file was deprecated;
`-Xlint:deprecation` asked for the details and got line 5 as well. `since = "2.0"` records the version
of the library that deprecated it, for whoever reads the documentation. **And the program still ran**:
a deprecated method works exactly as before. The warning is about the next version, which is why it is
easy to ignore and expensive to have ignored. The JDK itself marks methods this way, and lesson 19's
`finalize` is one of them.

## `@SuppressWarnings`: say you have read the warning

```java
// Quiet.java
public class Quiet {
    @SuppressWarnings("removal")
    public static void main(String[] args) {
        OldDesk.lendBook("978-0-13-468599-1");
    }
}
```

```
ana@vm:~/annot$ javac Quiet.java
```

Silence. `@SuppressWarnings("removal")` tells the compiler that this method's author saw the removal
warning and decided. **Put it on the smallest declaration that needs it**, a method rather than a
class, so it does not hide the next warning nobody has seen yet, and add a comment with the reason
when the reason is not obvious.

## `@FunctionalInterface`: say an interface has one method

An interface with exactly one abstract method can be implemented by a lambda, which `java-functional`
is about. `@FunctionalInterface` declares that intent, and the compiler holds the interface to it:

```java
// Rule.java
@FunctionalInterface
public interface Rule {
    boolean allows(String memberId);

    String describe();
}
```

```
ana@vm:~/annot$ javac Rule.java
Rule.java:2: error: Unexpected @FunctionalInterface annotation
@FunctionalInterface
^
  Rule is not a functional interface
    multiple non-overriding abstract methods found in interface Rule
1 error
```

`describe()` is a second abstract method, so a lambda could no longer implement `Rule`, and the
compiler says so at the interface rather than at every lambda that would break later.

The last of the language's own, **`@SafeVarargs`**, is a promise on a method with a generic varargs
parameter, `T... items`, that it does nothing unsafe with the array Java builds for it. It silences a
warning about generics that lesson 35 explains, and like every promise to the compiler it is only as
good as the method behind it.
