---
title: Seven steps, in a fixed order
version: 1
---

When `new Book()` runs, it feels like one event. **It is seven, for a class with one superclass,
and their order is fixed by the language**, not by where the lines sit in the file or which class
you happen to read first. The order matters the moment one step uses what another set up, and
section 04 is what goes wrong when it does.

This program numbers every step and prints it. `Item` is the superclass and `Book` extends it, the
same pair lesson 20 built, cut down to nothing but announcements. `note` is a static helper that
prints its argument and returns it, so that a field initialiser can announce itself too:

```java
// Order.java
class Item {
    static {
        System.out.println("1  Item: static block");
    }

    {
        System.out.println("3  Item: instance block");
    }

    Item() {
        System.out.println("4  Item: constructor body");
    }
}

class Book extends Item {
    static {
        System.out.println("2  Book: static block");
    }

    private String title = note("5  Book: field initialiser");

    {
        System.out.println("6  Book: instance block");
    }

    Book() {
        System.out.println("7  Book: constructor body");
    }

    static String note(String step) {
        System.out.println(step);
        return step;
    }
}

public class Order {
    public static void main(String[] args) {
        System.out.println("main: before the first Book");
        new Book();
        System.out.println("main: before the second Book");
        new Book();
    }
}
```

Save it as `Order.java` in `~/init` and run it. All three classes are in one file, which is allowed
because only `Order` is `public`:

```
ana@vm:~/init$ javac Order.java && java Order
main: before the first Book
1  Item: static block
2  Book: static block
3  Item: instance block
4  Item: constructor body
5  Book: field initialiser
6  Book: instance block
7  Book: constructor body
main: before the second Book
3  Item: instance block
4  Item: constructor body
5  Book: field initialiser
6  Book: instance block
7  Book: constructor body
ana@vm:~/init$ ls *.class
Book.class
Item.class
Order.class
Shelf.class
```

One source file became three class files, one per class, which is why the JVM can initialise them
separately. `Shelf.class` is section 02's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The order in which Java initialises a Book that extends Item. Once, the first time Book is used: 1, Item's static initialisers and blocks; 2, Book's static initialisers and blocks. Then for every new Book: 3, Item's field initialisers and instance blocks; 4, Item's constructor body; 5, Book's field initialisers; 6, Book's instance blocks; 7, Book's constructor body. The superclass is always finished before the subclass starts.\"><defs><marker id=\"jv27-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"200\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">once, the first time Book is used</text><text x=\"360\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every new Book()</text><rect x=\"20\" y=\"40\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1  Item</text><text x=\"82\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">static block</text><rect x=\"160\" y=\"40\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"222\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2  Book</text><text x=\"222\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">static block</text><path d=\"M144 68 H158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"20\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3  Item</text><text x=\"82\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instance block</text><path d=\"M144 168 H158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"160\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"222\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4  Item</text><text x=\"222\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">constructor body</text><path d=\"M284 168 H298\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"300\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5  Book</text><text x=\"362\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">field initialiser</text><path d=\"M424 168 H438\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"440\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"502\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6  Book</text><text x=\"502\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instance block</text><path d=\"M564 168 H578\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"580\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"642\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">7  Book</text><text x=\"642\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">constructor body</text><path d=\"M222 96 V118 H82 V138\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"20\" y=\"226\" width=\"680\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the superclass first, at both levels; inside one class, source order</text></svg>", "caption": "Steps 1 and 2 happen once per class, whatever the number of objects. Steps 3 to 7 happen for every object, and the superclass's part always finishes before the subclass's begins."}
```

Three rules produce that output, and each one is visible in it.

**A class is initialised lazily, the first time it is used.** `main: before the first Book` printed
before either static block. `Order` was initialised to run `main`, and `Item` and `Book` waited
until `new Book()` needed them. A class that a program never touches never runs its static blocks
at all.

**The superclass comes first, at both levels.** Before `Book` can be initialised, `Item` must be,
so step 1 is `Item`'s. And before `Book`'s part of an object is built, `Item`'s part is finished:
steps 3 and 4 run before step 5. That second part is the `super()` call from lesson 20. Every
constructor starts by calling its superclass's, written by you or added by the compiler, and the
superclass's field initialisers, instance blocks and constructor body all run inside that call.

**Inside one class, initialisers and blocks run in the order they are written.** In `Book` the field
`title` is declared above the instance block, so step 5 comes before step 6. Swap the two in the
source and the two lines swap in the output. Only after all of them does the constructor body run,
which is step 7.

The second `Book` shows what happens once a class is ready: steps 1 and 2 are gone. **Static
initialisation happens once per class, and instance initialisation once per object**, and that is
the whole difference between the two kinds of block.

`Object`, the superclass of `Item`, is in the chain too, above step 3. Its constructor does nothing
you can see, so it prints nothing; lesson 20 showed that `Item` extends it whether you write so or
not.
