---
title: Changing a collection while you walk it
version: 1
---

The library wants the overdue loans out of the list, and the first loop anybody writes walks the list
and removes what matches. **It looks correct, it compiles, and it fails**:

```java
// Overdue.java
import java.util.ArrayList;
import java.util.List;

public class Overdue {
    public static void main(String[] args) {
        List<String> loans = new ArrayList<>(List.of("Dune", "Emma:late", "Ulysses", "Beloved"));
        for (String loan : loans) {
            if (loan.endsWith(":late")) {
                loans.remove(loan);
            }
        }
        System.out.println(loans);
    }
}
```

```
ana@vm:~/iter$ java Overdue.java
Exception in thread "main" java.util.ConcurrentModificationException
	at java.base/java.util.ArrayList$Itr.checkForComodification(ArrayList.java:1096)
	at java.base/java.util.ArrayList$Itr.next(ArrayList.java:1050)
	at Overdue.main(Overdue.java:8)
```

The exception was thrown by `ArrayList$Itr.next`, the iterator section 02 met, from a method named
`checkForComodification`. **The list was changed while an iterator was walking it**, by something
other than that iterator. `loans.remove(loan)` removed `Emma:late` behind the iterator's back, and
the next call to `next()` noticed.

It noticed because an `ArrayList` counts its structural changes, the ones that add or remove
elements, in a field called `modCount`. An iterator copies that number when it is made and compares
it on every `next()`. A difference means the list it is walking is no longer the list it started
with, and **the iterator refuses to guess**: it throws `ConcurrentModificationException` at the
first call after the change. The name says "concurrent", but no second thread is involved. One
thread, one loop, two ways of changing the list at once.

## The same mistake, without the exception

Move the late loans to the end of the list and the program behaves differently:

```java
// Quiet.java
import java.util.ArrayList;
import java.util.List;

public class Quiet {
    public static void main(String[] args) {
        List<String> loans = new ArrayList<>(List.of("Dune", "Emma", "Ulysses:late", "Beloved:late"));
        for (String loan : loans) {
            System.out.println("checking " + loan);
            if (loan.endsWith(":late")) {
                loans.remove(loan);
            }
        }
        System.out.println(loans);
    }
}
```

```
ana@vm:~/iter$ java Quiet.java
checking Dune
checking Emma
checking Ulysses:late
[Dune, Emma, Beloved:late]
```

No exception, a printed list, and a wrong answer. **`Beloved:late` was never checked**: the loop
printed `checking` three times for four loans and stopped. The figure shows why:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Why Quiet.java never checked Beloved. Before the remove, the list holds Dune, Emma, Ulysses:late and Beloved:late at indexes 0 to 3, size 4, and the iterator&#x27;s cursor is at 3, just after Ulysses:late, which it has returned. The loop removes Ulysses:late: Beloved:late moves down to index 2 and the size becomes 3. The loop then asks hasNext, which compares the cursor, 3, with the size, 3, finds them equal and answers false. The loop ends, and Beloved:late was never returned or checked.\"><defs><marker id=\"jv34-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · next() returned Ulysses:late</text><rect x=\"200\" y=\"44\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"253\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dune</text><text x=\"253\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"310\" y=\"44\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Emma</text><text x=\"363\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"420\" y=\"44\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"473\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ulysses:late</text><text x=\"473\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"530\" y=\"44\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"583\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Beloved:late</text><text x=\"583\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M530 116 V80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv34-a)\"></path><text x=\"538\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cursor = 3</text><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">size = 4</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · after loans.remove(Ulysses:late)</text><rect x=\"200\" y=\"154\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"253\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dune</text><text x=\"253\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"310\" y=\"154\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Emma</text><text x=\"363\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"420\" y=\"154\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"473\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Beloved:late</text><text x=\"473\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"530\" y=\"154\" width=\"106\" height=\"32\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"583\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M530 226 V190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv34-a)\"></path><text x=\"538\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cursor = 3</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">size = 3</text><text x=\"20\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">hasNext() asks cursor != size: 3 != 3 is false, so the loop ends and Beloved:late is never checked</text></svg>", "caption": "The iterator remembers a position, not an element. Removing behind it moved the last element under the position it had already passed."}
```

`hasNext()` on an `ArrayList` iterator compares its cursor with the list's size, and does not check
`modCount`; only `next()` does. Removing `Ulysses:late` made the size 3 while the cursor stood at 3,
so `hasNext()` said there was nothing left and `next()` was never called again. **That is why the
documentation calls the check fail-fast on a "best-effort basis"**: it catches the change when it
can, and a program cannot rely on the exception to find its bug.

So the rule is not "avoid the exception". It is **never change a collection's structure while a
`for-each` walks it**, whether or not anything is thrown. Replacing an element with `set(i, x)` is
not a structural change, and `modCount` does not move for it. Adding or removing is, and section 04
has four ways to do it safely.
