---
title: Making an Optional
version: 1
---

**`Optional<T>` is a container that holds one value of type `T` or nothing.** A method that returns
`Optional<Edition>` says in its signature that it may find no edition, and the compiler makes the
caller deal with the box before reaching the value inside. `Catalogue.find` returns one; `findFirst`,
`max` and `reduce` in lessons 6 to 8 returned one for the same reason.

Three factory methods make one:

```java
// Making.java: of, ofNullable and empty, and the one that refuses null
import java.util.Optional;

public class Making {
    public static void main(String[] args) {
        Optional<String> some = Optional.of("Machado de Assis");
        Optional<String> none = Optional.empty();
        Optional<String> maybe = Optional.ofNullable(Catalogue.findOrNull("Dom Casmurro").translator());
        System.out.println(some + " " + none + " " + maybe);
        System.out.println(some.isPresent() + " " + none.isEmpty());

        System.out.println(Catalogue.find("Dom Casmurro"));
        System.out.println(Catalogue.find("Moby-Dick"));

        Optional<String> broken = Optional.of(Catalogue.findOrNull("Dom Casmurro").translator());
    }
}
```

```
ana@vm:~/fp/optional$ java Making.java
Optional[Machado de Assis] Optional.empty Optional.empty
true true
Optional[Edition[title=Dom Casmurro, author=Machado de Assis, translator=null, priceCents=3490]]
Optional.empty
Exception in thread "main" java.lang.NullPointerException
	at java.base/java.util.Objects.requireNonNull(Objects.java:220)
	at java.base/java.util.Optional.of(Optional.java:113)
	at Making.main(Making.java:15)
```

| factory | gives | use it when |
|---|---|---|
| `Optional.of(value)` | a box holding `value`; **throws** if `value` is `null` | you know the value is there |
| `Optional.ofNullable(value)` | a box holding `value`, or an empty box if it is `null` | the value comes from code that uses `null` for nothing |
| `Optional.empty()` | an empty box | there is nothing to return |

`ofNullable` is the bridge from old code to new: the translator field still holds `null`, and
`ofNullable` turned that into `Optional.empty`. **`of` refuses `null` on purpose.** The last line
called it with the same `null`, and it failed at once, on line 15, inside `Objects.requireNonNull`.
That is the right place to fail: a programmer who wrote `of` was saying "this is never `null`", and
the program stopped at the moment that turned out to be false.

`Catalogue.find("Moby-Dick")` printed `Optional.empty`. The caller learns nothing new from the value,
but learns everything from the type: there was never a way to read `find`'s result as an edition
without first deciding what to do when there is none.
