---
title: Narrowing, and the cast that says you meant it
version: 1
---

Going the other way, from a larger type to a smaller one, can lose the value entirely. **Java
refuses to do it silently**: assigning a `double` to an `int` is a compile error, even when the
number would fit.

```java
// Lossy.java
public class Lossy {
    public static void main(String[] args) {
        double price = 3.99;
        int whole = price;
        System.out.println(whole);
    }
}
```

```
ana@vm:~/convert$ javac Lossy.java
Lossy.java:5: error: incompatible types: possible lossy conversion from double to int
        int whole = price;
                    ^
1 error
```

The message names the risk, `possible lossy conversion`, not a certainty: the compiler does not look
at `3.99`, only at the types. To convert anyway you write a **cast**, the target type in parentheses
in front of the value, `(int) price`. A cast is you telling the compiler that you know a value may be
lost and you accept it. What exactly is lost depends on the conversion:

```java
// Narrow.java
public class Narrow {
    public static void main(String[] args) {
        double price = 3.99;
        System.out.println((int) price);
        System.out.println((int) -3.99);
        System.out.println((byte) 200);
        System.out.println((int) 1e20);
        System.out.println((int) Double.NaN);
        System.out.println(Math.round(3.99));
        System.out.println(Math.round(-2.5));
        System.out.println(Math.toIntExact(3_000_000_000L));
    }
}
```

```
ana@vm:~/convert$ java Narrow.java
3
-3
-56
2147483647
0
4
-2
Exception in thread "main" java.lang.ArithmeticException: integer overflow
	at java.base/java.lang.Math.toIntExact(Math.java:1375)
	at Narrow.main(Narrow.java:12)
```

Each line is a different rule, and none of them is rounding:

| expression | printed | the rule |
|---|---|---|
| `(int) 3.99` | `3` | a decimal to a whole number **cuts off the fraction**, towards zero |
| `(int) -3.99` | `-3` | towards zero, so up for a negative number, not down to -4 |
| `(byte) 200` | `-56` | a whole number to a smaller one **keeps the low bits**: 200 is 256 too many for a `byte`, minus 256 is -56 |
| `(int) 1e20` | `2147483647` | a decimal too large for the target **stops at its largest value** |
| `(int) Double.NaN` | `0` | not-a-number, lesson 8's subject, becomes 0 |

The cast never fails. **It always produces a number, and sometimes a wrong one**, with nothing on
the screen to say which. Two methods of `Math` say more about what you want.

`Math.round` rounds to the nearest whole number, so 3.99 became 4. Halves go up, towards positive
infinity, which is why `Math.round(-2.5)` gave -2 and not -3. `Math.round` of a `double` returns a
`long`, so it still needs a cast to fit in an `int`.

`Math.toIntExact` takes a `long` and gives the `int` only if it fits. 3,000,000,000 does not, so it
threw `ArithmeticException: integer overflow` and the program stopped on line 12. That is the
behaviour to want when a wrong number would be worse than no number: **an exception you see beats a
value that is silently wrong**.
