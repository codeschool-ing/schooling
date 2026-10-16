---
title: Finishing a collector, and running two at once
version: 1
---

**Three more collectors change the shape of a result rather than computing a new one.**
`collectingAndThen` runs a function on what another collector produced. `toCollection` chooses the
exact collection to fill. `teeing`, added in Java 12, sends every element to two collectors at once
and combines their two results at the end.

```schooling-example
{
  "language": "java",
  "file": "Finishing.java",
  "parts": [
    {
      "code": "// Finishing.java: collectingAndThen, toCollection and teeing\nimport java.util.Comparator;\nimport java.util.List;\nimport java.util.Map;\nimport java.util.TreeMap;\nimport java.util.TreeSet;\nimport java.util.stream.Collectors;\n\npublic class Finishing {\n    public static void main(String[] args) {"
    },
    {
      "code": "        Map<String, String> dearest = Shelf.BOOKS.stream()\n                .collect(Collectors.groupingBy(Book::genre, TreeMap::new,\n                        Collectors.collectingAndThen(\n                                Collectors.maxBy(Comparator.comparingLong(Book::priceCents)),\n                                b -> b.orElseThrow().title())));\n        System.out.println(dearest);",
      "note": "The dearest book per genre again, without the `Optional` around each one. `collectingAndThen` takes the `Optional` that `maxBy` produced for a group and turns it into the title, once per group."
    },
    {
      "code": "\n        TreeSet<String> authors = Shelf.BOOKS.stream()\n                .map(Book::author)\n                .collect(Collectors.toCollection(TreeSet::new));\n        System.out.println(authors.first() + \" ... \" + authors.last() + \" (\" + authors.size() + \")\");",
      "note": "`toCollection` takes a `Supplier` for the collection to fill. A `TreeSet` keeps the authors sorted and unique, and offers `first` and `last`, which a plain `Set` does not."
    },
    {
      "code": "\n        String range = Shelf.BOOKS.stream()\n                .collect(Collectors.teeing(\n                        Collectors.minBy(Comparator.comparingLong(Book::priceCents)),\n                        Collectors.maxBy(Comparator.comparingLong(Book::priceCents)),\n                        (min, max) -> min.orElseThrow().title() + \" to \" + max.orElseThrow().title()));\n        System.out.println(\"from the cheapest to the dearest: \" + range);",
      "note": "`teeing` passes every book to both `minBy` and `maxBy` in a single pass, then hands their two results to the function at the end."
    },
    {
      "code": "\n        List<String> fixed = Shelf.BOOKS.stream()\n                .map(Book::title)\n                .collect(Collectors.collectingAndThen(Collectors.toList(), List::copyOf));\n        try {\n            fixed.add(\"Moby-Dick\");\n        } catch (UnsupportedOperationException e) {\n            System.out.println(fixed.size() + \" titles, and add() is refused\");\n        }\n    }\n}\n",
      "note": "The older way to get a list nobody can change: collect a mutable list, then copy it with `List::copyOf`. Since Java 16, `toList()` on the stream does both."
    }
  ],
  "output": "{classic=Ulysses, fantasy=The Hobbit, poetry=Beowulf, sci-fi=Dune}\nAnonymous ... Ursula K. Le Guin (9)\nfrom the cheapest to the dearest: Beowulf to Ulysses\n12 titles, and add() is refused"
}
```

## Which collector, for which question

| question | collector |
|---|---|
| a map from a group to its elements | `groupingBy(classifier)` |
| a number, a sum or a summary per group | `groupingBy(classifier, counting() / summingLong(...) / averagingInt(...))` |
| only one field of each element in a group | `mapping(field, downstream)` |
| yes or no, with both answers always present | `partitioningBy(predicate)` |
| a result, then one more step on it | `collectingAndThen(collector, finisher)` |
| a particular kind of collection | `toCollection(TreeSet::new)` |
| two results from one pass | `teeing(first, second, merger)` |
| one string | `joining(separator, prefix, suffix)` (lesson 7) |

Every one of these is a recipe built from four functions: make an empty container, add one element
to it, merge two containers, finish. That last part, merging, is what lets a collector run on a
stream split across processors, and lesson 9 is the place where that matters.
