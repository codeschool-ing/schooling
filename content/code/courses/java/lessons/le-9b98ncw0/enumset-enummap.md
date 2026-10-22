---
title: EnumSet, EnumMap, and the number never to store
version: 1
---

Collections are lessons 31 to 33, and a `Set` or a `Map` of genres works with any of them. **The
standard library also carries two built for enums alone, `EnumSet` and `EnumMap`**, which use the
fact that an enum has a fixed number of constants, each with a position. They are smaller and faster
than the general ones and keep the enum's own order, so where the keys are an enum they are the
default choice.

```java
// Shelving.java
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

public class Shelving {
    enum Genre {
        FICTION, HISTORY, SCIENCE, POETRY
    }

    public static void main(String[] args) {
        Set<Genre> groundFloor = EnumSet.of(Genre.POETRY, Genre.FICTION);
        System.out.println(groundFloor);
        System.out.println(EnumSet.complementOf(EnumSet.copyOf(groundFloor)));
        System.out.println(EnumSet.range(Genre.HISTORY, Genre.POETRY));

        Genre[] returned = {Genre.SCIENCE, Genre.FICTION, Genre.SCIENCE, Genre.POETRY};
        Map<Genre, Integer> counts = new EnumMap<>(Genre.class);
        for (Genre g : returned) {
            counts.put(g, counts.getOrDefault(g, 0) + 1);
        }
        System.out.println(counts);
    }
}
```

```
ana@vm:~/enums/sets$ javac Shelving.java && java Shelving
[FICTION, POETRY]
[HISTORY, SCIENCE]
[HISTORY, SCIENCE, POETRY]
{FICTION=1, SCIENCE=2, POETRY=1}
```

Four lines, and each shows something an ordinary set or map would not:

- **`EnumSet.of(POETRY, FICTION)` printed `[FICTION, POETRY]`**, in the order the enum declares,
  not the order they were added. Inside, an `EnumSet` of up to 64 constants is one `long` with a bit
  per constant, and walking the bits goes in ordinal order.
- `complementOf` is every constant **not** in a set, which only makes sense when the set knows every
  constant there is. `range(HISTORY, POETRY)` is the constants from one to another, inclusive.
- **The `EnumMap` printed its keys in the enum's order too**, though `SCIENCE` was counted first. It
  is an array indexed by ordinal underneath, and `new EnumMap<>(Genre.class)` passes the class so
  that it knows how long the array must be.

Both are ordinary `Set` and `Map` objects to the rest of the program, so a method that takes a
`Set<Genre>` accepts an `EnumSet` without knowing.

## The ordinal is a position, never an identity

`EnumSet` and `EnumMap` use ordinals internally, inside one running program, where they cannot
change. **Your own code should never store one**: in a file, in a database column, in a message to
another program. The ordinal is where a constant happens to sit in the list, and the list is source
code that somebody will edit.

`Ordinals` shows what happens. It holds the same enum twice, as it was before somebody added
`BIOGRAPHY` at the top and as it is after, because a real demonstration would need a database and two
builds of the program. It saves `SCIENCE` both ways, and reads both back through the new version:

```java
// Ordinals.java
public class Ordinals {
    enum GenreBefore {
        FICTION, HISTORY, SCIENCE, POETRY
    }

    enum GenreAfter {
        BIOGRAPHY, FICTION, HISTORY, SCIENCE, POETRY
    }

    public static void main(String[] args) {
        GenreBefore stored = GenreBefore.SCIENCE;
        int savedOrdinal = stored.ordinal();
        String savedName = stored.name();
        System.out.println("saved: " + savedOrdinal + " and " + savedName);

        System.out.println("by ordinal: " + GenreAfter.values()[savedOrdinal]);
        System.out.println("by name:    " + GenreAfter.valueOf(savedName));
    }
}
```

```
ana@vm:~/enums/sets$ javac Ordinals.java && java Ordinals
saved: 2 and SCIENCE
by ordinal: HISTORY
by name:    SCIENCE
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Why a stored ordinal goes wrong. Before the edit, the enum lists FICTION, HISTORY, SCIENCE and POETRY at positions 0 to 3, and SCIENCE is saved as 2. After BIOGRAPHY is added at the top, every constant moves one place along, position 2 is HISTORY, and the saved 2 reads back as HISTORY. The saved name SCIENCE still finds SCIENCE, now at position 3.\"><defs><marker id=\"jv28-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"jv28-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">before the edit</text><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">after the edit</text><rect x=\"256\" y=\"40\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"308.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"308.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FICTION</text><rect x=\"372\" y=\"40\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"424.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HISTORY</text><rect x=\"488\" y=\"40\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"540.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SCIENCE</text><rect x=\"604\" y=\"40\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"656.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POETRY</text><rect x=\"140\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"192.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"192.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BIOGRAPHY</text><rect x=\"256\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"308.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"308.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FICTION</text><rect x=\"372\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"424.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HISTORY</text><rect x=\"488\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"540.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SCIENCE</text><rect x=\"604\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"656.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POETRY</text><rect x=\"372\" y=\"204\" width=\"104\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">saved: 2</text><rect x=\"488\" y=\"204\" width=\"104\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">saved: SCIENCE</text><path d=\"M424.0 204 V168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv28-a)\"></path><path d=\"M540.0 204 V168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv28-b)\"></path></svg>", "caption": "The number 2 was a position, and every position moved when a constant was added above. The name was the constant's identity, and it did not move."}
```

**The saved 2 came back as `HISTORY`.** No exception, no warning, and a perfectly valid genre: every
science book in the database is now filed under history, and nothing anywhere fails. Adding a
constant anywhere but the end shifts every constant after it, and so does deleting one or sorting
the list alphabetically, which is the kind of tidying somebody does in a quiet afternoon.

**The name survived**, because a name is what the constant is called and not where it sits. Store
`name()` and read it back with `valueOf`, and the edit is harmless. Renaming a constant still breaks
what was stored under the old name. For data that outlives the program, the strongest choice is a
code of your own, written down in a field: `SCIENCE("sci")`, with a method that finds a constant by
its code.
