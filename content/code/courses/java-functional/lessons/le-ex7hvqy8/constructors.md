---
title: Constructor references
version: 1
---

**`ClassName::new` is a reference to a constructor**, and its shape is chosen by the target type
like any other reference. A class with several constructors gives several shapes, and the compiler
picks the constructor whose parameters match the interface's method:

```java
// Constructors.java: one class, three constructor references, and an array
import java.util.List;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.function.IntFunction;

public class Constructors {
    record Book(String title, int year) {
        Book(String title) {
            this(title, 0);
        }
    }

    public static void main(String[] args) {
        Function<String, Book> undated = Book::new;
        BiFunction<String, Integer, Book> dated = Book::new;
        System.out.println(undated.apply("Beowulf"));
        System.out.println(dated.apply("Dune", 1965));

        IntFunction<String[]> slots = String[]::new;
        System.out.println(slots.apply(3).length);

        List<String> titles = List.of("Emma", "Dune", "Ulysses");
        String[] asArray = titles.toArray(String[]::new);
        System.out.println(asArray.length + " " + asArray[2]);
    }
}
```

```
ana@vm:~/fp/references$ java Constructors.java
Book[title=Beowulf, year=0]
Book[title=Dune, year=1965]
3
3 Ulysses
```

`Book::new` appeared twice and meant two constructors. Where a `Function<String, Book>` was wanted,
the one-argument constructor fitted; where a `BiFunction<String, Integer, Book>` was wanted, the
record's own two-argument one did. **The text of the reference is the same; the target type picks
the constructor.**

`String[]::new` is a reference to building an array, and its shape is `IntFunction<String[]>`: give
it a length, get an empty array of that length. It exists mostly for one call, `toArray`, which
uses it to build an array of the right type and size. Before Java 11 that call was written
`titles.toArray(new String[0])`, and you will see that form in older code.

## Where they are used

A constructor reference is what you pass when an API needs **a way to make things, not the things
themselves**:

| call | what it is given | what it does with it |
|---|---|---|
| `map.computeIfAbsent(key, k -> new ArrayList<>())` | a `Function` | builds a list only when the key is new |
| `Collectors.toCollection(TreeSet::new)` (lesson 8) | a `Supplier` | builds the collection a stream fills |
| `stream.toArray(String[]::new)` (lesson 7) | an `IntFunction` | builds the array the results go into |

The first row is written as a lambda on purpose. `computeIfAbsent` passes the key to the function,
so `ArrayList::new` there means `k -> new ArrayList<>(k)`. With `String` keys that does not compile,
because `ArrayList` has no constructor taking a string. With `Integer` keys it does compile, and
quietly uses the key as the new list's initial capacity, which is not what anybody meant. Section
05 has more cases where the lambda is the better choice.
