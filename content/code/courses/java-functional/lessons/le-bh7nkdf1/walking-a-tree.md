---
title: Walking a tree
version: 1
---

**Three methods of `Files` turn a directory into a stream of paths: `list` for one level, `walk` for
every level, and `find` for every level with a test.** All three hold the directory open while the
stream is used, so each goes in a `try` with resources, as `Files.lines` did. The program builds a small
library, looks at it three ways and deletes it:

```schooling-example
{
  "language": "java",
  "file": "Tree.java",
  "parts": [
    {
      "code": "// Tree.java: build a small tree, list it, walk it, search it and delete it\nimport java.io.IOException;\nimport java.io.UncheckedIOException;\nimport java.nio.file.Files;\nimport java.nio.file.Path;\nimport java.util.Comparator;\nimport java.util.stream.Stream;\n\npublic class Tree {\n    public static void main(String[] args) throws IOException {\n        Path root = Path.of(\"library\");\n        Files.createDirectories(root.resolve(\"fiction/classics\"));\n        Files.createDirectories(root.resolve(\"poetry\"));\n        Files.writeString(root.resolve(\"fiction/dune.txt\"), \"Dune\\n\".repeat(400));\n        Files.writeString(root.resolve(\"fiction/classics/emma.txt\"), \"Emma\\n\".repeat(900));\n        Files.writeString(root.resolve(\"poetry/odes.txt\"), \"Odes\\n\".repeat(30));\n        Files.writeString(root.resolve(\"poetry/notes.md\"), \"# notes\\n\");",
      "note": "Six lines build the tree the rest walks: four directories and four files, `createDirectories` making every missing level at once. The sizes are chosen: `dune.txt` is exactly 2,000 bytes."
    },
    {
      "code": "\n        System.out.println(\"one level:\");\n        try (Stream<Path> entries = Files.list(root)) {\n            entries.sorted().forEach(p -> System.out.println(\"  \" + p));\n        }",
      "note": "`Files.list` gives one level, the entries directly inside `root`, in no promised order, so it is sorted before printing."
    },
    {
      "code": "\n        System.out.println(\"every .txt, with its size:\");\n        try (Stream<Path> all = Files.walk(root)) {\n            all.filter(Files::isRegularFile)\n                    .filter(p -> p.toString().endsWith(\".txt\"))\n                    .sorted()\n                    .forEach(p -> System.out.println(\"  \" + root.relativize(p) + \"  \" + size(p)));\n        }",
      "note": "`Files.walk` gives every level, `root` included, directories and files alike. The filters keep the regular files whose names end in `.txt`."
    },
    {
      "code": "\n        System.out.println(\"over 2,000 bytes:\");\n        try (Stream<Path> big = Files.find(root, Integer.MAX_VALUE,\n                (p, attrs) -> attrs.isRegularFile() && attrs.size() > 2_000)) {\n            big.forEach(p -> System.out.println(\"  \" + p.getFileName()));\n        }",
      "note": "`Files.find` walks too, and hands its test the attributes it already read for each entry, so asking the size costs no second trip to the disk."
    },
    {
      "code": "\n        try (Stream<Path> all = Files.walk(root)) {\n            all.sorted(Comparator.reverseOrder()).forEach(Tree::delete);\n        }\n        System.out.println(\"deleted, exists: \" + Files.exists(root));\n    }",
      "note": "A directory can only be deleted once it is empty. In reverse order every path comes before its parent, so the walk deletes the files first and `library` last."
    },
    {
      "code": "\n    static long size(Path p) {\n        try {\n            return Files.size(p);\n        } catch (IOException e) {\n            throw new UncheckedIOException(e);\n        }\n    }\n\n    static void delete(Path p) {\n        try {\n            Files.delete(p);\n        } catch (IOException e) {\n            throw new UncheckedIOException(e);\n        }\n    }\n}\n\n",
      "note": "`Files.size` and `Files.delete` throw `IOException`, which no lambda of `java.util.function` may throw. Each helper wraps it in `UncheckedIOException` and the stream carries it out."
    }
  ]
}
```

```
ana@vm:~/fp/files$ java Tree.java
one level:
  library/fiction
  library/poetry
every .txt, with its size:
  fiction/classics/emma.txt  4500
  fiction/dune.txt  2000
  poetry/odes.txt  150
over 2,000 bytes:
  emma.txt
deleted, exists: false
```

## What each one saw

`list` saw the two directories directly inside `library` and nothing below them. **`walk` went down
every level** and met eight paths, `library` itself among them; the filters kept the three regular files
ending in `.txt`, and `notes.md` and the four directories were dropped. `find` met the same paths and
kept one: `emma.txt` at 4,500 bytes. `dune.txt` is exactly 2,000, and the test said more than 2,000.

The delete is the order that matters. **`Files.delete` refuses a directory that still has something in
it**, so a tree is deleted from the leaves up. Sorted in reverse, `library/poetry/odes.txt` comes before
`library/poetry`, which comes before `library`, and the last line confirms nothing was left.

## Checked exceptions in a stream

`Files::isRegularFile` went straight into `filter`, but `Files.size` could not: it declares
`IOException`, and the functional interfaces of lesson 2 declare no checked exceptions, so a lambda
calling it does not compile. **The helpers catch it and rethrow it as `UncheckedIOException`**, which the
stream lets through to the caller, where it can be caught and its `getCause()` read. The same wrapping
was there inside the streams themselves all along: if a directory cannot be read halfway through a walk,
`walk` throws `UncheckedIOException` from the terminal operation.

`walk` does not follow symbolic links unless asked with `FileVisitOption.FOLLOW_LINKS`, so a link that
points back up the tree cannot send it round in circles. For a walk that needs to act before and after
each directory, `Files.walkFileTree` takes a visitor with a method for each event; most programs never
need more than the stream.
