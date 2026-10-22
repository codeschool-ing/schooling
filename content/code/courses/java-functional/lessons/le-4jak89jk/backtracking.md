---
title: The cost of backtracking
version: 1
---

**Java's regular expressions work by trying: when one way of matching fails, the engine goes back and
tries another, and it stops only when it has found a match or run out of ways.** That is called
backtracking, and for most patterns the ways run out quickly. For some, the number of ways to divide the
text grows with every letter, and a pattern that answers instantly on a test line takes seconds, then
minutes, on a slightly longer one. Four patterns that describe the same strings, timed on text that almost
matches:

```java
// Backtrack.java: four patterns for the same text, timed on input that almost matches
import java.util.regex.Pattern;

public class Backtrack {
    public static void main(String[] args) {
        Pattern plain = Pattern.compile("a+b");
        Pattern nested = Pattern.compile("(a+)+b");
        Pattern twice = Pattern.compile("((a+)+)+b");
        Pattern possessive = Pattern.compile("((a++)+)+b");
        for (int n = 16; n <= 28; n += 4) {
            String input = "a".repeat(n) + "c";
            System.out.printf("%d letters   a+b %d ms   (a+)+b %d ms   ((a+)+)+b %5d ms   ((a++)+)+b %d ms%n",
                    n, time(plain, input), time(nested, input), time(twice, input), time(possessive, input));
        }
    }

    static long time(Pattern pattern, String input) {
        long start = System.nanoTime();
        pattern.matcher(input).matches();
        return (System.nanoTime() - start) / 1_000_000;
    }
}
```

```
ana@vm:~/fp/regex$ java Backtrack.java
16 letters   a+b 0 ms   (a+)+b 0 ms   ((a+)+)+b     7 ms   ((a++)+)+b 0 ms
20 letters   a+b 0 ms   (a+)+b 0 ms   ((a+)+)+b    56 ms   ((a++)+)+b 0 ms
24 letters   a+b 0 ms   (a+)+b 0 ms   ((a+)+)+b   674 ms   ((a++)+)+b 0 ms
28 letters   a+b 0 ms   (a+)+b 0 ms   ((a+)+)+b 10813 ms   ((a++)+)+b 0 ms
```

## Why one pattern exploded

All four describe the same thing: some `a`s and then a `b`. The input has the `a`s and ends in `c`, so
none of them can match, and the question is how long each takes to find that out.

`a+b` took nothing: the `a`s are taken, the `b` is missing, done. **`((a+)+)+b` went from 7 ms at sixteen
letters to almost eleven seconds at twenty-eight.** Before it can give up, it has to try every way of
splitting the run of `a`s between the three nested repetitions, ten letters as one group and eighteen as
another, or as three and twenty-five, and so on, and the number of ways roughly doubles with every letter.
Every four letters multiplied the time by eight to sixteen, so a line of forty letters would take hours,
from one call.

`(a+)+b` took nothing, though it is the textbook example of this problem. **The JDK's engine recognises
that simplest shape and avoids the repeated work**, which is why it is no longer a good test, and why the
one level more is: an optimisation that covers the common case is not a guarantee for every pattern.

## The cures

The last column is the first cure: `a++` is a **possessive** quantifier, which takes as many `a`s as it
can and never gives any back, so there is nothing to retry. `(?>...)`, an atomic group, does the same for
a whole group. The better cure is usually the first column: **write the pattern so that each piece of
text can be matched only one way**. Nested repetitions of the same thing, `(x+)+`, and alternatives that
can match the same text, `(a|a)+`, are the shapes to rewrite.

This matters most where the text comes from outside. A server that runs a pattern like the third on each
request can be stopped by anybody who sends a request with thirty `a`s and a `c`, with no flood of
traffic, just one patient request per thread. That attack has a name, ReDoS, and the defence is in the
pattern, before any request arrives. The next section is the other half of it.
