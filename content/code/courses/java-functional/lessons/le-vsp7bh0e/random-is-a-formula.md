---
title: Random is a formula
version: 1
---

**`java.util.Random` does not produce chance; it produces a sequence computed from a starting number,
the seed.** Each number comes from the one before by the same arithmetic, so the same seed always gives
the same sequence:

```java
// Dice.java: java.util.Random is a formula, and the same seed gives the same numbers
import java.util.Random;
import java.util.stream.Collectors;

public class Dice {
    public static void main(String[] args) {
        System.out.println("seed 2026: " + rolls(new Random(2026)));
        System.out.println("seed 2026: " + rolls(new Random(2026)));
        System.out.println("no seed:   " + rolls(new Random()));
    }

    static String rolls(Random random) {
        return random.ints(10, 1, 7).mapToObj(String::valueOf).collect(Collectors.joining(" "));
    }
}
```

```
ana@vm:~/fp/secrets$ java Dice.java
seed 2026: 6 5 2 1 4 5 6 5 5 1
seed 2026: 6 5 2 1 4 5 6 5 5 1
no seed:   5 3 4 4 5 2 1 2 5 1
```

## Where that helps and where it does not

The two seeded runs rolled the same ten dice, and **they will roll them again on every machine, on every
run**. That is exactly what a simulation, a test or a game that wants to replay a level needs. With no
seed, `Random` chose one from the clock and a counter, and the rolls were different, but only because the
starting point was; the arithmetic after it is the same.

That arithmetic is the problem for anything secret. `Random` keeps 48 bits of state, and each number it
returns gives away part of that state, so **somebody who sees a few of its outputs can work out the rest,
the ones before and the ones after**. A password-reset link, a session identifier or a coupon code made
with `Random` is a code whose neighbours can be computed by anybody who has received one.

| class | numbers from | use for |
|---|---|---|
| `Random` | a formula and a seed | simulations, tests, games that replay |
| `ThreadLocalRandom` | the same kind of formula, one per thread | the same, from many threads at once |
| `SecureRandom` | the operating system's source of randomness | anything that must not be guessed |

`ThreadLocalRandom.current()` is `Random` made for lessons 11 to 18: each thread has its own, so threads
do not wait for one another. It is just as predictable. **Neither is a source of secrets**; the next
section is.
