---
title: Nothing happens until the end
version: 1
---

**Intermediate operations are lazy: they record what to do and do nothing.** The terminal operation
starts the work, and then each element travels through every step before the next element starts.
Both facts are easiest to believe when you watch them. `peek` is an intermediate operation that
hands each element to a `Consumer` and passes it on unchanged, which makes it the stream's
`println` for debugging:

```java
// Lazy.java: watching a pipeline run, and not run
import java.util.List;

public class Lazy {
    public static void main(String[] args) {
        System.out.println("-- no terminal operation:");
        Shelf.BOOKS.stream()
                .peek(b -> System.out.println("  looked at " + b.title()))
                .filter(b -> b.pages() > 450);

        System.out.println("-- findFirst:");
        String first = Shelf.BOOKS.stream()
                .peek(b -> System.out.println("  looked at " + b.title()))
                .filter(b -> b.pages() > 450)
                .peek(b -> System.out.println("  kept " + b.title()))
                .map(Book::title)
                .findFirst()
                .orElse("none");
        System.out.println("first long book: " + first);

        System.out.println("-- two steps, element by element:");
        List<String> two = Shelf.BOOKS.stream()
                .filter(b -> b.genre().equals("classic"))
                .peek(b -> System.out.println("  classic: " + b.title()))
                .map(b -> b.title().toUpperCase())
                .peek(t -> System.out.println("  upper:   " + t))
                .limit(2)
                .toList();
        System.out.println(two);
    }
}
```

```
ana@vm:~/fp/streams$ java Lazy.java
-- no terminal operation:
-- findFirst:
  looked at Dune
  looked at Children of Dune
  looked at The Left Hand of Darkness
  looked at The Dispossessed
  looked at Emma
  kept Emma
first long book: Emma
-- two steps, element by element:
  classic: Emma
  upper:   EMMA
  classic: Persuasion
  upper:   PERSUASION
[EMMA, PERSUASION]
```

## Read the output in three parts

**The first pipeline printed nothing.** It has a source and two intermediate steps, and no terminal
operation, so it described work that nobody asked for. Java built the stream object and threw it
away. A pipeline missing its last line is a common bug, and an easy one to miss: it compiles, and it
silently does nothing.

**The second looked at five books and stopped.** `findFirst` needs one element, and the first long
book is Emma, the fifth on the shelf. The pipeline pulled the four science-fiction books, none of
them over 450 pages, then Emma, kept Emma, and the remaining seven books were never looked at. Operations that can finish early are called
**short-circuiting**: `findFirst`, `findAny`, `anyMatch`, `allMatch`, `noneMatch` and `limit`.

**The third went element by element.** A loop written by hand might filter every book first and then
convert every title. The stream did not: Emma was filtered and uppercased before Persuasion was even
looked at, and after two titles `limit(2)` stopped the whole pipeline. That order, one element
through all the steps, is why the steps cost nothing when the answer is found early, and it is the
reason lesson 9 can split the elements between processors.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" aria-label=\"A grid with three classics as columns, Emma, Persuasion and Middlemarch, and three steps as rows, filter, map and limit 2. Emma passes through all three steps first, then Persuasion passes through all three. Middlemarch is never reached, because limit stopped the pipeline after two.\"><defs><marker id=\"vertical-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"vertical-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"80\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">filter</text><text x=\"80\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">map</text><text x=\"80\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">limit(2)</text><text x=\"245\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Emma</text><rect x=\"170\" y=\"48\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">first, step 1</text><rect x=\"170\" y=\"106\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">first, step 2</text><rect x=\"170\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">first, step 3</text><path d=\"M245 92 L245 104\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#vertical-ah-phosphor)\"></path><path d=\"M245 150 L245 162\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#vertical-ah-phosphor)\"></path><text x=\"425\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Persuasion</text><rect x=\"350\" y=\"48\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">second, step 1</text><rect x=\"350\" y=\"106\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">second, step 2</text><rect x=\"350\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">second, step 3</text><path d=\"M425 92 L425 104\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#vertical-ah-paperdim)\"></path><path d=\"M425 150 L425 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#vertical-ah-paperdim)\"></path><text x=\"605\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Middlemarch</text><rect x=\"530\" y=\"48\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never reached</text><rect x=\"530\" y=\"106\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never reached</text><rect x=\"530\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never reached</text></svg>", "caption": "Each element goes through every step before the next one starts, and limit stops the pull."}
```

## What follows from laziness

- **a step that never runs cannot fail**, so an error inside a lambda shows up only when a terminal
  operation reaches the element that causes it, and the stack trace points at the terminal call
  as well as at the lambda;
- **`peek` is for looking**, not for doing. It runs only for the elements a pipeline happens to pull,
  so work done inside it may run for some elements and not others, as the second pipeline showed;
- **`sorted` cannot be lazy in the same way**: it has to see every element before it can hand over the
  first, so a `sorted` before `findFirst` pulls the whole source. Lesson 7 comes back to it.
