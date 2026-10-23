---
title: Where a stream comes from
version: 1
---

**Any collection gives a stream with `stream()`, and several other places give one too.** The source
decides what values flow and in what order; everything after it only sees one value at a time.

```schooling-example
{
  "language": "java",
  "file": "Sources.java",
  "parts": [
    {
      "code": "// Sources.java: six ways to start a stream\nimport java.util.Arrays;\nimport java.util.Map;\nimport java.util.stream.IntStream;\nimport java.util.stream.Stream;\n\npublic class Sources {\n    public static void main(String[] args) {"
    },
    {
      "code": "        System.out.println(Shelf.BOOKS.stream().count());",
      "note": "A collection's `stream()`: the most common source. `count()` ends it with the number of elements."
    },
    {
      "code": "        System.out.println(Stream.of(\"Emma\", \"Dune\", \"Ulysses\").map(String::length).toList());",
      "note": "`Stream.of` takes the values themselves, for a handful known in advance."
    },
    {
      "code": "        int[] years = {1965, 1815, 1922};\n        System.out.println(Arrays.stream(years).max().getAsInt());",
      "note": "`Arrays.stream` over an `int[]` gives an `IntStream`, the primitive kind from lesson 2 section 04, with `max` built in."
    },
    {
      "code": "        System.out.println(IntStream.rangeClosed(1, 5).sum());",
      "note": "`IntStream.range` and `rangeClosed` count, without any collection behind them. `rangeClosed(1, 5)` includes the 5."
    },
    {
      "code": "        System.out.println(Map.of(\"sci-fi\", 4).entrySet().stream().map(e -> e.getKey() + \"=\" + e.getValue()).toList());",
      "note": "A map is not a collection, but its `entrySet()`, `keySet()` and `values()` are, and each has `stream()`."
    },
    {
      "code": "        System.out.println(Stream.iterate(1, n -> n * 2).limit(10).toList());\n    }\n}\n",
      "note": "`Stream.iterate` makes values from a seed and a rule, forever. `limit(10)` is what makes it finish."
    }
  ],
  "output": "12\n[4, 4, 7]\n1965\n15\n[sci-fi=4]\n[1, 2, 4, 8, 16, 32, 64, 128, 256, 512]"
}
```

## Infinite sources

`Stream.iterate(1, n -> n * 2)` describes every power of two, which is an infinite sequence, and the
program did not run forever. **A stream computes values only as they are pulled**, and `limit(10)`
stopped pulling after ten. Remove the `limit` and `toList()` would try to collect them all, and the
program would run until the numbers overflowed and memory ran out. `Stream.generate(supplier)` is the
other infinite source: it calls a `Supplier` (lesson 2 section 03) for each value, which suits random
numbers or new identifiers, and needs a `limit` just the same.

Lesson 20 adds one more source that matters in practice: `Files.lines(path)`, a stream of the lines
of a file, read as they are pulled rather than all at once.

## A stream of `int` is not a `Stream<Integer>`

`Arrays.stream(years)` and `IntStream.rangeClosed` gave `IntStream`, not `Stream<Integer>`. The
primitive streams, `IntStream`, `LongStream` and `DoubleStream`, exist for the reason the primitive
interfaces do: **no boxing per element**. They also have the arithmetic a `Stream<Integer>` lacks,
`sum`, `average`, `max`, `summaryStatistics`, which is why `max().getAsInt()` and `sum()` were
available above. Lesson 7 shows how to cross between the two kinds.
