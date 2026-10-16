---
title: Two lists that answer different questions
version: 1
---

Lesson 31 settled array against `ArrayList`. This lesson is about the interfaces `List`, `Set` and
`Map`, and the classes behind each one, and it starts with the choice everybody meets first.
**`List` is an interface, and two classes in the JDK implement it for general use**: `ArrayList` and
`LinkedList`. The common belief is that `LinkedList` is the one to use when a list changes a lot.
It is right about one operation and wrong about the rest.

Both classes keep the same promise: elements in the order you put them, reachable by position,
duplicates allowed. What differs is how they keep it, and that decides what each one does cheaply:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two lists holding the same three books. An ArrayList keeps one array of references side by side, with spare slots at the end; get(1) is one step, and adding at the front shifts every slot one place right. A LinkedList keeps one node per element, each pointing at the next and the previous; adding at the front changes two pointers, and get(1) walks from an end.\"><defs><marker id=\"jv32-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ArrayList</text><text x=\"110\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one array, slots side by side</text><rect x=\"20\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dune</text><rect x=\"100\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Emma</text><rect x=\"180\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ulysses</text><rect x=\"260\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"340\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">get(1): one step, straight to the slot</text><text x=\"20\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">add(0, x): every slot moves one place right</text><text x=\"20\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">LinkedList</text><text x=\"110\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one node per element, linked both ways</text><rect x=\"20\" y=\"168\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dune</text><rect x=\"160\" y=\"168\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Emma</text><rect x=\"300\" y=\"168\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ulysses</text><path d=\"M110 180 H158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv32-a)\"></path><path d=\"M250 180 H298\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv32-a)\"></path><path d=\"M160 192 H112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv32-a)\"></path><path d=\"M300 192 H252\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv32-a)\"></path><text x=\"20\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">add(0, x): one new node, two links changed</text><text x=\"20\" y=\"238\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">get(1): walk from an end, node by node</text></svg>", "caption": "The same three books in both lists. What is one step for the one is a walk or a shift for the other."}
```

An `ArrayList` holds one array of references, side by side, with room to spare at the end. Reading
position `i` is arithmetic and one step. Inserting at position 0 means moving every element one
slot to the right first. A `LinkedList` keeps a separate node per element, each pointing at the next
and the previous. Inserting at the front changes two links, and reading position `i` means walking
there from the nearer end.

## Measured, once

This program does both operations a hundred thousand times on each list. Save it in a new
directory, `~/colls`:

```java
// ListCost.java
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

public class ListCost {
    static final int N = 100_000;

    public static void main(String[] args) {
        for (List<Integer> list : List.of(new ArrayList<Integer>(), new LinkedList<Integer>())) {
            String name = list.getClass().getSimpleName();

            long start = System.nanoTime();
            for (int i = 0; i < N; i++) {
                list.add(0, i);                      // insert at the front
            }
            long front = System.nanoTime() - start;

            start = System.nanoTime();
            long sum = 0;
            for (int i = 0; i < N; i++) {
                sum += list.get(i);                  // read by position
            }
            long byIndex = System.nanoTime() - start;

            System.out.printf("%-10s add at front %6d ms   get(i) %6d ms   sum %d%n",
                    name, front / 1_000_000, byIndex / 1_000_000, sum);
        }
    }
}
```

```
ana@vm:~/colls$ java ListCost.java
ArrayList  add at front    372 ms   get(i)      4 ms   sum 4999950000
LinkedList add at front      5 ms   get(i)   3947 ms   sum 4999950000
```

The milliseconds change on every run and on every machine; the shape does not. **At each operation one list
beats the other by a factor of seventy or more**, which is the figure above turned into
numbers. Inserting at the front cost the `ArrayList` 372 ms, because each insertion shifted
everything already there. Reading by position cost the `LinkedList` 3947 ms, because each `get(i)`
walked up to fifty thousand nodes.

Most programs read a list far more often than they insert at its front. That is why
**`ArrayList` is the default, and `LinkedList` is a choice you make for a reason you can name.** A
reason that holds up is lesson 33's: a queue, where elements arrive at one end and leave at the
other, and nothing is ever read by position. Even there, lesson 33 hands the job to `ArrayDeque`.

Notice the variable's type in the loop: `List<Integer>`. The program never says which class it is
measuring until it creates one. Writing the interface as the type and the class only after `new` is
what makes swapping one implementation for another a one-word change.
