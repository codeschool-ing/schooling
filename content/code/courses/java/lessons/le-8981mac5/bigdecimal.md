---
title: Money, with `BigDecimal` or with cents
version: 1
---

Section 04 showed why a `double` is the wrong place for a fine of R$ 12.30: the value stored is
not 12.30 but the nearest binary fraction, and sums drift. Money needs exact decimal arithmetic and
a stated rule for rounding. Java offers two sound ways to have both: **`BigDecimal`, a decimal number
of any size, or a `long` counting cents.**

```java
// Money.java
import java.math.BigDecimal;
import java.math.RoundingMode;

public class Money {
    public static void main(String[] args) {
        System.out.println(new BigDecimal(0.1));
        System.out.println(new BigDecimal("0.1"));

        BigDecimal a = new BigDecimal("0.10");
        BigDecimal b = new BigDecimal("0.20");
        BigDecimal sum = a.add(b);
        System.out.println(sum);
        System.out.println(sum.equals(new BigDecimal("0.3")));
        System.out.println(sum.compareTo(new BigDecimal("0.3")) == 0);

        BigDecimal fine = new BigDecimal("2.345");
        System.out.println(fine.setScale(2, RoundingMode.HALF_UP));
        System.out.println(fine.setScale(2, RoundingMode.HALF_EVEN));

        BigDecimal ten = new BigDecimal("10.00");
        System.out.println(ten.divide(new BigDecimal("3"), 2, RoundingMode.HALF_EVEN));
        System.out.println(ten.divide(new BigDecimal("3")));
    }
}
```

```
ana@vm:~/maths$ java Money.java
0.1000000000000000055511151231257827021181583404541015625
0.1
0.30
false
true
2.35
2.34
3.33
Exception in thread "main" java.lang.ArithmeticException: Non-terminating decimal expansion; no exact representable decimal result.
	at java.base/java.math.BigDecimal.divide(BigDecimal.java:1810)
	at Money.main(Money.java:23)
```

## Build it from a string, never from a `double`

The first line is the trap. `new BigDecimal(0.1)` was given a `double`, so it faithfully recorded
the binary fraction the `double` held, all 55 digits of it. **`new BigDecimal("0.1")` was given the
text**, and holds exactly one tenth. The rule follows: a `BigDecimal` is built from a `String`, or
from a whole number, and the error never gets in.

## Scale is part of the value

A `BigDecimal` is a whole number and a **scale**, the count of digits after the point. `0.10` is
10 with scale 2, and the sum of `0.10` and `0.20` printed `0.30`, keeping the scale. That is why
the next line printed `false`: **`equals` compares the scale too**, and `0.30` is not `0.3`. When
the question is "the same amount?", use `compareTo(...) == 0`, which ignores the scale and printed
`true`.

## Rounding is a rule you choose

`setScale(2, ...)` cuts a value to two places, and the second argument says how. The fine of
`2.345` sits exactly halfway between `2.34` and `2.35`:

| rule | `2.345` became | what it does with a half |
|---|---|---|
| `RoundingMode.HALF_UP` | `2.35` | goes away from zero, the rule taught at school |
| `RoundingMode.HALF_EVEN` | `2.34` | goes to the even neighbour, so halves do not all push the same way |

`HALF_EVEN` is called banker's rounding, and over thousands of halves it adds up to no bias. Which
one is right is a business decision, written in a contract or a law, and **the code has to say it
out loud**. Division forces the choice: `10.00` divided by `3` with two places and `HALF_EVEN` gave
`3.33`, and without a rounding rule the last line stopped the program with
`ArithmeticException: Non-terminating decimal expansion`. A third has no end in decimal, and
`BigDecimal` refuses to guess where to cut it.

## Or count cents in a `long`

When every amount has the same two decimal places, an integer number of cents is exact, fast and
simple. Addition cannot drift, and the only formatting happens at the edge, when a person reads it:

```java
// Cents.java
public class Cents {
    public static void main(String[] args) {
        long fine = 1050;
        long fee = 2075;
        long total = fine + fee;
        System.out.printf("R$ %d,%02d%n", total / 100, total % 100);

        long bill = 1000;
        long share = bill / 3;
        long left = bill % 3;
        System.out.println(share + " " + share + " " + (share + left));
    }
}
```

```
ana@vm:~/maths$ java Cents.java
R$ 31,25
333 333 334
```

`1050 + 2075` is `3125` cents, printed as `R$ 31,25` by splitting it into reais, `total / 100`, and
cents, `total % 100`, padded to two digits with `%02d`. Splitting a bill three ways shows the one
thing integers make you decide: **1000 cents do not divide by 3**, the remainder is 1, and some
instalment has to carry the extra cent. Here it went on the last, `333 333 334`, and the three add
back to 1000. Dropping it would lose a cent on every bill, silently.
