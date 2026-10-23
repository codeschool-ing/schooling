---
title: A sealed interface names its implementers
version: 1
---

An ordinary interface is open: anybody, in any file, in any library compiled years later, may
implement it. That is what made `Comparable` useful to `Book`. Sometimes the openness is the
problem. The library lends books and DVDs, and the code that works out a loan period wants to know
it has handled every kind of item there is. **A `sealed` interface lists every class allowed to
implement it**, and the compiler enforces the list in both directions.

## Writing the list

In `~/iface/sealed`:

```java
// Item.java
public sealed interface Item permits Book, Dvd {
    String title();
}
```

`permits` names the two classes. Each of them has to say, in its own declaration, what happens below
it, and a class that forgets is refused:

```java
// Book.java
public final class Book implements Item {
    private final String title;

    public Book(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }
}
```

```java
// Dvd.java
public class Dvd implements Item {
    private final String title;

    public Dvd(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }
}
```

```
ana@vm:~/iface/sealed$ javac Item.java Book.java Dvd.java
Dvd.java:2: error: sealed, non-sealed or final modifiers expected
public class Dvd implements Item {
       ^
1 error
```

**Every permitted class picks one of three words.** `final` closes the line: nothing extends `Book`.
`sealed`, with a `permits` of its own, continues the list one level down. `non-sealed` opens it again
from that class on, deliberately and in writing. `Dvd` takes the third:

```java
// Dvd.java
public non-sealed class Dvd implements Item {
    private final String title;

    public Dvd(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }
}
```

## Anybody else is refused

```java
// Magazine.java
public final class Magazine implements Item {
    @Override
    public String title() {
        return "Revista Piauí";
    }
}
```

```
ana@vm:~/iface/sealed$ javac Item.java Book.java Dvd.java Magazine.java
Magazine.java:2: error: class is not allowed to extend sealed class: Item (as it is not listed in its 'permits' clause)
public final class Magazine implements Item {
             ^
1 error
```

The message says why in its parentheses: `Magazine` is not in the `permits` clause. To add a kind of
item, you edit `Item.java`, which is the point: the list of kinds lives in one place, and adding to
it is a change somebody reviews rather than a file appearing elsewhere.

## What the list buys

```java
// Rules.java
public class Rules {
    static int loanDays(Item item) {
        return switch (item) {
            case Book b -> 21;
            case Dvd d -> 7;
        };
    }

    public static void main(String[] args) {
        System.out.println(loanDays(new Book("Iracema")));
        System.out.println(loanDays(new Dvd("Central do Brasil")));
    }
}
```

```
ana@vm:~/iface/sealed$ javac *.java && java Rules
21
7
```

**The `switch` has no `default`, and it compiles.** Lesson 10 showed a switch expression refused when
it does not cover every value. Here the compiler read `permits`, saw that every `Item` is a `Book` or
a `Dvd`, and accepted the two cases as complete. If a third class is ever added to `permits`, this
switch stops compiling until somebody decides that class's loan period, and so does every other
switch over `Item`. With an ordinary interface and a `default` branch, the new class would silently
get whatever the `default` said.

Sealed types arrived in Java 17 and the switch over them in Java 21, so neither is new in 25. Lesson 29 puts them together with records, where they are used most.
