---
title: Comparators built from keys
version: 1
---

**`Comparator.comparing(key)` builds a comparator from a function that extracts what to compare**,
and `thenComparing` adds the rule for ties. Together they replace the comparator written by hand,
with its subtraction and its nested `if`, by a description of the order:

```java
// Orders.java: comparators described by their keys
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class Orders {
    record Book(String title, String author, int year, String series) {}

    static void show(String label, List<Book> books, Comparator<Book> order) {
        List<Book> sorted = new ArrayList<>(books);
        sorted.sort(order);
        System.out.println(label);
        for (Book b : sorted) {
            System.out.println("  " + b.author() + ", " + b.year() + ", " + b.title());
        }
    }

    public static void main(String[] args) {
        List<Book> books = List.of(
                new Book("Dune", "Herbert", 1965, "Dune"),
                new Book("Persuasion", "Austen", 1817, null),
                new Book("Middlemarch", "Eliot", 1871, null),
                new Book("Children of Dune", "Herbert", 1976, "Dune"),
                new Book("Emma", "Austen", 1815, null));

        show("by author, then newest first:", books,
                Comparator.comparing(Book::author)
                        .thenComparing(Book::year, Comparator.reverseOrder()));

        show("the same, with reversed() at the end:", books,
                Comparator.comparing(Book::author)
                        .thenComparing(Book::year)
                        .reversed());

        show("books in a series first:", books,
                Comparator.comparing(Book::series, Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparingInt(Book::year));
    }
}
```

```
ana@vm:~/fp/composition$ java Orders.java
by author, then newest first:
  Austen, 1817, Persuasion
  Austen, 1815, Emma
  Eliot, 1871, Middlemarch
  Herbert, 1976, Children of Dune
  Herbert, 1965, Dune
the same, with reversed() at the end:
  Herbert, 1976, Children of Dune
  Herbert, 1965, Dune
  Eliot, 1871, Middlemarch
  Austen, 1817, Persuasion
  Austen, 1815, Emma
books in a series first:
  Herbert, 1965, Dune
  Herbert, 1976, Children of Dune
  Austen, 1815, Emma
  Austen, 1817, Persuasion
  Eliot, 1871, Middlemarch
```

The first order reads as it is written: **by author, and among one author's books, by year with
the newest first.** `thenComparing(Book::year, Comparator.reverseOrder())` takes a second argument,
the comparator to use on that key, and only that key is reversed.

## `reversed()` reverses everything before it

The second order looks like the first with the reversal moved to the end, and it is not. Herbert
now comes before Eliot and Austen. **`reversed()` is called on the comparator built so far**, so it
reversed the author order and the year order together. The years still came out newest first,
because the year order it reversed was oldest first; only the authors give the mistake away. This is the most common mistake with
comparator chains, and the output shows it plainly, which is why it is worth printing the result of
a new order once before trusting it.

## Missing keys

`series` is `null` for three books, and a plain `comparing(Book::series)` would throw a
`NullPointerException` the first time it compared one. `Comparator.nullsLast(...)` wraps a
comparator and decides where the `null` values go, here after everything else.
`Comparator.naturalOrder()` is the order a type defines for itself, alphabetical for strings. So the
two Dune books came first, in year order thanks to `thenComparingInt`, and the books with no series
followed.

`thenComparingInt` and `comparingInt` take a `ToIntFunction` and compare `int` values without
boxing them, the same trade as in lesson 2 section 04. Use them for numeric keys.
