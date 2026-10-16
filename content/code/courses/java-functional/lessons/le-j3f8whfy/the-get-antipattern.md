---
title: The get() antipattern, and where Optional does not belong
version: 1
---

**`get()` opens the box and returns the value, and throws when the box is empty.** That makes it the
one method that brings back exactly the failure `Optional` was meant to remove. It has a polite
cousin, the pair `isPresent()` then `get()`, which is safe and is `null` checking in a new costume:

```java
// Antipattern.java: get, the isPresent-get pair, and the version that needs neither
import java.util.Optional;

public class Antipattern {
    public static void main(String[] args) {
        Optional<Catalogue.Edition> found = Catalogue.find("Dom Casmurro");
        if (found.isPresent()) {
            System.out.println("checked: " + found.get().author());
        }
        System.out.println("chained: " + found.map(Catalogue.Edition::author).orElse("nobody"));

        Optional<Catalogue.Edition> missing = Catalogue.find("Moby-Dick");
        System.out.println(missing.get().author());
    }
}
```

```
ana@vm:~/fp/optional$ java Antipattern.java
checked: Machado de Assis
chained: Machado de Assis
Exception in thread "main" java.util.NoSuchElementException: No value present
	at java.base/java.util.Optional.get(Optional.java:143)
	at Antipattern.main(Antipattern.java:13)
```

The checked version works, and it is five lines doing what the chained version does in one. **The
unchecked `get()` failed with `NoSuchElementException: No value present`**, on line 13, which tells
you less than the `NullPointerException` it replaced: not even which value was missing. The method's
own documentation recommends `orElseThrow()` in its place, which does the same thing and says in its
name that it may throw. When an empty box really is a bug, write that:
`find(title).orElseThrow(() -> new IllegalStateException("no edition called " + title))` fails with a
message somebody can act on.

## Where `Optional` belongs

`Optional` was designed for one job: **a method's return type, when the method may have no result**.
It is a poor fit almost everywhere else:

| use | why not | instead |
|---|---|---|
| a field, `Optional<String> translator` | it is not serializable, adds an object per field, and the field can still be `null` itself | a nullable field, and an accessor that returns `Optional.ofNullable(field)` |
| a parameter, `void ship(Optional<Address> a)` | every caller must wrap, and a caller can still pass `null` | an overload without the parameter, or a nullable parameter documented as such |
| an element of a collection, `List<Optional<Book>>` | a list can simply leave the missing ones out | filter them out with `flatMap(Optional::stream)` |
| `Optional<List<Book>>` | "no books" already has a value: the empty list | return the empty list |

And one rule without exceptions: **a method that returns `Optional` never returns `null`**. A caller
who receives `null` where an `Optional` was promised gets the `NullPointerException` the type was
supposed to rule out, from the one place nobody would think to check.
