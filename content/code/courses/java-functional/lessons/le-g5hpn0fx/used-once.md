---
title: A stream is used once, and leaves its source alone
version: 1
---

**A stream can be consumed once.** After its terminal operation it is finished, and asking it for
anything else is an error. It also never changes the collection it came from, and the list that
`toList()` gives back cannot be changed either. Three short programs, three exceptions:

```java
// Once.java: three things a stream will not do
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

public class Once {
    public static void main(String[] args) {
        Stream<Book> classics = Shelf.BOOKS.stream().filter(b -> b.genre().equals("classic"));
        System.out.println(classics.count() + " classics");
        try {
            System.out.println(classics.count() + " classics, again");
        } catch (IllegalStateException e) {
            System.out.println("second use: " + e.getMessage());
        }

        List<String> titles = Shelf.BOOKS.stream().map(Book::title).toList();
        try {
            titles.add("Moby-Dick");
        } catch (UnsupportedOperationException e) {
            System.out.println("toList() is read-only: " + e);
        }

        List<String> mutable = new ArrayList<>(List.of("Emma", "Dune"));
        try {
            mutable.stream().forEach(t -> mutable.add(t + " (copy)"));
        } catch (java.util.ConcurrentModificationException e) {
            System.out.println("changing the source mid-stream: " + e);
        }
    }
}
```

```
ana@vm:~/fp/streams$ java Once.java
6 classics
second use: stream has already been operated upon or closed
toList() is read-only: java.lang.UnsupportedOperationException
changing the source mid-stream: java.util.ConcurrentModificationException
```

## A stream is a traversal

The first exception is the one everybody meets. **A stream is closer to an iterator than to a
list**: a single pass over the source, which is used up as it goes. Storing a stream in a variable to
use twice is therefore a mistake in the design, not in the syntax. The fix is to keep the
**source**, or a `Supplier<Stream<Book>>` that builds a new stream each time, and start a new
pipeline for each question.

## The results are read-only

`toList()`, added in Java 16, returns an unmodifiable list, and `add` threw
`UnsupportedOperationException`. That is deliberate: the result of a query is a value, and code that
wants to edit it should say so with `new ArrayList<>(stream.toList())`. Older code uses
`collect(Collectors.toList())`, which returns a list you can change; lesson 8 explains collectors.

## Leave the source alone

The last case changed the list from inside its own stream, and the stream noticed:
`ConcurrentModificationException`. **A pipeline's lambdas should not change the source they are
reading**, nor anything else the pipeline depends on. The rule has a name in the documentation,
non-interference, and it is the same one the `java` course's lesson 34 gave for iterators, for the
same reason: the traversal and the change would disagree about what is there. When the result
should be a new list, the stream builds it with `toList()`; the old one stays as it was.
