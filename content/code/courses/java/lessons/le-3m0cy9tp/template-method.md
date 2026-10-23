---
title: The template method, a superclass with blanks to fill
version: 1
---

An abstract class is at its most useful when it owns an **algorithm** and leaves a few of its steps
blank. The steps that are the same for everything are written once and kept out of reach; the steps
that differ are abstract methods each subclass fills in. That arrangement has a name, the
**template method**, and you will meet it in nearly every framework you use in `java-back`.

The library charges for late returns. The rule is the same for everything: nothing if the item is
not late, otherwise a daily fee times the days late, never more than a maximum. **What differs is the
two numbers**, so those are the blanks. Money here is whole cents in an `int`, so that nothing is
lost to a fraction. In a new directory, `~/abstract/fees`:

```java
// Loanable.java
public abstract class Loanable {
    private final String title;

    protected Loanable(String title) {
        this.title = title;
    }

    public final int lateFeeCents(int daysLate) {
        if (daysLate <= 0) {
            return 0;
        }
        int fee = daysLate * dailyFeeCents();
        return Math.min(fee, maximumFeeCents());
    }

    protected abstract int dailyFeeCents();

    protected int maximumFeeCents() {
        return 2000;
    }

    public String title() {
        return title;
    }
}
```

Three kinds of method in one class, and each says how a subclass may treat it:

| method | declared | a subclass |
|---|---|---|
| `lateFeeCents` | `public final`, with a body | may call it, may not replace it |
| `dailyFeeCents` | `protected abstract`, no body | must write it |
| `maximumFeeCents` | `protected`, with a body | may replace it, and inherits 2000 if it does not |

A method like `maximumFeeCents`, with a sensible default a subclass can override, is called a
**hook**. Both blanks are `protected`, because they are for subclasses to fill and not for other
classes to call. Now two subclasses, each a few lines, and a program that asks both for fees:

```java
// Book.java
public class Book extends Loanable {
    public Book(String title) {
        super(title);
    }

    @Override
    protected int dailyFeeCents() {
        return 50;
    }
}
```
```java
// Dvd.java
public class Dvd extends Loanable {
    public Dvd(String title) {
        super(title);
    }

    @Override
    protected int dailyFeeCents() {
        return 150;
    }

    @Override
    protected int maximumFeeCents() {
        return 3000;
    }
}
```
```java
// Fees.java
public class Fees {
    public static void main(String[] args) {
        Loanable[] items = {new Book("Effective Java"), new Dvd("Metropolis")};
        int[] lateness = {0, 3, 30};
        for (Loanable item : items) {
            for (int days : lateness) {
                int cents = item.lateFeeCents(days);
                System.out.println(item.title() + ", " + days + " days late: "
                        + cents / 100 + "." + String.format("%02d", cents % 100));
            }
        }
    }
}
```

```
ana@vm:~/abstract/fees$ javac Loanable.java Book.java Dvd.java Fees.java && java Fees
Effective Java, 0 days late: 0.00
Effective Java, 3 days late: 1.50
Effective Java, 30 days late: 15.00
Metropolis, 0 days late: 0.00
Metropolis, 3 days late: 4.50
Metropolis, 30 days late: 30.00
```

**Neither subclass contains a single `if`, a multiplication or a `Math.min`**, and both charge
correctly. The book's thirty days came to 15.00, under its 20.00 maximum. The DVD's thirty days at
1.50 would be 45.00, and its own maximum of 30.00 capped it. The cents are printed as whole units
and cents with integer arithmetic, `cents / 100` and `cents % 100`, so the fee is never a `double`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The abstract class Loanable holds a final method, lateFeeCents, with the steps written once: days late times the daily fee, capped by the maximum. It calls dailyFeeCents, abstract with no body, which every subclass writes, and maximumFeeCents, a hook returning 2000 by default. Book fills in dailyFeeCents with 50 and inherits the maximum of 2000. Dvd fills in dailyFeeCents with 150 and replaces the maximum with 3000.\"><defs><marker id=\"jv21-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"330\" height=\"258\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"181\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loanable, abstract</text><rect x=\"36\" y=\"54\" width=\"290\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"181\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">final lateFeeCents(daysLate)</text><text x=\"181\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the steps, written once:</text><text x=\"181\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">days × daily, capped by maximum</text><rect x=\"36\" y=\"142\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"181\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">abstract dailyFeeCents()</text><text x=\"181\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no body: every subclass writes it</text><rect x=\"36\" y=\"206\" width=\"290\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"181\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">maximumFeeCents()  2000</text><text x=\"181\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a hook: a default a subclass may replace</text><path d=\"M60 116 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv21-a)\"></path><path d=\"M50 116 C20 160 20 200 34 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv21-a)\"></path><rect x=\"400\" y=\"60\" width=\"300\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"550\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dailyFeeCents()  50</text><text x=\"550\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">maximum: inherited, 2000</text><rect x=\"400\" y=\"170\" width=\"300\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Dvd</text><text x=\"550\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dailyFeeCents()  150</text><text x=\"550\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">maximumFeeCents()  3000</text><path d=\"M398 110 L330 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M398 206 L330 170\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M398 232 H330\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "The superclass owns the order of the steps and cannot be overridden there. Subclasses fill in the one blank they must and the one they may, and nothing else."}
```

## `final` keeps the order of the steps

`lateFeeCents` is `final`, so no subclass can replace the algorithm itself. An e-book that decided to
charge in its own way finds out at once:

```java
// Ebook.java
public class Ebook extends Loanable {
    public Ebook(String title) {
        super(title);
    }

    @Override
    protected int dailyFeeCents() {
        return 0;
    }

    @Override
    public int lateFeeCents(int daysLate) {
        return -1;
    }
}
```

```
ana@vm:~/abstract/fees$ javac Ebook.java
Ebook.java:13: error: lateFeeCents(int) in Ebook cannot override lateFeeCents(int) in Loanable
    public int lateFeeCents(int daysLate) {
               ^
  overridden method is final
1 error
```

**`overridden method is final`.** Without the `final`, `Ebook` would compile and return -1 for every
late return, and the rule "a fee is never negative" would hold for every class except the one that
broke it, with nothing in `Loanable` able to stop it. `final` on a method is lesson 16's subject; here
it is what turns "the steps happen in this order" from a habit into a guarantee. Delete `Ebook.java`
before going on, or every later `javac *.java` in this directory fails on it.
