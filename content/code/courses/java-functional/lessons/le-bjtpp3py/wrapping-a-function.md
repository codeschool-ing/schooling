---
title: A function that improves a function
version: 1
---

**The most useful higher-order functions take a function and return another one with the same
shape and something added.** The caller sees a `Function<T, R>` going in and a `Function<T, R>`
coming out, and the new one can be used everywhere the old one was. Two additions come up all the
time: saying what happened, and not doing the same work twice.

```java
// Wrappers.java: two functions that take a function and return a better one
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

public class Wrappers {
    static int lookups = 0;

    static <T, R> Function<T, R> logged(String name, Function<T, R> f) {
        return t -> {
            R result = f.apply(t);
            System.out.println("  " + name + "(" + t + ") = " + result);
            return result;
        };
    }

    static <T, R> Function<T, R> memoized(Function<T, R> f) {
        Map<T, R> cache = new HashMap<>();
        return t -> cache.computeIfAbsent(t, f);
    }

    static String authorOf(String title) {
        lookups++;
        return switch (title) {
            case "Dune" -> "Frank Herbert";
            case "Emma" -> "Jane Austen";
            default -> "unknown";
        };
    }

    public static void main(String[] args) {
        Function<String, String> author = memoized(logged("authorOf", Wrappers::authorOf));
        for (String title : new String[] {"Dune", "Emma", "Dune", "Dune", "Ulysses"}) {
            System.out.println(title + " by " + author.apply(title));
        }
        System.out.println("lookups: " + lookups);
    }
}
```

```
ana@vm:~/fp/higher-order$ java Wrappers.java
  authorOf(Dune) = Frank Herbert
Dune by Frank Herbert
  authorOf(Emma) = Jane Austen
Emma by Jane Austen
Dune by Frank Herbert
Dune by Frank Herbert
  authorOf(Ulysses) = unknown
Ulysses by unknown
lookups: 3
```

Read the output from the inside out. **`logged` printed a line only when the real lookup ran**, and
it ran three times for five questions: `Dune` was asked three times and looked up once. The
counter agrees, `lookups: 3`. That is because the two wrappers were stacked:
`memoized(logged(...))` checks the cache first, and only a miss reaches the logged function and,
inside it, `authorOf`. Swap them, `logged(memoized(...))`, and every call would be logged, hits
included. **The order of wrappers is the order of the questions asked**, outermost first.

## What `memoized` relies on

`computeIfAbsent(t, f)` calls `f` only when the key is missing, and stores the answer. It is only a
correct cache when `f` **gives the same answer every time for the same argument and does nothing
else that matters**. `authorOf` qualifies, apart from the counter that is there to be counted. A
function that reads the clock, a file or a database does not, and memoizing it serves stale
answers with no sign that they are stale.

The cache is also unbounded and not safe for two threads at once. For one program working through
a list, that is fine. For a server, it is the start of a memory leak and a race, and lesson 15's
`ConcurrentHashMap` is the first half of the cure.

## The same shape everywhere

This is the decorator pattern without the classes. A wrapper that adds a retry, a timeout, a
permission check or a measurement is written the same way: take a `Function`, return a `Function`
that does its extra work around a call to the one it was given. Libraries for web servers and
resilience are built out of exactly this, which is why reading the type `Function<T, R>` in a
parameter and again in the return type tells you most of what the method does.
