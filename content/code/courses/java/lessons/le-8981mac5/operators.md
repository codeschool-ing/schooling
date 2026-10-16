---
title: Operators, and the two that surprise
version: 1
---

Java's arithmetic operators are the ones from school, `+ - * /`, plus `%` for the remainder. Two of
them do something different from a calculator, and **both differences come from the types of the
operands, not from the operator**. Make a directory for this lesson, `~/maths`, and save this as
`Operators.java`:

```java
// Operators.java
public class Operators {
    public static void main(String[] args) {
        System.out.println(7 / 2);
        System.out.println(7.0 / 2);
        System.out.println(7 % 3);
        System.out.println(-7 % 3);
        System.out.println(7 % -3);

        int i = 5;
        int a = i++;
        int b = ++i;
        System.out.println(a + " " + b + " " + i);

        System.out.println(2 + 3 * 4);
        System.out.println((2 + 3) * 4);
        System.out.println(10 - 4 - 3);

        int big = Integer.MAX_VALUE;
        System.out.println(big + 1);
        System.out.println(Math.addExact(big, 1));
    }
}
```

```
ana@vm:~/maths$ java Operators.java; echo $?
3
3.5
1
-1
1
5 7 7
14
20
3
-2147483648
Exception in thread "main" java.lang.ArithmeticException: integer overflow
	at java.base/java.lang.Math.addExact(Math.java:915)
	at Operators.main(Operators.java:21)
1
```

Line by line, against what a calculator would say:

| expression | printed | why |
|---|---|---|
| `7 / 2` | `3` | **both operands are `int`, so the division is integer division**: the fraction is thrown away |
| `7.0 / 2` | `3.5` | one operand is a `double`, so the other is widened and the division keeps its fraction |
| `7 % 3` | `1` | the remainder of 7 divided by 3 |
| `-7 % 3` | `-1` | **the remainder takes the sign of the left operand** |
| `7 % -3` | `1` | the sign of the right operand does not matter |
| `a`, `b`, `i` | `5 7 7` | `i++` gives the old value then adds one; `++i` adds one then gives the new value |
| `2 + 3 * 4` | `14` | `*` binds tighter than `+` |
| `(2 + 3) * 4` | `20` | brackets first |
| `10 - 4 - 3` | `3` | operators of equal rank go left to right: `(10 - 4) - 3` |
| `big + 1` | `-2147483648` | the largest `int` plus one wraps round to the smallest |

## Integer division throws the fraction away

`7 / 2` is `3` and not `3.5` because Java decides the kind of division before it looks at the
values. **Two `int`s give an `int`**, and an `int` has nowhere to keep `.5`. It is truncated, which
means cut towards zero, so `-7 / 2` is `-3`, and section 03 shows the method that rounds down
instead. The usual bug is an average: `sum / count` with two `int`s, where the fix is to make one of
them a `double` before dividing, `(double) sum / count`, a cast
lesson 6 explains.

The remainder follows the same rule. `-7 % 3` is `-1`, because `-7 / 3` is `-2` and `-2 * 3 + -1`
gives back `-7`. A test like `n % 2 == 1` to find odd numbers is therefore **wrong for negative
numbers**: `-7 % 2` is `-1`. Write `n % 2 != 0`.

## `i++` and `++i`

Both add one to `i`. They differ only in the value the expression has, which matters when it is
used inside a larger one. `a = i++` copied the old 5 into `a` and then made `i` 6; `b = ++i` made
`i` 7 and copied the 7. **On a line of its own, `i++;` and `++i;` are the same statement**, and a
loop counter is the only place most code needs either. Code that uses the value of `i++` inside
another expression is code the next reader has to stop and work out.

## Overflow does not stop the program

`Integer.MAX_VALUE + 1` printed `-2147483648`. Lesson 4 explained why: an `int` has 32 bits, and
the arithmetic wraps round, from the largest value to the smallest, **with no error and no
warning**. A counter of milliseconds or a sum of prices can cross that line quietly and turn
negative.

When the answer must be right or not at all, the `Math` class has exact versions that refuse:
`Math.addExact`, `subtractExact`, `multiplyExact` and `toIntExact`. The last line of the program
asked for one and the program stopped with `ArithmeticException: integer overflow`, pointing at
line 21, and exit status 1. **A crash you can see is better than a negative balance you cannot.**
The other remedy is a wider type: `long` holds values up to about nine quintillion, which is room
for any count of things in a library.
