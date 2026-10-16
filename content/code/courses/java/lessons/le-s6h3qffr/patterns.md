---
title: Taking a record apart
version: 1
---

Records arrived together with a second feature, and the two were designed as a pair. **Because a
record is exactly its components, Java can take one apart for you**, the way you would pull the
fields out by hand with accessors, and it can do it inside a `switch` or an `instanceof`. The
feature is called a **record pattern**.

The library lends books and DVDs. Lesson 23's sealed interface says those are the only two kinds of
item, and both are records:

```java
// Patterns.java
sealed interface Item permits Book, Dvd {
}

record Book(String title, int pages) implements Item {
}

record Dvd(String title, int minutes) implements Item {
}

public class Patterns {
    static String describe(Item item) {
        return switch (item) {
            case Dvd(String title, int minutes) -> title + ": " + minutes + " minutes";
            case Book(String title, int pages) when pages > 500 -> title + ": a long book";
            case Book(String title, int pages) -> title + ": " + pages + " pages";
        };
    }

    public static void main(String[] args) {
        Item[] items = {new Book("Dom Casmurro", 256), new Book("Os Sertões", 640), new Dvd("Central do Brasil", 113)};
        for (Item item : items) {
            System.out.println(describe(item));
        }

        Object first = items[0];
        if (first instanceof Book(var title, var pages)) {
            System.out.println("taken apart: " + title + " / " + pages);
        }
    }
}
```

In `~/records/patterns`:

```
ana@vm:~/records/patterns$ javac Patterns.java && java Patterns
Dom Casmurro: 256 pages
Os Sertões: a long book
Central do Brasil: 113 minutes
taken apart: Dom Casmurro / 256
```

Each `case` is a pattern, and a pattern does two jobs at once:

- **It tests.** `case Book(String title, int pages)` matches only when `item` is a `Book`.
- **It takes apart.** When it matches, `title` and `pages` are new variables holding the record's
  components, ready to use on the right of the arrow. No cast, and no call to `title()`.

**A `when` clause adds a condition**, a guard: the first `Book` case matched only *Os Sertões*,
whose 640 pages pass `pages > 500`. The order of the cases matters for that reason. Java tries them
from the top, and the unguarded `Book` case below catches every book the guard turned away. Put the
unguarded one first and the compiler refuses the file, because the guarded case could never match.

**`instanceof` takes a pattern too.** `first instanceof Book(var title, var pages)` tested and took
apart in one step, and `var` let the compiler supply the component types it already knows.

## The `switch` with no `default`

There is no `default` branch in `describe`, and the compiler accepted it. A `switch` over a value of
type `Item` must cover every possible `Item`, and **`sealed` tells the compiler exactly which those
are**: `Book` and `Dvd`, as the `permits` clause lists them. A cover that checks out at compile time
is called exhaustive.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A sealed interface and an exhaustive switch. The sealed interface Item permits two records, Book with title and pages, and Dvd with title and minutes. The switch in describe has three cases: Dvd, Book with a guard pages greater than 500, and Book. Every permitted record reaches at least one case, so the compiler accepts the switch without a default.\"><defs><marker id=\"jv29-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sealed interface Item</text><text x=\"150\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sealed: these two and no others</text><rect x=\"20\" y=\"120\" width=\"120\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">record Book</text><text x=\"80\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">title, pages</text><rect x=\"160\" y=\"120\" width=\"120\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">record Dvd</text><text x=\"220\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">title, minutes</text><path d=\"M80 120 V98 H220 V120 M150 76 V98\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"380\" y=\"20\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the switch in describe()</text><rect x=\"398\" y=\"58\" width=\"284\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">case Dvd(String title, int minutes)</text><rect x=\"398\" y=\"108\" width=\"284\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">case Book(…) when pages &gt; 500</text><rect x=\"398\" y=\"158\" width=\"284\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">case Book(String title, int pages)</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tried first, top to bottom</text><path d=\"M80 184 V212 H350 V126 H396\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv29-a)\"></path><path d=\"M350 176 H396\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv29-a)\"></path><path d=\"M280 152 H320 V76 H396\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv29-a)\"></path><rect x=\"20\" y=\"240\" width=\"680\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every permitted type has a case: no default needed</text></svg>", "caption": "The permits clause is a complete list, so the compiler can check the switch against it. Add a third record to the list and this switch stops compiling until it has a case."}
```

Then somebody adds magazines to the library, in `permits` and as a record, and does not touch
`describe`:

```java
// Magazines.java
sealed interface Item permits Book, Dvd, Magazine {
}

record Book(String title, int pages) implements Item {
}

record Dvd(String title, int minutes) implements Item {
}

record Magazine(String title, int issue) implements Item {
}

public class Magazines {
    static String describe(Item item) {
        return switch (item) {
            case Book(String title, int pages) -> title + ": " + pages + " pages";
            case Dvd(String title, int minutes) -> title + ": " + minutes + " minutes";
        };
    }

    public static void main(String[] args) {
        System.out.println(describe(new Magazine("Piauí", 200)));
    }
}
```

```
ana@vm:~/records/magazines$ javac Magazines.java
Magazines.java:16: error: the switch expression does not cover all possible input values
        return switch (item) {
               ^
1 error
```

**The same refusal as lesson 28's enum `switch`, for the same reason**: the compiler knows every kind
of item, and one has no case. It points at the `switch` that needs one. Across a whole program, a new
record in a sealed interface fails the build once for every `switch` that forgot it, which is the
list of places a person would otherwise have had to find by searching.

## Which Java has it

Record patterns and patterns in `switch` became part of the language in Java 21, so they work on 21
and on 25. **Java 17, the LTS before, has neither**, and a team still on 17 meets this:

```
ana@vm:~/records/patterns$ javac --release 17 Patterns.java 2>&1 | head -4
Patterns.java:14: error: patterns in switch statements are not supported in -source 17
            case Dvd(String title, int minutes) -> title + ": " + minutes + " minutes";
                 ^
  (use -source 21 or higher to enable patterns in switch statements)
```

`head -4` kept the first of two errors. The second points at the same line and names the other half,
*deconstruction patterns*, which is the compiler's word for taking a record apart. Records
and sealed interfaces themselves compile on 17. What it lacks is taking them apart.
