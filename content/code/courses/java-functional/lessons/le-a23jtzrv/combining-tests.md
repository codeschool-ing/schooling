---
title: Combining tests
version: 1
---

**`Predicate` has `and`, `or` and `negate`, and each returns a new predicate.** They are the `&&`,
`||` and `!` of the language, applied to tests rather than to answers, so a rule can be assembled
from named parts and passed around before anything is tested.

```java
// Tests.java: predicates combined, and the order they are evaluated in
import java.util.List;
import java.util.function.Predicate;

public class Tests {
    record Book(String title, int pages, long priceCents) {}

    static Predicate<Book> noisy(String name, Predicate<Book> p) {
        return b -> {
            boolean answer = p.test(b);
            System.out.println("  " + name + "(" + b.title() + ") = " + answer);
            return answer;
        };
    }

    public static void main(String[] args) {
        Predicate<Book> cheap = b -> b.priceCents() < 4000;
        Predicate<Book> doorstop = b -> b.pages() > 450;
        Book emma = new Book("Emma", 474, 3990);
        Book dune = new Book("Dune", 412, 6990);

        System.out.println("cheap and doorstop, Emma: " + cheap.and(doorstop).test(emma));
        System.out.println("cheap or doorstop, Dune:  " + cheap.or(doorstop).test(dune));
        System.out.println("not cheap, Dune:          " + cheap.negate().test(dune));

        System.out.println("evaluating cheap.and(doorstop) on Dune:");
        System.out.println(noisy("cheap", cheap).and(noisy("doorstop", doorstop)).test(dune));

        List<String> lines = List.of("Emma", "", "  ", "Dune");
        System.out.println(lines.stream().filter(Predicate.not(String::isBlank)).toList());
    }
}
```

```
ana@vm:~/fp/composition$ java Tests.java
cheap and doorstop, Emma: true
cheap or doorstop, Dune:  false
not cheap, Dune:          true
evaluating cheap.and(doorstop) on Dune:
  cheap(Dune) = false
false
[Emma, Dune]
```

The first three lines are the plain cases: Emma is both cheap and long, Dune is neither cheap nor
long so `or` is `false`, and `negate` turned "cheap" into "not cheap".

## They stop as soon as they know

The fourth case wrapped each predicate in `noisy`, which prints every time it runs. **Only `cheap`
printed.** Dune is not cheap, so `cheap.and(doorstop)` was already `false`, and `doorstop` was never
called. `and` and `or` short-circuit exactly like `&&` and `||`: `and` stops at the first `false`,
`or` at the first `true`. Two consequences:

- **put the cheap test first.** A rule that checks a field before it queries a database saves the
  query every time the field already says no;
- **do not rely on the second test running.** A predicate that also records or counts something
  will skip that work whenever the first one decides. That is one more reason to keep tests free of
  side effects (lesson 4 section 02).

## `Predicate.not`

`negate()` needs a predicate to call it on, and `String::isBlank` is a method reference with no type
until it has a target. `Predicate.not(String::isBlank)` gives it one and flips it in a single
expression, which is why it reads so well inside a `filter`. The last line used it on a stream to
drop the empty and the blank lines; lesson 6 explains streams, and the predicate inside is all this
section needs.
