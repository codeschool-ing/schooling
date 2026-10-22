---
title: Chains on objects that never change
version: 1
---

`StringBuilder` and the receipt chained by changing one object and returning it. The other kind of
chain looks the same on the page and works the opposite way: **every call leaves the object alone
and returns a new one**. `String` works like that, and so does every date and time class in
`java.time`. A chain on them is a series of new objects, each built from the last.

## A due date, and a renewal that did nothing

```java
// Dates.java
import java.time.LocalDate;

public class Dates {
    public static void main(String[] args) {
        LocalDate lent = LocalDate.of(2026, 10, 9);
        LocalDate due = lent.plusWeeks(3).plusDays(1);
        System.out.println("lent " + lent + ", due " + due);

        due.plusDays(7);
        System.out.println("after renewing: " + due);

        String title = "iracema";
        title.toUpperCase();
        System.out.println(title);
    }
}
```

```
ana@vm:~/fluent$ javac Dates.java && java Dates
lent 2026-10-09, due 2026-10-31
after renewing: 2026-10-31
iracema
```

The first chain did what it says: three weeks and a day after 9 October is 31 October, and `due`
holds the result. `lent` still says the 9th, because `plusWeeks` never touched it.

**The renewal is the bug.** `due.plusDays(7)` computed 7 November, returned it, and the program threw
it away, because nothing was assigned. `due` still says 31 October. The same happened to the title, where
`toUpperCase()` built `IRACEMA` and the line discarded it, so `iracema` printed. The compiler said
nothing about either, since calling a method and ignoring its result is legal Java. **The fix is the
assignment the reader assumed was there**: `due = due.plusDays(7);`.

## Writing one

An immutable class with chainable methods returns a new instance from each of them. The library's
fine:

```java
// Fine.java
public final class Fine {
    private final long cents;
    private final String reason;

    public Fine(long cents, String reason) {
        this.cents = cents;
        this.reason = reason;
    }

    public Fine plus(long more) {
        return new Fine(cents + more, reason);
    }

    public Fine withReason(String newReason) {
        return new Fine(cents, newReason);
    }

    @Override
    public String toString() {
        return cents + " cents for " + reason;
    }
}
```

```java
// Fines.java
public class Fines {
    public static void main(String[] args) {
        Fine first = new Fine(150, "late return");
        Fine second = first.plus(50).plus(50).withReason("late return, two reminders");
        System.out.println(first);
        System.out.println(second);
    }
}
```

```
ana@vm:~/fluent$ javac Fine.java Fines.java && java Fines
150 cents for late return
250 cents for late return, two reminders
```

`first` still says 150 cents and its first reason, after a chain of three calls started from it. Each call
built a new `Fine` and the chain continued on that one; `second` is the last of them, 250 cents with
the new reason. The `with` prefix is the convention for "a copy with this one part changed", and
lesson 29's records are where Java is heading with it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two kinds of chain. Above, a mutable chain: the receipt object returns itself from line, so every call works on one object. Below, an immutable chain on Fine: first, 150 cents for late return, then plus(50) builds a new Fine of 200 cents, plus(50) another of 250, and withReason a fourth with the new reason, which is second. first is unchanged.\"><defs><marker id=\"jv26-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a mutable chain</text><rect x=\"250\" y=\"40\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the receipt</text><text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one object, changed by each call</text><path d=\"M470 60 C520 40, 520 92, 472 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv26-a)\"></path><text x=\"528\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">line(...) returns this</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">an immutable chain</text><rect x=\"20\" y=\"160\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">first</text><text x=\"80\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150, late return</text><rect x=\"210\" y=\"160\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a new Fine</text><text x=\"270\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200, late return</text><rect x=\"400\" y=\"160\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a new Fine</text><text x=\"460\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">250, late return</text><rect x=\"590\" y=\"160\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">second</text><text x=\"650\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">250, reminders</text><path d=\"M140 188 H208\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv26-a)\"></path><text x=\"174.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">plus(50)</text><path d=\"M330 188 H398\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv26-a)\"></path><text x=\"364.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">plus(50)</text><path d=\"M520 188 H588\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv26-a)\"></path><text x=\"554.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">withReason</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">four objects; nothing receives the two in the middle, and first never changes</text></svg>", "caption": "Above, every call changes one object. Below, every call makes a new one and the old one stays as it was, which is why its result has to be kept."}
```

## Which kind is in front of you

The two kinds of chain cannot be told apart by looking at the call. They differ in what the method
returns, and the documentation says it:

| class | `x.something()` | to keep the result |
|---|---|---|
| `StringBuilder`, the receipt, a builder | changes `x` and returns `x` | nothing to do; `x` changed |
| `String`, `LocalDate`, `BigDecimal`, `Fine` | returns a new object; `x` is unchanged | assign it: `x = x.something();` |

**An immutable chain is safer to share**: a `Fine` handed to another part of the program cannot be
changed behind your back, for the reason lesson 22 gave about lists. What it asks in return is that
you never call one of its methods as a statement on its own, with nothing receiving the result.
