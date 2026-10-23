---
title: Bound and unbound
version: 1
---

**`String::length` and `name::length` look alike and are different things.** The first is
unbound: it has no string yet and takes one as its argument, so its shape is
`Function<String, Integer>`. The second is bound: it already holds the string in `name`, takes
nothing, and its shape is `Supplier<Integer>`. Which one you have depends on whether a class or an
object is written before the `::`.

## Two arguments, one receiver

An unbound reference uses **its first argument as the object** and passes the rest to the method.
That is why `String::compareToIgnoreCase`, a method that takes one string, can be a
`Comparator<String>`, whose `compare` takes two:

```java
// Unbound.java: an unbound reference takes its object from the first argument
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.function.BiPredicate;

public class Unbound {
    public static void main(String[] args) {
        BiPredicate<String, String> sameIgnoringCase = String::equalsIgnoreCase;
        System.out.println(sameIgnoringCase.test("EMMA", "emma"));

        Comparator<String> byName = String::compareToIgnoreCase;
        List<String> authors = new ArrayList<>(List.of("woolf", "Austen", "eliot", "Brontë"));
        authors.sort(byName);
        System.out.println(authors);
    }
}
```

```
ana@vm:~/fp/references$ java Unbound.java
true
[Austen, Brontë, eliot, woolf]
```

`compare(a, b)` became `a.compareToIgnoreCase(b)`, and the authors sorted without regard to case.

## When the object is chosen

A bound reference **evaluates what is before the `::` once, when the reference is made**. A lambda
evaluates its body each time it runs. With a value that changes, the two give different answers:

```java
// Bound.java: a bound reference fixes its receiver when it is made; a lambda reads it when it runs
import java.util.function.Supplier;

public class Bound {
    static String current = "Dune";

    public static void main(String[] args) {
        Supplier<Integer> ref = current::length;
        Supplier<Integer> lambda = () -> current.length();
        current = "One Hundred Years of Solitude";
        System.out.println("reference: " + ref.get());
        System.out.println("lambda:    " + lambda.get());

        current = null;
        Supplier<Integer> later = () -> current.length();
        System.out.println("the lambda was made without complaint");
        Supplier<Integer> now = current::length;
        System.out.println("never printed");
    }
}
```

```
ana@vm:~/fp/references$ java Bound.java
reference: 4
lambda:    29
the lambda was made without complaint
Exception in thread "main" java.lang.NullPointerException
	at java.base/java.util.Objects.requireNonNull(Objects.java:220)
	at Bound.main(Bound.java:17)
```

**The reference printed 4, the length of `"Dune"`**, because it took the string out of `current`
when it was made, before the assignment. The lambda printed 29, because it read the field when it
ran. `current` is a static field here so that the lambda may read it after a change; a local
variable would have been refused, as lesson 1 section 06 showed.

The second half is the same rule with a `null`. The lambda that reads a `null` field was made
without complaint and would fail only if somebody called it. **The bound reference failed on the
line that made it**: the stack trace points at line 17 and at `Objects.requireNonNull`, the check
the compiler put in front of every bound reference. That is a better place to fail, since it names
the line where the `null` went in, not some later line where it came out.
