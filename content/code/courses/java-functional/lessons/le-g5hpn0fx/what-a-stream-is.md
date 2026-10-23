---
title: What a stream is
version: 1
---

**A stream is a pipeline of operations over a sequence of values: one source, any number of
intermediate steps, and one terminal operation that produces the result.** It holds no data of its
own. A list stores books; a stream built from that list describes what to do with each book, and
does it once, when the result is asked for.

Lessons 6 to 9 work on the same shelf of twelve books, so save these two files together in
`~/fp/streams`. `Book` is a record (lesson 29 of `java`), and `Shelf` holds the list:

```java
// Book.java: one book on the shelf
public record Book(String title, String author, int year, int pages, long priceCents, String genre) {}
```

```java
// Shelf.java: the twelve books the stream lessons work on
import java.util.List;

public class Shelf {
    public static final List<Book> BOOKS = List.of(
            new Book("Dune", "Frank Herbert", 1965, 412, 6990, "sci-fi"),
            new Book("Children of Dune", "Frank Herbert", 1976, 444, 5990, "sci-fi"),
            new Book("The Left Hand of Darkness", "Ursula K. Le Guin", 1969, 304, 4990, "sci-fi"),
            new Book("The Dispossessed", "Ursula K. Le Guin", 1974, 387, 5490, "sci-fi"),
            new Book("Emma", "Jane Austen", 1815, 474, 3990, "classic"),
            new Book("Persuasion", "Jane Austen", 1817, 249, 2990, "classic"),
            new Book("Middlemarch", "George Eliot", 1871, 880, 4490, "classic"),
            new Book("Ulysses", "James Joyce", 1922, 730, 8990, "classic"),
            new Book("Dom Casmurro", "Machado de Assis", 1899, 256, 3490, "classic"),
            new Book("Grande Sertão: Veredas", "João Guimarães Rosa", 1956, 624, 7990, "classic"),
            new Book("Beowulf", "Anonymous", 1000, 96, 2490, "poetry"),
            new Book("The Hobbit", "J. R. R. Tolkien", 1937, 310, 4590, "fantasy"));
}
```

A program in the same folder can use both, because from Java 22 on the source-file mode compiles
the other `.java` files a program refers to (lesson 1 section 02).

## A loop and a stream

The question: the titles of the books under 40.00, in shelf order. As a loop, and as a stream:

```java
// LoopAndStream.java: one question answered with a loop and with a stream
import java.util.ArrayList;
import java.util.List;

public class LoopAndStream {
    public static void main(String[] args) {
        List<String> cheap = new ArrayList<>();
        for (Book b : Shelf.BOOKS) {
            if (b.priceCents() < 4000) {
                cheap.add(b.title());
            }
        }
        System.out.println("loop:   " + cheap);

        List<String> cheapToo = Shelf.BOOKS.stream()
                .filter(b -> b.priceCents() < 4000)
                .map(Book::title)
                .toList();
        System.out.println("stream: " + cheapToo);
    }
}
```

```
ana@vm:~/fp/streams$ java LoopAndStream.java
loop:   [Emma, Persuasion, Dom Casmurro, Beowulf]
stream: [Emma, Persuasion, Dom Casmurro, Beowulf]
```

The answers are the same. **The loop says how; the stream says what.** The loop builds a list,
walks the books with an index it never shows, tests, extracts and adds. The stream names three
things: where the books come from, `stream()`; what to keep, `filter`; what to turn each into,
`map`; and how to finish, `toList()`. The `select` you wrote in lesson 4 section 02 was the first
half of this, and `filter` is the library's version of it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 145\" role=\"img\" aria-label=\"A stream pipeline drawn left to right: the source Shelf.BOOKS.stream(), then two intermediate steps, filter keeping books under 4000 cents and map turning each into its title, then the terminal operation toList, which produces the result. A bracket under the first three says they run nothing yet.\"><defs><marker id=\"pipeline-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"pipeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"155\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97.5\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">source</text><text x=\"97.5\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">stream()</text><path d=\"M175 58 L195 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#pipeline-ah-paperdim)\"></path><rect x=\"195\" y=\"30\" width=\"155\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.5\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">intermediate</text><text x=\"272.5\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">filter(...)</text><path d=\"M350 58 L370 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#pipeline-ah-paperdim)\"></path><rect x=\"370\" y=\"30\" width=\"155\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.5\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">intermediate</text><text x=\"447.5\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">map(Book::title)</text><path d=\"M525 58 L545 58\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pipeline-ah-phosphor)\"></path><rect x=\"545\" y=\"30\" width=\"155\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">terminal</text><text x=\"622.5\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">toList()</text><path d=\"M25 104 L520 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><text x=\"272\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">describe the work, run nothing</text><text x=\"622\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">runs the pipeline</text></svg>", "caption": "Every operation but the last returns a new stream; the terminal one runs them all."}
```

## Three kinds of operation

| kind | returns | examples | runs |
|---|---|---|---|
| **source** | a `Stream` | `list.stream()`, `Stream.of(...)`, `IntStream.range(0, 10)` | nothing yet |
| **intermediate** | another `Stream` | `filter`, `map`, `sorted`, `distinct`, `limit` | nothing yet |
| **terminal** | a result, or nothing | `toList`, `count`, `forEach`, `findFirst`, `reduce`, `collect` | the whole pipeline |

The test is the return type. **Anything that returns a `Stream` is a step; anything that returns
something else ends the pipeline.** That is why a stream expression is written as a chain, one
operation per line: every line but the last hands a new stream to the next.
