---
title: An interface is a contract
version: 1
---

Lesson 21's abstract class was a parent with some of its work left undone. **An interface is a
different thing: it is a list of methods a class promises to have**, with no fields and, in its
plain form, no code. A class can extend only one class, and it can sign as many of these promises
as it likes. That is the whole of Java's answer to multiple inheritance: one line of ancestry, any
number of contracts.

## Writing one and signing it

In a new directory, `~/iface`, the library's contract for anything that can be lent:

```java
// Lendable.java
public interface Lendable {
    String title();

    int loanDays();
}
```

Two methods, no bodies, and no `public` or `abstract` written: **every method in an interface is
public and abstract unless it says otherwise**, so the words are left out. A class signs the
contract with `implements` and then has to provide both:

```java
// Book.java
public class Book implements Lendable, Comparable<Book> {
    private final String title;

    public Book(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }

    @Override
    public int loanDays() {
        return 21;
    }

    @Override
    public int compareTo(Book other) {
        return title.compareTo(other.title);
    }
}
```

```java
// Dvd.java
public class Dvd implements Lendable {
    private final String title;

    public Dvd(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }

    @Override
    public int loanDays() {
        return 7;
    }
}
```

`Book` signs two contracts, separated by a comma: `Lendable`, and the standard library's
`Comparable<Book>`, whose one method, `compareTo`, says how two books are ordered. `@Override` on
each method asks the compiler to confirm it really does fulfil something from a supertype; lesson 24
shows what it catches. `Dvd` signs only `Lendable`.

## A variable of the interface's type

```java
// Desk.java
import java.util.ArrayList;
import java.util.List;

public class Desk {
    public static void main(String[] args) {
        List<Lendable> items = List.of(new Book("Iracema"), new Dvd("Central do Brasil"));
        for (Lendable item : items) {
            System.out.println(item.title() + ": " + item.loanDays() + " days");
        }

        List<Book> books = new ArrayList<>();
        books.add(new Book("O Guarani"));
        books.add(new Book("Dom Casmurro"));
        books.add(new Book("Iracema"));
        books.sort(null);
        System.out.println(books.get(0).title() + ", then " + books.get(1).title());
    }
}
```

```
ana@vm:~/iface$ javac *.java && java Desk
Iracema: 21 days
Central do Brasil: 7 days
Dom Casmurro, then Iracema
```

**`List<Lendable>` holds a book and a DVD**, two classes with no parent in common except `Object`,
and the loop calls `title()` and `loanDays()` on each without knowing which one it has. Each object
answered with its own method: 21 days for the book, 7 for the DVD. Lesson 25 explains how the JVM
picks the method at the moment of the call.

The second half used the other contract. `books.sort(null)` means "sort by the elements' own order",
which is `compareTo`, and `Dom Casmurro` came first because `D` sorts before `I` and `O`. `List.sort`
was written long before `Book` existed. It works on it because `Book` signed `Comparable`, and that
is the use of a contract: **code written against the interface works with every class that signs it,
including the ones written later.**

## What the compiler holds a class to

A class that signs and does not deliver is refused:

```java
// Magazine.java
public class Magazine implements Lendable {
    @Override
    public String title() {
        return "Revista Piauí";
    }
}
```

```
ana@vm:~/iface$ javac Magazine.java
Magazine.java:2: error: Magazine is not abstract and does not override abstract method loanDays() in Lendable
public class Magazine implements Lendable {
       ^
1 error
```

The message names the missing method and offers the one way out besides writing it: a class that is
`abstract` may leave interface methods unwritten for its subclasses, as lesson 21's did.

And an interface cannot be built, because there is nothing in it to run:

```java
// Nope.java
public class Nope {
    public static void main(String[] args) {
        Lendable thing = new Lendable();
    }
}
```

```
ana@vm:~/iface$ javac Nope.java
Nope.java:4: error: Lendable is abstract; cannot be instantiated
        Lendable thing = new Lendable();
                         ^
1 error
```

`Lendable thing` was fine on its own. **A variable may have an interface type; an object never
does.** Every object is an instance of some class, and the variable can hold any of them that signed.
