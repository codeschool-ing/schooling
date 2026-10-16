---
title: What type an expression has
version: 1
---

Section 02 converted values as they were assigned. The same thing happens **inside an expression**,
and there the rules surprise people, because they decide the type of a result before it is stored
anywhere. Two rules cover nearly everything:

1. **Arithmetic is never done on `byte`, `short` or `char`.** Each is widened to `int` first, so
   the result is at least an `int`.
2. **If either side is wider, the other is widened to match.** `int` with `long` gives a `long`,
   anything with `double` gives a `double`.

The first rule makes a sum of two `byte`s an `int`, and an `int` does not go into a `byte` without
a cast:

```java
// SmallSum.java
public class SmallSum {
    public static void main(String[] args) {
        byte morning = 10;
        byte afternoon = 20;
        byte total = morning + afternoon;
        System.out.println(total);
    }
}
```

```
ana@vm:~/convert$ javac SmallSum.java
SmallSum.java:6: error: incompatible types: possible lossy conversion from int to byte
        byte total = morning + afternoon;
                             ^
1 error
```

10 plus 20 fits comfortably in a `byte`, and the compiler refuses anyway, for the same reason as in
section 03: it looks at types, and `morning + afternoon` is an `int`. `byte total = (byte)
(morning + afternoon);` compiles. So does making `total` an `int`, which is the usual fix.

## Eight results, eight rules

```java
// Promote.java
public class Promote {
    public static void main(String[] args) {
        byte stock = 10;
        stock += 300;
        System.out.println(stock);
        System.out.println(7 / 2);
        System.out.println(7 / 2.0);
        int pages = 7;
        double half = pages / 2;
        System.out.println(half);
        char letter = 'A';
        System.out.println(letter + 1);
        System.out.println((char) (letter + 1));
        System.out.println("total: " + 1 + 2);
        System.out.println(1 + 2 + " total");
    }
}
```

```
ana@vm:~/convert$ java Promote.java
54
3
3.5
3.0
66
B
total: 12
3 total
```

Line by line:

- **`stock += 300` printed 54.** The compound operators, `+=`, `-=` and the rest, include a hidden
  cast back to the variable's type. `stock + 300` is 310, an `int`, and the hidden `(byte)` kept its
  low bits, as `(byte) 200` did in section 03. `stock = stock + 300;` would have been refused; the
  shorter form compiles and is wrong.
- **`7 / 2` printed 3.** Both sides are `int`, so it is integer division and the fraction is cut off.
  `7 / 2.0` printed 3.5, because one side is a `double` and the other was widened.
- **`double half = pages / 2` printed 3.0**, not 3.5. The type of the variable does not reach into
  the expression: `pages / 2` is computed as `int` division, gives 3, and only then is 3 widened to
  `3.0`. Write `pages / 2.0`.
- **`letter + 1` printed 66**: the `char` became an `int` for the arithmetic. `(char) (letter + 1)`
  cast it back and printed `B`.
- **`"total: " + 1 + 2` printed `total: 12`**, and `1 + 2 + " total"` printed `3 total`. `+` with a
  `String` on either side joins text, and Java evaluates left to right: in the first, `"total: " + 1`
  is already a `String`, so `2` is joined to it; in the second, `1 + 2` is added as numbers first.

Most of these are silent. **Nothing warns about `pages / 2` or `stock += 300`**, so the habit to build
is to know the type of every expression you write, and lesson 8 adds the operators that go with it.
