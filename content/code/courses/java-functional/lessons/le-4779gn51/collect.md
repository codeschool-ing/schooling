---
title: Collecting into a container
version: 1
---

**`collect` is the terminal operation that builds a container, a list, a set, a map or a string, from
the elements.** `reduce` makes a new value at every step, which is right for a number and wasteful for
a container: reducing strings with `+` would build a new string for every element and copy everything
accumulated so far each time. `collect` instead creates one container and adds each element to it.
The recipes for doing so are in `Collectors`:

```java
// Collect.java: four collectors, and what toMap does with a repeated key
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.stream.Collectors;

public class Collect {
    public static void main(String[] args) {
        Set<String> genres = Shelf.BOOKS.stream().map(Book::genre).collect(Collectors.toSet());
        System.out.println("genres: " + genres.size());

        String line = Shelf.BOOKS.stream()
                .filter(b -> b.genre().equals("sci-fi"))
                .map(Book::title)
                .collect(Collectors.joining(", ", "sci-fi: ", "."));
        System.out.println(line);

        Map<String, Integer> pages = Shelf.BOOKS.stream()
                .filter(b -> b.pages() > 600)
                .collect(Collectors.toMap(Book::title, Book::pages));
        System.out.println(new TreeMap<>(pages));

        try {
            Shelf.BOOKS.stream().collect(Collectors.toMap(Book::author, Book::title));
        } catch (IllegalStateException e) {
            System.out.println(e.getMessage());
        }

        Map<String, String> byAuthor = Shelf.BOOKS.stream()
                .collect(Collectors.toMap(Book::author, Book::title, (first, second) -> first + " / " + second, TreeMap::new));
        System.out.println(byAuthor.get("Frank Herbert") + " | " + byAuthor.get("Jane Austen"));
    }
}
```

```
ana@vm:~/fp/streams$ java Collect.java
genres: 4
sci-fi: Dune, Children of Dune, The Left Hand of Darkness, The Dispossessed.
{Grande Sertão: Veredas=624, Middlemarch=880, Ulysses=730}
Duplicate key Frank Herbert (attempted merging values Dune and Children of Dune)
Dune / Children of Dune | Emma / Persuasion
```

- **`toSet()`** gathered the genres into a set, which kept each once. Four genres. A `HashSet` has no
  order you should print and rely on, which is why the line prints its size.
- **`joining(", ", "sci-fi: ", ".")`** joined the titles with a separator, a prefix and a suffix. It
  builds one `StringBuilder` and appends to it, which is the efficient version of the `+` loop.
- **`toMap(key, value)`** built a map from each book's title to its pages. It is printed through a
  `TreeMap` so that the keys come out sorted.

## A repeated key is an error, by default

`toMap(Book::author, Book::title)` failed, and the message names the key and both values: Frank
Herbert wrote two books, and a map can hold one value per key. **`toMap` refuses to choose which one to
keep**, which is the right default, because either silent choice would lose a book. When repeats are
expected, the third argument says how to merge two values for the same key; here the titles were
joined. The fourth, `TreeMap::new`, chooses the kind of map, a constructor reference used as a
`Supplier` exactly as lesson 3 section 04 showed.

Most real questions about a shelf are about groups rather than about a map of one value per key:
books per genre, total price per author, the cheapest book in each decade. That is
`Collectors.groupingBy`, and it is lesson 8.
