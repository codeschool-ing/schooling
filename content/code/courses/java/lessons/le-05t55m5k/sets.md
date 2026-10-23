---
title: Sets, and the order each one keeps
version: 1
---

A `Set` holds each element once. Add something it already has and nothing changes; `add` answers
`false` to say so. **What surprises people is not the uniqueness but the order**, because the three
`Set` classes in daily use keep three different ones, and a program that prints a `HashSet` and
looks right today has made a promise the class never made.

```java
// Orders.java
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

public class Orders {
    public static void main(String[] args) {
        List<String> borrowed = List.of("Dune", "Emma", "Ulysses", "Beloved", "Dune", "Emma", "Middlemarch");

        Set<String> hash = new HashSet<>(borrowed);
        Set<String> linked = new LinkedHashSet<>(borrowed);
        Set<String> tree = new TreeSet<>(borrowed);

        System.out.println("list          " + borrowed);
        System.out.println("HashSet       " + hash);
        System.out.println("LinkedHashSet " + linked);
        System.out.println("TreeSet       " + tree);
        System.out.println("add Dune again? " + tree.add("Dune"));
    }
}
```

```
ana@vm:~/colls$ java Orders.java
list          [Dune, Emma, Ulysses, Beloved, Dune, Emma, Middlemarch]
HashSet       [Beloved, Dune, Ulysses, Middlemarch, Emma]
LinkedHashSet [Dune, Emma, Ulysses, Beloved, Middlemarch]
TreeSet       [Beloved, Dune, Emma, Middlemarch, Ulysses]
add Dune again? false
```

Seven titles went in and five came out of each set: the second `Dune` and the second `Emma` were
dropped. Then the three orders:

| class | order | how it finds an element | needs from the element |
|---|---|---|---|
| `HashSet` | none you can rely on | by `hashCode`, then `equals` | `equals` and `hashCode` that agree |
| `LinkedHashSet` | the order of first insertion | the same, plus a list through the entries | the same |
| `TreeSet` | sorted | by comparing, down a balanced tree | `Comparable`, or a `Comparator` |

**`HashSet`'s order is whatever its buckets happen to produce**, here `Beloved, Dune, Ulysses,
Middlemarch, Emma`. It is the same on every run of this program, because a `String`'s hash code is
computed from its characters, and that sameness is the trap. Add more elements and the set grows
its table and the order reshuffles; change the elements' class and it changes again. A test that
compares a printed `HashSet` with a fixed string passes until the day it does not.

When the order matters, say so with the class. `LinkedHashSet` costs a little memory for the list
it threads through its entries and gives you back insertion order. `TreeSet` keeps its elements
sorted, alphabetically for strings, and adds a few navigation methods such as `first()` and
`ceiling(x)`.

## The contract a hash needs

`HashSet` and `HashMap` find an element in two steps. The hash code picks a bucket, and `equals`
compares inside it. **Two objects that are `equals` must have the same `hashCode`**, or the first
step sends them to different buckets and the second never runs. Lesson 24 overrode `equals`
correctly; here is a class that overrides it and forgets the other half:

```java
// BrokenKey.java
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;

public class BrokenKey {
    static class Book {
        final String isbn;
        Book(String isbn) { this.isbn = isbn; }

        @Override
        public boolean equals(Object o) {
            return o instanceof Book b && b.isbn.equals(isbn);
        }
        // no hashCode: Object's is used, one per object
    }

    public static void main(String[] args) {
        Set<Book> shelf = new HashSet<>();
        shelf.add(new Book("978-0441013593"));
        shelf.add(new Book("978-0441013593"));
        System.out.println("size " + shelf.size());
        System.out.println("contains " + shelf.contains(new Book("978-0441013593")));
        System.out.println("equal? " + new Book("978-0441013593").equals(new Book("978-0441013593")));
    }
}
```

```
ana@vm:~/colls$ java BrokenKey.java
size 2
contains false
equal? true
```

Three lines, each true and together absurd. The two books are equal, the set holds both of them,
and it cannot find a third equal one. **Without `hashCode`, `Object`'s version is used, and it gives
each object a number of its own**, so equal books land in different buckets. Nothing failed and
nothing warned: the set is simply wrong.

The repair is one method beside `equals`, built from the same fields:

```java
@Override
public int hashCode() {
    return Objects.hash(isbn);
}
```

Put it in `BrokenKey.java` in place of the comment that says `no hashCode`, and run the file again:

```
ana@vm:~/colls$ java BrokenKey.java
size 1
contains true
equal? true
```

The `import java.util.Objects;` at the top of the file was there for this line. Lesson 29's records write both methods for you, from the
components, and never forget one of the two.
