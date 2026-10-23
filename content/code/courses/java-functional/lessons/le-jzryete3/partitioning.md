---
title: Partitioning into yes and no
version: 1
---

**`Collectors.partitioningBy(predicate)` splits a stream into two groups, the elements that pass and
the ones that do not, and returns a map with exactly two keys, `true` and `false`.** It is
`groupingBy` with a `Predicate` for a classifier, and with one difference that is the reason it
exists:

```java
// Partition.java: partitioningBy against groupingBy on the same yes-or-no question
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class Partition {
    public static void main(String[] args) {
        Map<Boolean, List<String>> cheap = Shelf.BOOKS.stream()
                .collect(Collectors.partitioningBy(b -> b.priceCents() < 4000,
                        Collectors.mapping(Book::title, Collectors.toList())));
        System.out.println("under 40.00: " + cheap.get(true));
        System.out.println("the rest:    " + cheap.get(false));

        Map<Boolean, Long> free = Shelf.BOOKS.stream()
                .collect(Collectors.partitioningBy(b -> b.priceCents() == 0, Collectors.counting()));
        System.out.println("partitioningBy, free: " + free);

        Map<Boolean, Long> freeGrouped = Shelf.BOOKS.stream()
                .collect(Collectors.groupingBy(b -> b.priceCents() == 0, Collectors.counting()));
        System.out.println("groupingBy, free:     " + freeGrouped);
    }
}
```

```
ana@vm:~/fp/streams$ java Partition.java
under 40.00: [Emma, Persuasion, Dom Casmurro, Beowulf]
the rest:    [Dune, Children of Dune, The Left Hand of Darkness, The Dispossessed, Middlemarch, Ulysses, Grande Sertão: Veredas, The Hobbit]
partitioningBy, free: {false=12, true=0}
groupingBy, free:     {false=12}
```

The first two lines are the split you would expect: four books under 40.00 and eight at or above it.
Like `groupingBy`, `partitioningBy` takes a downstream collector, and `mapping` made each side a list
of titles.

## Both keys, always

No book on the shelf is free, and the two collectors disagree about what that means.
**`partitioningBy` returned `{false=12, true=0}`**: both keys, with zero for the side nobody is on.
**`groupingBy` returned `{false=12}`**, because a key exists only when some element produced it.
Code that reads `freeGrouped.get(true)` gets `null`, and with a `Long` that becomes a
`NullPointerException` the moment it is unboxed for arithmetic. With `partitioningBy` the same read
gives 0.

So the rule is simple: **when the question is yes or no, use `partitioningBy`**, and every reader of
the result can count on both answers being there. `groupingBy` is for classifiers with more than two
outcomes, where the absent keys are a real fact about the data, as `crime` was in section 02.
