---
title: A variable assigned once
version: 1
---

**`final` on a variable means it is assigned exactly once**, and the compiler refuses a second
assignment. Lesson 15 used it on a constant; it works on any variable, and the commonest uses are not
constants at all. In a new directory, `~/final`, the smallest case:

```java
// Locals.java
public class Locals {
    public static void main(String[] args) {
        final int maxLoans = 3;
        maxLoans = 4;
    }
}
```

```
ana@vm:~/final$ javac Locals.java
Locals.java:5: error: cannot assign a value to final variable maxLoans
        maxLoans = 4;
        ^
1 error
```

## A field every constructor must set

On a field, `final` says something more useful: **each object gets the value once, while it is being
built, and keeps it.** A book's ISBN identifies that book, and a book whose ISBN changed halfway
through its life would be a different book wearing the old one's identity. A `final` field with no
value in its declaration is a *blank final*, and the compiler checks that every constructor assigns
it. Here the second constructor forgets:

```java
// Book.java
class Book {
    final String isbn;
    String title;

    Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    Book(String title) {
        this.title = title;
    }
}
```

```
ana@vm:~/final$ javac Book.java
Book.java:13: error: variable isbn might not have been initialized
    }
    ^
1 error
```

The caret points at the closing brace of `Book(String title)`, line 13: the place where the
constructor ends without having set `isbn`. This is the check lesson 13 promised: **with `final`, the
compiler refuses a constructor that leaves the field at its default**, where lesson 13's `Copy` left
`null` behind in silence.

The other half of the rule is that nothing assigns the field after the constructor:

```java
// Book.java
class Book {
    final String isbn;
    String title;

    Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    void fixIsbn(String corrected) {
        isbn = corrected;
    }
}
```

```
ana@vm:~/final$ javac Book.java
Book.java:12: error: cannot assign a value to final variable isbn
        isbn = corrected;
        ^
1 error
```

A book with a wrong ISBN is fixed by making a new `Book`, not by editing the old one. Without
`fixIsbn` and with one constructor, the class compiles, and `javap` shows the modifier where the
JVM can see it too:

```java
// Book.java
class Book {
    final String isbn;
    String title;

    Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }
}
```

```
ana@vm:~/final$ javac Book.java && javap -p Book
Compiled from "Book.java"
class Book {
  final java.lang.String isbn;
  java.lang.String title;
  Book(java.lang.String, java.lang.String);
}
```

## A final reference to something that changes

The surprise comes with references. **`final` fixes the variable, and the variable holds a reference,
so what is fixed is which object it leads to.** The object itself can change as much as its class
allows:

```java
// Notes.java
public class Notes {
    public static void main(String[] args) {
        final StringBuilder note = new StringBuilder("Due");
        note.append(" on Friday");
        System.out.println(note);

        final int[] counts = {1, 2, 3};
        counts[0] = 9;
        System.out.println(counts[0] + " " + counts.length);
    }
}
```

```
ana@vm:~/final$ javac Notes.java && java Notes
Due on Friday
9 3
```

Both variables are `final`, and the `StringBuilder` of lesson 7 grew, and the array's first element
became 9. What `final` refuses is pointing the variable somewhere else:

```java
// Reassign.java
public class Reassign {
    public static void main(String[] args) {
        final StringBuilder note = new StringBuilder("Due");
        note = new StringBuilder("Overdue");
    }
}
```

```
ana@vm:~/final$ javac Reassign.java
Reassign.java:5: error: cannot assign a value to final variable note
        note = new StringBuilder("Overdue");
        ^
1 error
```

So a `final` field holding a list, from lesson 31 on, is still a list anybody with the reference can
add to. **An object that cannot change at all needs every field final and every field's object
unchangeable too**, which is what `String` is, and what lesson 29's records come close to.
