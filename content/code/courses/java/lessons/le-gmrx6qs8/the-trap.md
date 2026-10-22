---
title: The trap: an equals that takes a Book
version: 1
---

Every class inherits `equals(Object)` from `Object`, and it says two references are equal only when
they point at the same object. Two `Book` objects for the same ISBN are different objects, so the
library wants its own rule. The usual first attempt looks right, compiles, passes a quick test, and
is wrong.

## The attempt

In `~/overload/trap`:

```java
// Book.java
public class Book {
    private final String isbn;
    private final String title;

    public Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    public boolean equals(Book other) {
        return isbn.equals(other.isbn);
    }

    @Override
    public int hashCode() {
        return isbn.hashCode();
    }
}
```

The parameter is `Book`, because a book should only ever be compared with a book. That one word is
the mistake. **`equals(Book)` does not override `equals(Object)`; it overloads it**, and `Book` now
has two `equals` methods side by side. A program that calls it directly sees nothing wrong:

```java
// Trap.java
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class Trap {
    public static void main(String[] args) {
        Book a = new Book("978-85-359-0277-2", "Dom Casmurro");
        Book b = new Book("978-85-359-0277-2", "Dom Casmurro");
        System.out.println("a.equals(b): " + a.equals(b));

        Set<Book> shelf = new HashSet<>();
        shelf.add(a);
        shelf.add(b);
        System.out.println("books in the set: " + shelf.size());
        System.out.println("list contains b: " + List.of(a).contains(b));

        Object asObject = b;
        System.out.println("a.equals(asObject): " + a.equals(asObject));
    }
}
```

```
ana@vm:~/overload/trap$ javac Book.java Trap.java && java Trap
a.equals(b): true
books in the set: 2
list contains b: false
a.equals(asObject): false
```

The first line is the quick test, and it passed. Then a `HashSet` kept **both books**, though they
have the same ISBN and the same hash code, and a list holding `a` said it did not contain `b`. The
last line gives the reason away: the same `b`, held in a variable of type `Object`, is not equal to
`a`.

## Why the collections never see it

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Book after the mistake has two equals methods. Its own equals(Book other) compares ISBNs and is what a.equals(b) reaches, because both variables are declared Book. The equals(Object o) inherited from Object compares identity, and it is the one HashSet.add and List.contains call, because they only know their elements as Object.\"><defs><marker id=\"jv24-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"250\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a.equals(b)</text><text x=\"145\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">both declared Book</text><rect x=\"20\" y=\"180\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">HashSet.add, List.contains</text><text x=\"145\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">only know elements as Object</text><text x=\"145\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">equals(Object)</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><rect x=\"420\" y=\"60\" width=\"260\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">equals(Book other)</text><text x=\"550\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">written by you: compares ISBNs</text><text x=\"550\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">an overload, not an override</text><rect x=\"420\" y=\"160\" width=\"260\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">equals(Object o)</text><text x=\"550\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inherited from Object: same object?</text><text x=\"550\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">what the collections call</text><path d=\"M270 60 L418 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv24-a)\"></path><path d=\"M270 215 L418 200\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv24-a)\"></path></svg>", "caption": "The two methods sit side by side in Book. The compiler picks between them from the declared type of the argument, so the collections never meet the one that was written."}
```

Section 02 said overloads are chosen by the compiler, from the declared types of the arguments. In
`a.equals(b)` both are declared `Book`, so the compiler picked `equals(Book)`, the one Ana wrote.
`HashSet` was compiled years before `Book` existed, and it knows its elements only as `Object`.
**Every collection calls `equals(Object)`**, and in this `Book` that is still `Object`'s version,
which compares identity. So `a` and `b` were two different objects to the set, and both went in.
The same goes for `asObject`: declared `Object`, so `equals(Object)`, so `false`.

## `@Override` finds it

Put the annotation on the attempt, as section 03 says to do on every override:

```java
// Book.java
public class Book {
    private final String isbn;
    private final String title;

    public Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    @Override
    public boolean equals(Book other) {
        return isbn.equals(other.isbn);
    }

    @Override
    public int hashCode() {
        return isbn.hashCode();
    }
}
```

```
ana@vm:~/overload/trap$ javac Book.java
Book.java:11: error: method does not override or implement a method from a supertype
    @Override
    ^
1 error
```

The compiler says what the bug is in one line: **this method overrides nothing.** With the
annotation, the mistake never reaches a set.

## The override that works

```java
// Book.java
public class Book {
    private final String isbn;
    private final String title;

    public Book(String isbn, String title) {
        this.isbn = isbn;
        this.title = title;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof Book book && isbn.equals(book.isbn);
    }

    @Override
    public int hashCode() {
        return isbn.hashCode();
    }
}
```

```
ana@vm:~/overload/trap$ javac Book.java Trap.java && java Trap
a.equals(b): true
books in the set: 1
list contains b: true
a.equals(asObject): true
```

The parameter is `Object`, so this replaces the inherited method and every caller reaches it,
whatever type it declared. `other instanceof Book book` checks the type and names the cast result in
one step, so a `String` or a `null` simply compares as not equal. Now the set holds one book and the
list finds `b`.

`hashCode` was overridden all along, and that matters as much: **two objects that are equal must
have the same hash code**, or a `HashSet` will look for the second in the wrong place and never ask
`equals` at all. Lesson 32 takes that contract apart, and lesson 29's records write both methods for
you.
