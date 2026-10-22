---
title: "`finally`: the block that runs on every way out"
version: 1
---

A method can leave in several ways: by reaching its end, by `return`, or by an exception passing
through it. Some work has to happen on all of them. A ledger opened must be closed, whether the
loan went through or not. **A `finally` block runs whenever control leaves its `try`**, by any of
those routes, and that is the whole of what it is for.

The program below opens and closes an imaginary ledger, and then shows the two places where
`finally` behaves in a way nobody expects the first time:

```java
// Always.java
public class Always {
    static String lend(String title) {
        System.out.println("open the ledger");
        try {
            if (title.isBlank()) {
                throw new IllegalArgumentException("no title");
            }
            System.out.println("lend " + title);
            return "lent";
        } finally {
            System.out.println("close the ledger");
        }
    }

    @SuppressWarnings("finally")
    static String swallow() {
        try {
            throw new IllegalStateException("the real problem");
        } finally {
            return "all fine";
        }
    }

    public static void main(String[] args) {
        System.out.println(lend("Dune"));
        try {
            lend(" ");
        } catch (IllegalArgumentException e) {
            System.out.println("caught: " + e.getMessage());
        }
        System.out.println(swallow());
        try {
            System.out.println("exiting");
            System.exit(0);
        } finally {
            System.out.println("this line never prints");
        }
    }
}
```

```
ana@vm:~/exc$ java Always.java; echo "exit $?"
open the ledger
lend Dune
close the ledger
lent
open the ledger
close the ledger
caught: no title
all fine
exiting
exit 0
```

## Every way out

The first call returned normally. `close the ledger` printed **after** `lend Dune` and **before** the
caller printed `lent`: the `return "lent"` was evaluated, then the `finally` ran, then the method
actually returned. A `return` inside a `try` does not skip the `finally`; it waits for it.

The second call threw. `close the ledger` printed before `caught: no title`, so the `finally` ran
while the exception was on its way out, and the exception carried on to `main`'s `catch`
afterwards. **The ledger was closed on both routes**, which is the property that makes `finally` the
place for cleanup. Lesson 37 replaces this pattern with a shorter one for anything that can be
closed, and the reason it can is this block.

## A `return` in `finally` swallows the exception

`swallow()` threw `IllegalStateException("the real problem")`, and the program printed `all fine`.
**A `return` inside `finally` replaces whatever was leaving the method**, an exception included, and
the exception disappears without a trace: no stack trace, no message, nothing in a log.

The compiler knows this is almost always a mistake and warns about it with `-Xlint:finally`; the
`@SuppressWarnings("finally")` above the method is there only so that this demonstration compiles
quietly, and lesson 39 explains the annotation. In your own code, never `return` from a `finally`,
and never `throw` from one either, which replaces the original exception in the same way.

## The one exit `finally` does not see

The last `try` called `System.exit(0)`, and `this line never prints` never printed; the exit status
was 0. **`System.exit` stops the JVM, and a stopped JVM runs no more code**, `finally` blocks
included. The same holds if the process is killed from outside, or the machine loses power. A
`finally` guarantees cleanup for every way the *method* ends, not for every way the *program* does.
