---
title: The variable's type and the object's class
version: 1
---

A variable in Java has a type that is written in the source and never changes: `Item item` is an
`Item` variable for as long as it exists. The object it refers to has a class, fixed when `new` ran,
and it may be any subclass of `Item`. **Those are two different types, and each one decides a
different thing.** Most confusion about polymorphism comes from treating them as one.

| | where it comes from | known when | it decides |
|---|---|---|---|
| **declared type** | the variable's declaration, `Item item` | at compile time | which methods may be called |
| **actual class** | the `new` that built the object | at run time | which body of an overridden method runs |

## Three objects behind one type

In `~/binding`, a parent and two subclasses that override its one method:

```java
// Item.java
public class Item {
    public String describe() {
        return "an item";
    }
}
```

```java
// Book.java
public class Book extends Item {
    private final String isbn;

    public Book(String isbn) {
        this.isbn = isbn;
    }

    @Override
    public String describe() {
        return "a book";
    }

    public String isbn() {
        return isbn;
    }
}
```

```java
// Dvd.java
public class Dvd extends Item {
    @Override
    public String describe() {
        return "a DVD";
    }
}
```

```java
// Desk.java
public class Desk {
    public static void main(String[] args) {
        Item[] items = { new Book("978-85-359-0277-2"), new Dvd(), new Item() };
        for (Item item : items) {
            System.out.println(item.describe());
        }
    }
}
```

```
ana@vm:~/binding$ javac *.java && java Desk
a book
a DVD
an item
```

Three elements, all declared `Item`, and three different answers. **The loop called `describe()`
on an `Item` each time, and each object ran its own override**: the book's, the DVD's, and for the
plain `Item`, the original. Nothing in `Desk` mentions `Book` or `Dvd` after the array is built.

## The declared type limits what you may ask

`Book` has a method `Item` lacks. Through an `Item` variable it is out of reach, even when the
object is a book:

```java
// Visible.java
public class Visible {
    public static void main(String[] args) {
        Item item = new Book("978-85-359-0277-2");
        System.out.println(item.isbn());
    }
}
```

```
ana@vm:~/binding$ javac Visible.java
Visible.java:5: error: cannot find symbol
        System.out.println(item.isbn());
                               ^
  symbol:   method isbn()
  location: variable item of type Item
1 error
```

The message says exactly what the compiler looked at: `variable item of type Item`. **The compiler
never sees objects, only declarations**, and `Item` declares no `isbn()`. That the object built on
the line above is a `Book` is a fact about run time, and the compiler does not reason about it.

## A cast is a promise the JVM checks

```java
// Casts.java
public class Casts {
    public static void main(String[] args) {
        Item[] items = { new Book("978-85-359-0277-2"), new Dvd() };
        for (Item item : items) {
            if (item instanceof Book book) {
                System.out.println("checked: " + book.isbn());
            }
        }
        Book forced = (Book) items[1];
        System.out.println(forced.isbn());
    }
}
```

```
ana@vm:~/binding$ javac Casts.java && java Casts
checked: 978-85-359-0277-2
Exception in thread "main" java.lang.ClassCastException: class Dvd cannot be cast to class Book (Dvd and Book are in unnamed module of loader 'app')
	at Casts.main(Casts.java:10)
```

The `instanceof` pattern asked first, so the book printed its ISBN and the DVD was skipped. **The
plain cast `(Book) items[1]` did not ask**: it told the compiler "trust me, this is a `Book`", and the
compiler accepted it, because an `Item` could be one. The JVM did not trust it. It checked the actual
class at the moment of the cast, found a `Dvd`, and threw `ClassCastException` on line 10, naming
both classes. So a cast moves the check from compile time to run time; it never skips it. Prefer the
`instanceof` form, which turns a crash into a branch.
