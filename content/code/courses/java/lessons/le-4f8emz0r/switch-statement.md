---
title: The classic `switch`, and falling through
version: 1
---

An `if` chain that compares one value against a list of constants reads badly by the fourth
`else if`. **`switch` takes the value once and jumps straight to the matching `case`.** The form in
this section is the one Java has had since 1996, and you will read it in every older codebase.
Section 04 shows the form written since Java 14, which removes this one's trap:

```java
// Shelf.java
public class Shelf {
    public static void main(String[] args) {
        String genre = "poetry";
        switch (genre) {
            case "novel":
                System.out.println("shelf A");
                break;
            case "poetry":
                System.out.println("shelf B");
            case "history":
                System.out.println("shelf C");
                break;
            default:
                System.out.println("returns desk");
        }

        int day = 6;
        switch (day) {
            case 6:
            case 7:
                System.out.println("weekend: closed");
                break;
            default:
                System.out.println("open");
        }

        String missing = null;
        switch (missing) {
            case "novel":
                System.out.println("shelf A");
                break;
            default:
                System.out.println("returns desk");
        }
    }
}
```

```
ana@vm:~/cond$ java Shelf.java
shelf B
shelf C
weekend: closed
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.hashCode()" because "<local4>" is null
	at Shelf.main(Shelf.java:29)
```

## A `case` is a label, not a box

The genre was `"poetry"`, and the program printed **two** shelves. That is the trap, and it is how
the classic `switch` was designed, not a bug in this one. A `case` is a place to jump to. Once
there, the code runs downwards, past any other `case` labels in its way, until a `break` or the end
of the `switch`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"How a classic switch runs for genre equal to poetry. Control jumps to the label case \"poetry\" and prints shelf B. There is no break, so it carries on past the label case \"history\" and prints shelf C, and stops only at the break after it, leaving the switch.\"><defs><marker id=\"jv10-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"60\" y=\"20\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">switch (genre)</text><rect x=\"80\" y=\"50\" width=\"210\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">case \"novel\":</text><rect x=\"104\" y=\"80\" width=\"186\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf A; break;</text><rect x=\"80\" y=\"110\" width=\"210\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">case \"poetry\":</text><rect x=\"104\" y=\"140\" width=\"186\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf B</text><rect x=\"80\" y=\"170\" width=\"210\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">case \"history\":</text><rect x=\"104\" y=\"200\" width=\"186\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf C; break;</text><rect x=\"80\" y=\"230\" width=\"210\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">default: returns desk</text><path d=\"M40 32 V122 H78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv10-a)\"></path><text x=\"30\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\"></text><path d=\"M312 130 V204\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv10-a)\"></path><path d=\"M300 212 H350 V262\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv10-a)\"></path><text x=\"380\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1. jumps to the matching label</text><text x=\"380\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">genre is \"poetry\"</text><text x=\"380\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2. runs down past the next label</text><text x=\"380\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no break after shelf B: case \"history\" is not a wall</text><text x=\"380\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3. stops at the first break</text><text x=\"380\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and leaves the switch</text></svg>", "caption": "A label is a place to jump to, not a boundary. Only break, or the end of the switch, stops the run."}
```

The `case "poetry"` block has no `break`, so it fell through into `case "history"` and printed
`shelf C` as well. **Every `case` that should stop needs its own `break`**, and forgetting one
compiles without a word.

Falling through is occasionally what you want, and the second `switch` uses it on purpose: `case 6:`
has no statements at all, so day 6 and day 7 share one block and one `break`. Both forms are valid,
which is exactly why a missing `break` cannot be caught by the compiler: it has no way to tell
which you meant.

## What a classic `switch` accepts

The value may be an `int` or a smaller integer type, a `char`, a `String`, or an `enum`, which
lesson 28 introduces. Each `case` must be a constant the compiler can see. And the value must not
be `null`:

```
ana@vm:~/cond$ javac -g Shelf.java && java Shelf 2>&1 | tail -2
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.hashCode()" because "<local4>" is null
	at Shelf.main(Shelf.java:29)
```

The third `switch` was given `null` and threw `NullPointerException`, at line 29. **A classic
`switch` on a `String` calls `hashCode()` on it first**, and that is what failed. The message names
`"<local4>"` even after `javac -g`, because the variable it means is not `missing` but a hidden copy
the compiler made to run the `switch`, which has no name to keep. Section 04 shows the newer form,
which can take `null` as a `case` of its own.
