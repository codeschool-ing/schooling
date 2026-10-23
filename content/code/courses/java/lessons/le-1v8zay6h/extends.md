---
title: `extends`, and what a subclass gets for free
version: 1
---

A library lends books and DVDs. Both have a title and a year, both are lent for some number of days,
and both describe themselves the same way. A book also has an author and a DVD has a running time.
Writing the shared part twice would mean fixing every mistake in it twice. **Inheritance writes the
shared part once, in a class the others extend**, and each of them adds only what is its own.

Make a directory for this lesson, `~/inherit`, and save four files in it. First the shared part:

```java
// Item.java
public class Item {
    protected final String title;
    private final int year;

    public Item(String title, int year) {
        this.title = title;
        this.year = year;
    }

    public int loanDays() {
        return 14;
    }

    public String describe() {
        return title + " (" + year + "), " + loanDays() + " days";
    }
}
```

Then two classes that extend it:

```java
// Book.java
public class Book extends Item {
    private final String author;

    public Book(String title, int year, String author) {
        super(title, year);
        this.author = author;
    }

    public String author() {
        return author;
    }
}
```
```java
// Dvd.java
public class Dvd extends Item {
    private final int minutes;

    public Dvd(String title, int year, int minutes) {
        super(title, year);
        this.minutes = minutes;
    }

    @Override
    public int loanDays() {
        return 7;
    }
}
```

And a program that uses them:

```java
// Lending.java
public class Lending {
    public static void main(String[] args) {
        Book book = new Book("Effective Java", 2018, "Joshua Bloch");
        Dvd dvd = new Dvd("Metropolis", 1927, 153);
        System.out.println(book.describe());
        System.out.println(book.author());
        System.out.println(dvd.describe());
    }
}
```

```
ana@vm:~/inherit$ javac *.java && java Lending
Effective Java (2018), 14 days
Joshua Bloch
Metropolis (1927), 7 days
ana@vm:~/inherit$ javap -p Book
Compiled from "Book.java"
public class Book extends Item {
  private final java.lang.String author;
  public Book(java.lang.String, int, java.lang.String);
  public java.lang.String author();
}
```

**`Book` declares no `describe()`, and `book.describe()` worked.** `Book extends Item` makes `Book`
a **subclass** of `Item`, its **superclass**, and a subclass has every field and method its
superclass has. `javap -p Book` shows what `Book.class` itself holds: one field, one constructor and
`author()`. The rest is found in `Item` when it is called.

**`Dvd` replaced one method.** It declares its own `loanDays()`, returning 7, and `describe()`,
written once in `Item`, called the DVD's version: the DVD's line says 7 days, the book's says 14.
That is called **overriding**, and `@Override` above the method asks the compiler to check that it
really does replace one; lesson 24 is about both. Lesson 25 explains how `describe()` knew which
`loanDays()` to call.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A class hierarchy. Book and Dvd each point up to Item, and Item points up to java.lang.Object, which gives every class toString, equals and hashCode. Item holds a protected title, a private year, loanDays returning 14 and describe. Book adds a private author and author(). Dvd adds a private minutes and replaces loanDays with one returning 7.\"><defs><marker id=\"jv20-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"260\" y=\"14\" width=\"200\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">java.lang.Object</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">toString, equals, hashCode</text><rect x=\"240\" y=\"104\" width=\"240\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Item</text><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">protected title</text><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">private year</text><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loanDays() 14, describe()</text><rect x=\"60\" y=\"240\" width=\"240\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"180\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">private author</text><text x=\"180\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author()</text><rect x=\"420\" y=\"240\" width=\"240\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Dvd</text><text x=\"540\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">private minutes</text><text x=\"540\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loanDays() 7</text><path d=\"M360 104 V64\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv20-a)\"></path><path d=\"M180 240 L300 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv20-a)\"></path><path d=\"M540 240 L420 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv20-a)\"></path><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every class, in the end</text><text x=\"600\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what both share</text><text x=\"30\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each adds or replaces</text></svg>", "caption": "The arrows point at the parent, the way extends reads. A Book is an Item and an Object; what Item declares, Book has without writing it again."}
```

## `super(...)` comes first

A `Book` is an `Item` with more in it, so building a book means building the item part first.
**`super(title, year)` calls the superclass's constructor**, and the item part is initialised before
the book part. Take that line out of `Book` and compile:

```
ana@vm:~/inherit$ sed -i 's/        super(title, year);//' Book.java && javac Book.java
Book.java:5: error: constructor Item in class Item cannot be applied to given types;
    public Book(String title, int year, String author) {
                                                       ^
  required: String,int
  found:    no arguments
  reason: actual and formal argument lists differ in length
1 error
```

Without an explicit call, the compiler inserts `super()` with no arguments, and `Item` has no
constructor that takes none: `required: String,int`, `found: no arguments`. A class whose superclass
has a no-argument constructor can leave the call out; `Item` asks for a title and a year, so every
subclass has to pass them on. Lesson 27 adds what Java 25 allows *before* that call. Put the line back before going on.

## `private` stays private, `protected` does not

`title` is `protected` in `Item` and `year` is `private`. `describe()` uses both, because it is
`Item`'s own method. A subclass sees only one of them. Change `Book.author()` to return the year as
well:

```
ana@vm:~/inherit$ sed -i 's/return author;/return author + ", " + year;/' Book.java && javac Book.java
Book.java:11: error: year has private access in Item
        return author + ", " + year;
                               ^
1 error
```

**`year has private access in Item`**: a `Book` *has* a year, set by the constructor it called, and
its own code may not touch it. `private` is private to the class that declares it, subclasses
included, which is lesson 14's rule seen from below. `protected` opens a member to subclasses, and
`title` is readable from `Book` for that reason. The usual advice is to keep even subclass access
narrow, and to give a subclass a method rather than a field when it needs something. Undo the change to
`author()` too.
