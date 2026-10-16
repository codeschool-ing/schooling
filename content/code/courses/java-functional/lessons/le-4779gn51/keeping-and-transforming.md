---
title: Keeping and transforming
version: 1
---

**`filter` keeps some elements, `map` turns each element into one other value, and `flatMap` turns
each element into any number of values.** Those three, with a handful of steps that reorder and trim,
make up most intermediate operations you will write. This program runs them on the shelf from lesson
6, saved beside it in `~/fp/streams`:

```schooling-example
{
  "language": "java",
  "file": "Steps.java",
  "parts": [
    {
      "code": "// Steps.java: filter, map, flatMap, distinct, sorted, skip and limit on the shelf\nimport java.util.Arrays;\nimport java.util.Comparator;\nimport java.util.List;\n\npublic class Steps {\n    public static void main(String[] args) {"
    },
    {
      "code": "        List<String> sciFiAuthors = Shelf.BOOKS.stream()\n                .filter(b -> b.genre().equals(\"sci-fi\"))\n                .map(Book::author)\n                .distinct()\n                .toList();\n        System.out.println(\"sci-fi authors: \" + sciFiAuthors);",
      "note": "`filter` keeps the four science-fiction books, `map` turns each into its author, and `distinct` drops repeats, comparing with `equals`. Two authors wrote the four."
    },
    {
      "code": "\n        int totalPages = Shelf.BOOKS.stream().mapToInt(Book::pages).sum();\n        System.out.println(\"pages on the shelf: \" + totalPages);",
      "note": "`mapToInt` is `map` into an `IntStream`, the primitive kind from lesson 6 section 03, which has `sum`. `boxed()` goes the other way, back to a `Stream<Integer>`."
    },
    {
      "code": "\n        List<String> words = Shelf.BOOKS.stream()\n                .map(Book::title)\n                .flatMap(t -> Arrays.stream(t.split(\" \")))\n                .filter(w -> w.length() > 6)\n                .sorted()\n                .toList();\n        System.out.println(\"long title words: \" + words);",
      "note": "`flatMap` takes a function that returns a stream, and joins all those streams into one. Each title became its words, and the words of all twelve titles flowed on as a single stream."
    },
    {
      "code": "\n        List<String> page2 = Shelf.BOOKS.stream()\n                .sorted(Comparator.comparingLong(Book::priceCents))\n                .skip(4)\n                .limit(4)\n                .map(b -> b.title() + \" \" + b.priceCents())\n                .toList();\n        System.out.println(\"second page of four, by price: \" + page2);\n    }\n}\n",
      "note": "`sorted` takes a comparator built as in lesson 5. `skip(4)` drops the first four and `limit(4)` keeps the next four: the second page of a list shown four at a time."
    }
  ],
  "output": "sci-fi authors: [Frank Herbert, Ursula K. Le Guin]\npages on the shelf: 5166\nlong title words: [Beowulf, Casmurro, Children, Darkness, Dispossessed, Middlemarch, Persuasion, Sertão:, Ulysses, Veredas]\nsecond page of four, by price: [Middlemarch 4490, The Hobbit 4590, The Left Hand of Darkness 4990, The Dispossessed 5490]"
}
```

## `map` is one to one, `flatMap` is one to many

`map(Book::title)` gave one title for each book. A title split into words is several values, and
`map(t -> Arrays.stream(t.split(" ")))` would have produced a `Stream<Stream<String>>`, a stream
whose elements are streams, which is almost never what anybody wants. **`flatMap` flattens it**:
the function returns a stream for each element, and the result is one stream of everything they
contained. The same shape turns a list of orders into a list of the items in them, or a list of
directories into a list of their files. The split is on spaces and nothing else, which is why `Sertão:` kept its colon.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"On the left, three titles: Dune, Children of Dune and The Hobbit. With map, each title gives one value, a stream of its words, so the result is three streams. With flatMap, the words of all three flow on as one stream: Dune, Children, of, Dune, The, Hobbit.\"><defs><marker id=\"flatmap-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Dune</text><rect x=\"20\" y=\"80\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Children of Dune</text><rect x=\"20\" y=\"130\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">The Hobbit</text><text x=\"300\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">map: three streams</text><rect x=\"225\" y=\"30\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[Dune]</text><path d=\"M190 48 L221 48\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flatmap-ah-paperdim)\"></path><rect x=\"225\" y=\"80\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[Children, of, Dune]</text><path d=\"M190 98 L221 98\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flatmap-ah-paperdim)\"></path><rect x=\"225\" y=\"130\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[The, Hobbit]</text><path d=\"M190 148 L221 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flatmap-ah-paperdim)\"></path><text x=\"565\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">flatMap: one stream</text><rect x=\"430\" y=\"30\" width=\"270\" height=\"136\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Dune</text><text x=\"565\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Children</text><text x=\"565\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">of</text><text x=\"565\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Dune</text><text x=\"565\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">The</text><text x=\"565\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Hobbit</text></svg>", "caption": "map gives one value per element; flatMap joins the streams it gets into one."}
```

## Order of steps matters

`filter` early makes everything after it cheaper, because fewer elements reach the later steps. In
`words`, filtering by length after `flatMap` was the only option, since a word does not exist until
the title is split; filtering the books by genre before mapping them to authors, in `sciFiAuthors`,
saved eight `map` calls. **`distinct` and `sorted` remember elements**: `distinct` keeps a set of
everything it has passed, and `sorted` holds the whole stream until it has seen the end. On twelve
books that costs nothing worth measuring. On a stream of millions it decides whether the program
fits in memory, which is a reason to put them after the `filter` that removes most of the elements.
