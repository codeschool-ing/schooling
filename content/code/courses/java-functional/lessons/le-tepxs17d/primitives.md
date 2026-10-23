---
title: The other thirty-nine
version: 1
---

**`java.util.function` has 43 interfaces, and most of the ones after the first four are the same
shapes for `int`, `long` and `double`.** The JDK can list its own package, because its classes are
readable as a file system with the address `jrt:/`. This program reads them; it uses a stream,
which lesson 6 explains, and you do not need to follow it yet to read what it printed:

```java
// ListFunctions.java: every interface in java.util.function, read from the JDK itself
import java.net.URI;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Stream;

public class ListFunctions {
    public static void main(String[] args) throws Exception {
        Path dir = FileSystems.getFileSystem(URI.create("jrt:/"))
                .getPath("/modules/java.base/java/util/function");
        try (Stream<Path> files = Files.list(dir)) {
            List<String> names = files
                    .map(p -> p.getFileName().toString().replace(".class", ""))
                    .filter(n -> !n.contains("$"))
                    .sorted()
                    .toList();
            System.out.println(names.size() + " interfaces");
            for (int i = 0; i < names.size(); i += 4) {
                System.out.println("  " + String.join(", ", names.subList(i, Math.min(i + 4, names.size()))));
            }
        }
    }
}
```

```
ana@vm:~/fp/interfaces$ java ListFunctions.java
43 interfaces
  BiConsumer, BiFunction, BiPredicate, BinaryOperator
  BooleanSupplier, Consumer, DoubleBinaryOperator, DoubleConsumer
  DoubleFunction, DoublePredicate, DoubleSupplier, DoubleToIntFunction
  DoubleToLongFunction, DoubleUnaryOperator, Function, IntBinaryOperator
  IntConsumer, IntFunction, IntPredicate, IntSupplier
  IntToDoubleFunction, IntToLongFunction, IntUnaryOperator, LongBinaryOperator
  LongConsumer, LongFunction, LongPredicate, LongSupplier
  LongToDoubleFunction, LongToIntFunction, LongUnaryOperator, ObjDoubleConsumer
  ObjIntConsumer, ObjLongConsumer, Predicate, Supplier
  ToDoubleBiFunction, ToDoubleFunction, ToIntBiFunction, ToIntFunction
  ToLongBiFunction, ToLongFunction, UnaryOperator
```

Read the names as a grammar rather than a list:

| part of the name | meaning | example |
|---|---|---|
| `Int`, `Long`, `Double` in front | the **input** is that primitive | `IntPredicate` tests an `int` |
| `To...` in front | the **output** is that primitive | `ToIntFunction<T>` turns a `T` into an `int` |
| `...To...` in the middle | primitive in, another primitive out | `IntToDoubleFunction` |
| `Obj...Consumer` | an object and a primitive in | `ObjIntConsumer<T>` |
| `BooleanSupplier` | the one `boolean` that is not a `Predicate` | a supplier of `true` or `false` |

## Why they exist: generics take objects

A type argument must be a class, so `Function<Integer, Integer>` cannot take an `int`. Java fills
the gap by **boxing**: wrapping each `int` in an `Integer` object on the way in and unwrapping it
on the way out. Each wrap may be a new object on the heap, and in a loop over millions of numbers
that is millions of objects to create and collect. The primitive interfaces skip the wrapping:

```java
// Primitives.java: the same test, boxed and unboxed
import java.util.function.IntPredicate;
import java.util.function.Predicate;
import java.util.function.ToIntFunction;

public class Primitives {
    public static void main(String[] args) {
        Predicate<Integer> evenBoxed = n -> n % 2 == 0;
        IntPredicate even = n -> n % 2 == 0;
        ToIntFunction<String> length = s -> s.length();

        System.out.println(evenBoxed.test(10) + " " + even.test(10));
        System.out.println(length.applyAsInt("Ulysses"));

        Integer a = 1000;
        Integer b = 1000;
        System.out.println("two boxes of 1000 are the same object: " + (a == b));
    }
}
```

```
ana@vm:~/fp/interfaces$ java Primitives.java
true true
7
two boxes of 1000 are the same object: false
```

The two predicates answer the same, and `evenBoxed.test(10)` boxed the `10` to call it. The last
line is the proof that boxes are objects: two `Integer` values of 1000 are **two different
objects**, and `==` compares objects, not numbers (lesson 4 of `java` showed the same trap). The
method names change too, so that nobody mistakes one family for the other: `applyAsInt`, not
`apply`.

**Use the primitive interface when the values are numbers in a hot loop**, and do not bother
otherwise: one boxed call costs nanoseconds. Lesson 6 meets the same split in streams, where
`IntStream` exists for exactly this reason.
