---
title: The constructor that runs too early
version: 1
---

Section 03's order has a consequence nobody expects the first time. **While the superclass's
constructor runs, the subclass's fields have not been set yet**, not even the ones with an
initialiser and not even the `final` ones. Usually that does not matter, because the superclass's
constructor knows nothing about the subclass. It starts to matter when the superclass constructor
calls a method, and the subclass overrides that method.

Here is the trap. `Item`'s constructor prints a description of the item it is building, by calling
`describe()`. `Book` overrides `describe()` to use its own fields:

```java
// Trap.java
class Item {
    Item() {
        System.out.println("Item() sees: " + describe());
    }

    String describe() {
        return "an item";
    }
}

class Book extends Item {
    private final String title;
    private int pages = 100;

    Book(String title) {
        super();
        this.title = title;
    }

    @Override
    String describe() {
        return title + ", " + pages + " pages";
    }
}

public class Trap {
    public static void main(String[] args) {
        Book book = new Book("Dom Casmurro");
        System.out.println("afterwards: " + book.describe());
    }
}
```

In a directory of its own, `~/init/trap`:

```
ana@vm:~/init/trap$ javac Trap.java && java Trap
Item() sees: null, 0 pages
afterwards: Dom Casmurro, 100 pages
```

**`null` for a `final` field, and 0 for a field initialised to 100.** Follow it through section
03's steps. `new Book("Dom Casmurro")` calls `super()` first, so `Item()` runs before anything in
`Book`. `Item()` calls `describe()`, and because the object being built *is* a `Book`, the call
reaches `Book`'s version, the overriding one (lesson 25 is about that choice). That version reads
`title` and `pages`, which still hold the defaults every field starts with: `null` for a reference
and 0 for an `int`. Only after `super()` returns do `pages = 100` and `this.title = title` run.

A program does not stop at the wrong line; it prints it, carries on and is right afterwards.
Replace the `println` with code that stores the description, or validates it, or registers the
object somewhere, and the mistake is kept. **The rule that follows: a constructor should not call a
method that a subclass can override.** Call a `private`, `static` or `final` method instead, which
no subclass can replace, or do the work after construction.

## Code before `super(...)`, from Java 25

Until Java 25, the call to `super(...)` had to be the first statement of a constructor, so a
subclass could not set a field before its superclass ran. **Java 25 allows statements before
`super(...)`**, under one condition: they may assign the object's own fields, but they may not read
them or call its methods, because the object is not built yet. That is enough to put `title` in
place before `Item()` looks at it, and to check the argument before any construction starts:

```java
// Early.java
class Item {
    Item() {
        System.out.println("Item() sees: " + describe());
    }

    String describe() {
        return "an item";
    }
}

class Book extends Item {
    private final String title;
    private int pages = 100;

    Book(String title) {
        if (title.isBlank()) {
            throw new IllegalArgumentException("a book needs a title");
        }
        this.title = title;
        super();
    }

    @Override
    String describe() {
        return title + ", " + pages + " pages";
    }
}

public class Early {
    public static void main(String[] args) {
        Book book = new Book("Dom Casmurro");
        System.out.println("afterwards: " + book.describe());
        new Book(" ");
    }
}
```

```
ana@vm:~/init/trap$ javac Early.java && java Early
Item() sees: Dom Casmurro, 0 pages
afterwards: Dom Casmurro, 100 pages
Exception in thread "main" java.lang.IllegalArgumentException: a book needs a title
	at Book.<init>(Early.java:18)
	at Early.main(Early.java:34)
```

**Half fixed, and the half that is not fixed is instructive.** `title` was assigned before
`super()`, so `Item()` saw it. `pages` still read 0, because a field initialiser is not a statement
you wrote before `super()`: it is step 5, and it runs after `super()` returns, like before. To have
`pages` in place early it would also have to be assigned in the constructor, above the call.

The blank title failed before `Item` was ever involved. `Book.<init>` in the stack trace is the
`Book` constructor, as the JVM names it, and line 18 is the `throw`. Lesson 36 reads stack traces
properly. Validating an argument before the superclass does any work used to need a static helper
method wrapped around the argument; now it is an `if` in the obvious place.

**This is new in Java 25 and does not exist on 21.** Compile the same file for 21 and the compiler
says so, by name:

```
ana@vm:~/init/trap$ javac --release 21 Early.java
Early.java:20: error: flexible constructors is not supported in -source 21
        this.title = title;
        ^
  (use -source 25 or higher to enable flexible constructors)
1 error
```

The feature is called **flexible constructor bodies**. It changes where you may put code. It does
not change section 03's order, and it does not make it safe to call an overridable method from a
constructor: anything the subclass sets in its field initialisers is still missing at that moment.
