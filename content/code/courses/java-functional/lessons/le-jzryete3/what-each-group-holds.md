---
title: What each group holds
version: 1
---

**`groupingBy(classifier, downstream)` hands each group's elements to another collector**, and the
map holds whatever that collector produces. A list is only the default. Ask for a count and each
group becomes a number; ask for a sum and it becomes a total:

```schooling-example
{
  "language": "java",
  "file": "Downstream.java",
  "parts": [
    {
      "code": "// Downstream.java: one grouping, five different answers per group\nimport java.util.Comparator;\nimport java.util.Map;\nimport java.util.Optional;\nimport java.util.TreeMap;\nimport java.util.TreeSet;\nimport java.util.stream.Collectors;\n\npublic class Downstream {\n    public static void main(String[] args) {"
    },
    {
      "code": "        Map<String, Long> count = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.counting()));\n        System.out.println(\"count:   \" + count);",
      "note": "`counting()` turns each group into the number of elements in it, as a `Long`."
    },
    {
      "code": "\n        Map<String, Long> value = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.summingLong(Book::priceCents)));\n        System.out.println(\"value:   \" + value);",
      "note": "`summingLong` adds up one field per group: the value of each genre's stock, in cents."
    },
    {
      "code": "\n        Map<String, Double> pages = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.averagingInt(Book::pages)));\n        System.out.println(\"pages:   \" + pages);",
      "note": "`averagingInt` gives a `Double`, the average of the field within each group."
    },
    {
      "code": "\n        Map<String, String> authors = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new,\n                        Collectors.mapping(Book::author, Collectors.collectingAndThen(Collectors.toCollection(TreeSet::new), set -> String.join(\" & \", set)))));\n        System.out.println(\"authors: \" + authors);",
      "note": "Collectors nest: `mapping` turns each book into its author, `toCollection(TreeSet::new)` keeps each author once and in order, and `collectingAndThen` (section 05) joins the set into one string."
    },
    {
      "code": "\n        Map<String, Optional<Book>> dearest = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new, Collectors.maxBy(Comparator.comparingLong(Book::priceCents))));\n        dearest.forEach((g, b) -> System.out.println(\"dearest \" + g + \": \" + b.map(Book::title).orElseThrow()));\n    }\n}\n",
      "note": "`maxBy` keeps one element per group, wrapped in an `Optional` because the collector cannot know that no group will be empty."
    }
  ],
  "output": "count:   {classic=6, fantasy=1, poetry=1, sci-fi=4}\nvalue:   {classic=31940, fantasy=4590, poetry=2490, sci-fi=23460}\npages:   {classic=535.5, fantasy=310.0, poetry=96.0, sci-fi=386.75}\nauthors: {classic=George Eliot & James Joyce & Jane Austen & João Guimarães Rosa & Machado de Assis, fantasy=J. R. R. Tolkien, poetry=Anonymous, sci-fi=Frank Herbert & Ursula K. Le Guin}\ndearest classic: Ulysses\ndearest fantasy: The Hobbit\ndearest poetry: Beowulf\ndearest sci-fi: Dune"
}
```

## Reading the results as a table

| genre | count | value, cents | average pages | dearest |
|---|---|---|---|---|
| classic | 6 | 31,940 | 535.5 | Ulysses |
| fantasy | 1 | 4,590 | 310.0 | The Hobbit |
| poetry | 1 | 2,490 | 96.0 | Beowulf |
| sci-fi | 4 | 23,460 | 386.75 | Dune |

**Each downstream collector is a small `collect` run separately on one group.** That is the idea to
hold on to: `counting`, `summingLong`, `averagingInt`, `mapping`, `maxBy`, and `toList`, `toSet`
and `joining` from lesson 7, can all appear inside a `groupingBy`, and some of them, `mapping` above,
take another collector in turn. A pipeline that answers "total value per genre" is one line, and the
loop it replaces would be a map, a `getOrDefault` and an addition, written again for every new
question.

The `Optional` around each `maxBy` result is the price of generality: `maxBy` would return an empty
`Optional` for an empty stream, and inside a `groupingBy` no group is ever empty, so `orElseThrow()`
can never throw here. Section 05 shows how to remove the wrapper when it is only noise.
