---
title: A class inside a class, with no strings attached
version: 1
---

Every class so far has had a file of its own. Java also lets you declare a class **inside** another
one, and there are four kinds, which differ in one question: **does an object of the inner class
belong to an object of the outer one?** This section is the kind where it does not. The keyword that
says so is `static`, the same word lesson 15 used for a field that belongs to the class rather than
to any object.

A catalogue keeps entries, and an entry means nothing outside a catalogue. So `Entry` lives inside
`Catalogue`. Make a directory for this lesson, `~/nested`, and save this in it:

```java
// Catalogue.java
public class Catalogue {
    static class Entry {
        final String isbn;
        final String title;

        Entry(String isbn, String title) {
            this.isbn = isbn;
            this.title = title;
        }
    }

    private final Entry[] entries = new Entry[10];
    private int size;

    void add(String isbn, String title) {
        entries[size++] = new Entry(isbn, title);
    }

    public static void main(String[] args) {
        Catalogue c = new Catalogue();
        c.add("978-0134685991", "Effective Java");
        c.add("978-0596009205", "Head First Java");
        Catalogue.Entry loose = new Catalogue.Entry("978-1617293566", "Modern Java in Action");
        System.out.println(c.size + " entries; one more built on its own: " + loose.title);
        System.out.println(c.entries[0].title + ", " + c.entries[1].title);
    }
}
```

The nested class is declared like any other, with `static` in front. Code inside `Catalogue` calls
it `Entry`; code anywhere else calls it **`Catalogue.Entry`**, the outer name, a dot, the inner
name. `main` uses both spellings:

```
ana@vm:~/nested$ javac Catalogue.java && java Catalogue
2 entries; one more built on its own: Modern Java in Action
Effective Java, Head First Java
ana@vm:~/nested$ ls
Catalogue$Entry.class
Catalogue.class
Catalogue.java
```

Two things in that transcript are the whole idea.

**`new Catalogue.Entry(...)` needed no catalogue.** The third entry was built in `main` with no
`Catalogue` object anywhere near it. A static nested class is an ordinary class that happens to be
declared inside another; nesting changes its name and what it may see, and nothing about how it is
created.

**One source file gave two class files.** The JVM has no idea of nesting. The compiler writes the
nested class as a class of its own, named `Catalogue$Entry`, outer name and inner name joined by a
dollar sign. That is the name you will see in a stack trace and in `javap`, and the reason a `$`
in a class name never means you typed one.

## What it may see, and what it may not

Nesting buys access. `Entry` sits inside `Catalogue`'s braces, so it may use anything `Catalogue`
declares, including what is `private`, and `Catalogue` may use `Entry`'s private members in return.
Lesson 14 drew the line around a class; a nested class is inside that line.

What it may not use is an **instance** field of the outer class, because a static nested object
has no outer object to read it from. `Shelf` tries:

```java
// Shelf.java
public class Shelf {
    private int capacity = 40;

    static class Label {
        String text() {
            return "Shelf of " + capacity;
        }
    }
}
```

```
ana@vm:~/nested$ javac Shelf.java
Shelf.java:7: error: non-static variable capacity cannot be referenced from a static context
            return "Shelf of " + capacity;
                                 ^
1 error
```

**Which shelf's capacity?** A `Label` may exist with no `Shelf` at all, so `capacity` has no object
to come from, and the compiler says so in lesson 15's words: a static context cannot reach an
instance member. The two ways out are the subject of the rest of the lesson. Give the label a shelf
to ask, as a constructor parameter, or drop `static` and make it an inner class, which section 03
does.

## When to nest

**Nest a class when it is part of another one's implementation and nothing else would use it.** The
JDK does it all the time. `Map.Entry`, the pair a map hands out in lesson 32, is a static nested
interface of `Map`. Builders, which lesson 26 writes, are static nested classes of the class they
build. The rule of thumb is the static one first: **a nested class should be `static` unless it needs an outer object**. An inner class carries a hidden reference, which section 03 makes
visible, and that reference costs memory and can keep the outer object alive.
