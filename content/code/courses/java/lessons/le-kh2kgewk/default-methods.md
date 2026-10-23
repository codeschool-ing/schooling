---
title: Default methods, and growing a contract
version: 1
---

A contract with a hundred signatures has a problem the day it needs one more clause. Add an abstract
method to `Lendable` and every class that implements it stops compiling, including classes in other
people's code that you will never see. **Until Java 8 the honest answer was "you cannot"**, and the
standard library carried interfaces it was not allowed to improve. A **default method** is the way
out: a method in the interface that comes with a body, which every implementer inherits unless it
writes its own.

## A new clause, with a body

In `~/iface/defaults`, with `Book.java` and `Dvd.java` copied unchanged from section 02, here is
`Lendable` grown by three methods:

```schooling-example
{
  "language": "java",
  "file": "Lendable.java",
  "parts": [
    {
      "code": "public interface Lendable {\n    String title();\n\n    int loanDays();",
      "note": "The two abstract methods from section 02, unchanged. Every class that already signed `Lendable` still compiles against this file."
    },
    {
      "code": "\n    default boolean renewable() {\n        return true;\n    }",
      "note": "**A default method has a body**, and a class that signs the interface gets it for free. Books and DVDs are renewable without a line of their own; a class that disagrees writes its own `renewable`."
    },
    {
      "code": "\n    static String describe(Lendable item) {\n        return item.title() + \": \" + days(item.loanDays())\n                + (item.renewable() ? \", renewable\" : \", not renewable\");\n    }",
      "note": "**A static method belongs to the interface itself** and is called on its name, `Lendable.describe(item)`. It is not inherited: `Book.describe` does not exist."
    },
    {
      "code": "\n    private static String days(int n) {\n        return n == 1 ? \"1 day\" : n + \" days\";\n    }\n}",
      "note": "A private method is a helper for the interface's own code, here the plural of *day*. It is invisible to implementers and to callers, and `javap` does not list it."
    }
  ]
}
```

A game, which the library lends for one day and never renews, overrides the default:

```java
// Game.java
public class Game implements Lendable {
    private final String title;

    public Game(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }

    @Override
    public int loanDays() {
        return 1;
    }

    @Override
    public boolean renewable() {
        return false;
    }
}
```

```java
// Shelf.java
public class Shelf {
    public static void main(String[] args) {
        Lendable[] items = { new Book("Iracema"), new Dvd("Central do Brasil"), new Game("Banco Imobiliário") };
        for (Lendable item : items) {
            System.out.println(Lendable.describe(item));
        }
    }
}
```

```
ana@vm:~/iface/defaults$ javac *.java && java Shelf
Iracema: 21 days, renewable
Central do Brasil: 7 days, renewable
Banco Imobiliário: 1 day, not renewable
ana@vm:~/iface/defaults$ javap Lendable
Compiled from "Lendable.java"
public interface Lendable {
  public abstract java.lang.String title();
  public abstract int loanDays();
  public default boolean renewable();
  public static java.lang.String describe(Lendable);
}
```

**`Book.java` and `Dvd.java` compiled without a change** and answered `renewable` from the default;
`Game` said no with its own method. `describe` built each line from the two abstract methods and the
default, and its private helper picked `1 day` over `1 days`. `javap` lists what the interface shows
the world: the abstract pair, the `default` method and the `static` one. The private helper is not
there, because `javap` lists only what other code may call.

## What a default is for, and what it is not

A default method is written for **evolution**: adding behaviour to a contract that already has
implementers, with a body that is correct for most of them. That is how `List` gained `sort` in
Java 8 without breaking every list class anyone had written, and how `Comparator` gained
`reversed()` and `thenComparing`.

It is not a way to give an interface state. An interface can declare constants and nothing else
that holds a value, so a default method can only call other methods, never keep a field of its own.
**If two default methods need to share a counter, the design wants an abstract class**, which lesson
21 showed. The choice between the two comes down to that: an interface when the classes share a
promise, an abstract class when they share data and the code around it.
