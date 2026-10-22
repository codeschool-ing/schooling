---
title: Where inheritance stops paying
version: 1
---

Inheritance is the feature beginners reach for first, because it saves typing at once. Its costs
arrive later and from a distance. **A subclass depends on how its superclass is written, not only on
what it promises**, and that is a stronger tie than any other in the language. Three limits, one of
them in the syntax and two in the design.

## One parent

A class extends exactly one class. An audio book is a book and, in a way, a recording, and Java will
not let a class say so. Make `Book` extend both:

```
ana@vm:~/inherit$ sed -i 's/public class Book extends Item {/public class Book extends Item, Dvd {/' Book.java && javac Book.java
Book.java:2: error: '{' expected
public class Book extends Item, Dvd {
                              ^
1 error
```

The compiler does not even get as far as an explanation: after `extends Item` it expected the class
body, `{`, and found a comma. **Single inheritance of classes is a rule of the grammar**, chosen so
that a method can never be inherited from two places with two bodies. A class can implement any
number of **interfaces**, which promise behaviour without most of that risk, and lesson 23 is about
them. Put `Book.java` back as section 02 has it
before going on.

## The is-a test

`extends` says that every object of the subclass **is an** object of the superclass, and can be used
wherever one is expected. A `Book` is an `Item`, and a `Dvd` is an `Item`: anywhere the program
lends an item, either will do. Before writing `extends`, say the sentence. "A `Loan` is a `Book`" is
false: a loan **has** a book, and that relation is a field, not a superclass. Inheriting to get
some code you want, from a class you are not a kind of, is the most common misuse of the feature.

## The superclass's code is part of yours

A shelf should count how many ISBNs were ever put on it. `HashSet` already holds a set of strings,
so the obvious move is to extend it and count in the two methods that add:

```java
// CountingSet.java
import java.util.Collection;
import java.util.HashSet;
import java.util.List;

public class CountingSet extends HashSet<String> {
    private int added;

    @Override
    public boolean add(String isbn) {
        added++;
        return super.add(isbn);
    }

    @Override
    public boolean addAll(Collection<? extends String> isbns) {
        added += isbns.size();
        return super.addAll(isbns);
    }

    public static void main(String[] args) {
        CountingSet shelf = new CountingSet();
        shelf.addAll(List.of("978-0134685991", "978-0596009205", "978-1617293566"));
        System.out.println(shelf.added + " added, " + shelf.size() + " on the shelf");
    }
}
```

(`Collection<? extends String>` is the exact parameter type of `HashSet.addAll`, which an override
has to repeat; lesson 35 explains the `?`.) Three ISBNs go in, in one call:

```
ana@vm:~/inherit$ java CountingSet.java
6 added, 3 on the shelf
```

**Six added, for three ISBNs.** Nothing in `CountingSet` is wrong on its own. `addAll` added three,
and then `super.addAll` did its work by calling `add` once per element, and `add` is overridden, so
each one was counted again. Whether `HashSet.addAll` calls `add` is not in its contract; it is a
detail of how it happens to be written, and **a subclass that overrides methods depends on those
details**. A future version could change them, and the count would change with it, with no edit to
this class.

The way out is to stop being a set and start **having** one. `CountingShelf` keeps a `HashSet` in a
private field and offers only the methods it means to:

```java
// CountingShelf.java
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class CountingShelf {
    private final Set<String> isbns = new HashSet<>();
    private int added;

    public void add(String isbn) {
        added++;
        isbns.add(isbn);
    }

    public void addAll(List<String> more) {
        for (String isbn : more) {
            add(isbn);
        }
    }

    public int size() {
        return isbns.size();
    }

    public static void main(String[] args) {
        CountingShelf shelf = new CountingShelf();
        shelf.addAll(List.of("978-0134685991", "978-0596009205", "978-1617293566"));
        System.out.println(shelf.added + " added, " + shelf.size() + " on the shelf");
    }
}
```

```
ana@vm:~/inherit$ java CountingShelf.java
3 added, 3 on the shelf
```

That is **composition**: the shelf uses a set the way it uses a string, through its public methods,
and nothing `HashSet` does inside can reach the count. It costs a few lines a subclass would have
inherited, `size()` here, and buys a class whose behaviour is all in its own file.

**Prefer composition, and extend when the is-a sentence is true and the superclass was designed to be
extended.** `Item` was: it is ours, small, and every method in it is meant to be shared or replaced.
`HashSet` was not designed for it, and promises nothing about how its methods call each other.
Lesson 21 is the other half of this: a superclass written to be extended, with
the places a subclass fills in marked as such.
