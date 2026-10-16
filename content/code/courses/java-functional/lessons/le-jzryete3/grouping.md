---
title: Grouping
version: 1
---

**`Collectors.groupingBy(classifier)` sorts the elements into groups and returns a map from each
group's key to a list of the elements in it.** The classifier is a `Function` that answers one
question per element: which group is this one in? It is the stream's `GROUP BY`, and it works on the
shelf from lesson 6 in `~/fp/streams`:

```java
// Grouping.java: books grouped by genre, by decade, and in a sorted map
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Collectors;

public class Grouping {
    public static void main(String[] args) {
        Map<String, List<Book>> byGenre = Shelf.BOOKS.stream()
                .collect(Collectors.groupingBy(Book::genre));
        System.out.println(byGenre.keySet());
        System.out.println("fantasy: " + byGenre.get("fantasy"));
        System.out.println("crime:   " + byGenre.get("crime"));

        Map<String, List<Book>> sorted = Shelf.BOOKS.stream()
                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.toList()));
        sorted.forEach((genre, books) -> System.out.println(genre + " " + books.size()));

        Map<Integer, List<String>> byCentury = Shelf.BOOKS.stream()
                .collect(Collectors.groupingBy(b -> b.year() / 100 + 1, TreeMap::new,
                        Collectors.mapping(Book::title, Collectors.toList())));
        byCentury.forEach((century, titles) -> System.out.println("century " + century + ": " + titles));
    }
}
```

```
ana@vm:~/fp/streams$ java Grouping.java
[fantasy, classic, sci-fi, poetry]
fantasy: [Book[title=The Hobbit, author=J. R. R. Tolkien, year=1937, pages=310, priceCents=4590, genre=fantasy]]
crime:   null
classic 6
fantasy 1
poetry 1
sci-fi 4
century 11: [Beowulf]
century 19: [Emma, Persuasion, Middlemarch, Dom Casmurro]
century 20: [Dune, Children of Dune, The Left Hand of Darkness, The Dispossessed, Ulysses, Grande Sertão: Veredas, The Hobbit]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"On the left, the twelve books as a stream. groupingBy with Book::genre as the classifier asks each book for its genre and drops it into a bucket with that key. Four buckets result: classic with six books, sci-fi with four, fantasy with one and poetry with one. There is no crime bucket, because no book produced that key.\"><defs><marker id=\"buckets-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"buckets-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">12 books</text><text x=\"95.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Shelf.BOOKS</text><rect x=\"220\" y=\"100\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">groupingBy</text><text x=\"305.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Book::genre</text><path d=\"M170 130 L216 130\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-paperdim)\"></path><rect x=\"450\" y=\"20\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">classic</text><rect x=\"580\" y=\"20\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">6 books</text><path d=\"M390 130 L420 130 L420 39 L446 39\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-phosphor)\"></path><rect x=\"450\" y=\"70\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sci-fi</text><rect x=\"580\" y=\"70\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4 books</text><path d=\"M390 130 L420 130 L420 89 L446 89\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-phosphor)\"></path><rect x=\"450\" y=\"120\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fantasy</text><rect x=\"580\" y=\"120\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1 book</text><path d=\"M390 130 L420 130 L420 139 L446 139\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-phosphor)\"></path><rect x=\"450\" y=\"170\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">poetry</text><rect x=\"580\" y=\"170\" width=\"120\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1 book</text><path d=\"M390 130 L420 130 L420 189 L446 189\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#buckets-ah-phosphor)\"></path><rect x=\"450\" y=\"220\" width=\"250\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"575.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no crime key: get returns null</text></svg>", "caption": "The classifier picks a key for each element; a key exists only if some element produced it."}
```

## Three things to notice

**The keys come from the data.** `byGenre` has the four genres the shelf contains and no others.
`byGenre.get("crime")` is `null`, not an empty list, because no book produced that key; a report that
must show every genre, including the empty ones, has to start from the list of genres rather than
from the map. Section 04 shows the one collector that always has both of its keys.

**The plain map has no order you should rely on.** `byGenre` is a `HashMap`, and the order of
`keySet()` is whatever the hash table made of it. The second form of `groupingBy` takes a map
factory: `TreeMap::new`, used as a `Supplier` (lesson 3 section 04), gives keys in sorted order, which
is what a printed report wants.

**The key can be computed.** `b.year() / 100 + 1` turns a year into a century with integer division:
1965 is in the 20th, 1815 in the 19th, and Beowulf, dated 1000, in the 11th by this sum. The third
argument, `Collectors.mapping(Book::title, toList())`, made each group a list of titles instead of a
list of books. That argument is called the **downstream** collector, and it is the subject of the
next section.
