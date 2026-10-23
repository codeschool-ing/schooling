---
title: The short answers
version: 1
---

**Many questions asked of a stream have a terminal operation of their own**, and using it is both
shorter and faster than collecting a list and looking at it. Faster, because the matching ones stop
as soon as they know (lesson 6 section 04).

```java
// Answers.java: terminal operations that answer one question each
import java.util.Arrays;
import java.util.Comparator;
import java.util.IntSummaryStatistics;

public class Answers {
    public static void main(String[] args) {
        System.out.println("any over 800 pages:   " + Shelf.BOOKS.stream().anyMatch(b -> b.pages() > 800));
        System.out.println("all after 1900:       " + Shelf.BOOKS.stream().allMatch(b -> b.year() > 1900));
        System.out.println("none free:            " + Shelf.BOOKS.stream().noneMatch(b -> b.priceCents() == 0));
        System.out.println("classics:             " + Shelf.BOOKS.stream().filter(b -> b.genre().equals("classic")).count());
        System.out.println("dearest:              " + Shelf.BOOKS.stream().max(Comparator.comparingLong(Book::priceCents)).map(Book::title).orElseThrow());
        System.out.println("first before 1900:    " + Shelf.BOOKS.stream().filter(b -> b.year() < 1900).findFirst().map(Book::title).orElseThrow());
        System.out.println("average pages:        " + Shelf.BOOKS.stream().mapToInt(Book::pages).average().orElse(0));

        IntSummaryStatistics years = Shelf.BOOKS.stream().mapToInt(Book::year).summaryStatistics();
        System.out.println("years:                " + years);

        String[] titles = Shelf.BOOKS.stream().map(Book::title).filter(t -> t.startsWith("The")).toArray(String[]::new);
        System.out.println("titles starting The:  " + Arrays.toString(titles));
    }
}
```

```
ana@vm:~/fp/streams$ java Answers.java
any over 800 pages:   true
all after 1900:       false
none free:            true
classics:             6
dearest:              Ulysses
first before 1900:    Emma
average pages:        430.5
years:                IntSummaryStatistics{count=12, sum=22101, min=1000, average=1841.750000, max=1976}
titles starting The:  [The Left Hand of Darkness, The Dispossessed, The Hobbit]
```

| question | operation | returns |
|---|---|---|
| does any element match? | `anyMatch(p)` | `boolean`, stops at the first match |
| does every element match? | `allMatch(p)` | `boolean`, stops at the first failure |
| does no element match? | `noneMatch(p)` | `boolean`, stops at the first match |
| how many? | `count()` | `long` |
| the largest, the smallest? | `max(cmp)`, `min(cmp)` | `Optional` |
| the first one that passes? | `findFirst()` | `Optional` |
| sum, average, all at once | `sum`, `average`, `summaryStatistics` on a primitive stream | a number, an `OptionalDouble`, a statistics object |
| an array | `toArray(String[]::new)` | an array of the right type (lesson 3 section 04) |

Two of these deserve a second look:

- **`allMatch` on an empty stream is `true`**, and `anyMatch` is `false`. "Every book on an empty
  shelf is free" is true because there is no book to contradict it. That is logic, not a bug, and it
  is worth remembering before writing `if (orders.stream().allMatch(Order::isPaid)) ship();`;
- **`summaryStatistics` makes one pass** and keeps the count, sum, minimum, average and maximum
  together, where asking for each separately would walk the shelf five times. The years run from 1000,
  Beowulf, to 1976.

`max`, `min` and `findFirst` return an `Optional`, for the same reason `reduce` without an identity
did: an empty stream has no largest element. `orElseThrow()` takes the value out and throws if there
is none, which is right here, where an empty shelf would be a bug in the program rather than a case
to handle.
