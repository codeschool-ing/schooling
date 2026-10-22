---
title: Eight primitive types, and what each can hold
version: 1
---

Python and JavaScript let a variable hold anything and work out what it is when the program runs.
**Java decides the type of every variable when it compiles**, and the type fixes two things for
good: which values the variable can hold, and how many bits of memory each one takes. Most types in
Java are classes, which lesson 12 begins. Eight are not. They are the **primitive types**, built
into the language, and every number, character and true-or-false in a Java program is one of them
underneath.

A program that asks each one for its size and its limits, in `~/types`:

```java
// Ranges.java
public class Ranges {
    public static void main(String[] args) {
        System.out.println("byte   " + Byte.SIZE + " bits, " + Byte.MIN_VALUE + " to " + Byte.MAX_VALUE);
        System.out.println("short  " + Short.SIZE + " bits, " + Short.MIN_VALUE + " to " + Short.MAX_VALUE);
        System.out.println("int    " + Integer.SIZE + " bits, " + Integer.MIN_VALUE + " to " + Integer.MAX_VALUE);
        System.out.println("long   " + Long.SIZE + " bits, " + Long.MIN_VALUE + " to " + Long.MAX_VALUE);
        System.out.println("float  " + Float.SIZE + " bits, largest " + Float.MAX_VALUE);
        System.out.println("double " + Double.SIZE + " bits, largest " + Double.MAX_VALUE);
        System.out.println("char   " + Character.SIZE + " bits, 0 to " + (int) Character.MAX_VALUE);
        System.out.println("boolean: true or false");
    }
}
```

```
ana@vm:~/types$ java Ranges.java
byte   8 bits, -128 to 127
short  16 bits, -32768 to 32767
int    32 bits, -2147483648 to 2147483647
long   64 bits, -9223372036854775808 to 9223372036854775807
float  32 bits, largest 3.4028235E38
double 64 bits, largest 1.7976931348623157E308
char   16 bits, 0 to 65535
boolean: true or false
```

Each primitive has a class with a matching name, `Integer` for `int` and `Character` for `char`, and
those classes carry the limits as constants. The `(int)` before `Character.MAX_VALUE` turns the
character into its number, a cast that lesson 6 explains.

| type | bits | holds | use it for |
|---|---|---|---|
| `byte` | 8 | whole numbers, -128 to 127 | raw bytes from a file or the network |
| `short` | 16 | whole numbers, -32,768 to 32,767 | almost nothing in new code |
| `int` | 32 | whole numbers, about ±2.1 billion | **the default for a whole number** |
| `long` | 64 | whole numbers, about ±9.2 × 10¹⁸ | counts that can pass two billion, timestamps |
| `float` | 32 | decimals, about 7 significant digits | large arrays where memory matters |
| `double` | 64 | decimals, about 15 to 16 significant digits | **the default for a decimal** |
| `char` | 16 | one UTF-16 code unit, 0 to 65,535 | a single character |
| `boolean` | — | `true` or `false` | conditions |

**`int` and `double` are the defaults**: a whole number written in the source, such as `42`, is an
`int`, and a number with a point, such as `39.90`, is a `double`. The others are chosen on purpose,
for a reason you could name. The size of a `boolean` is not part of the language, which is why the
program printed none: the JVM decides how to store it.

## What happens at the edge

A fixed number of bits means a largest value, and Java does not stop at it. **Going past it wraps
round to the other end, silently**:

```java
// Overflow.java
public class Overflow {
    public static void main(String[] args) {
        int copies = Integer.MAX_VALUE;
        System.out.println(copies);
        System.out.println(copies + 1);
        long many = Integer.MAX_VALUE;
        System.out.println(many + 1);
        char letter = 'A';
        System.out.println(letter);
        System.out.println(letter + 0);
        letter++;
        System.out.println(letter);
    }
}
```

```
ana@vm:~/types$ java Overflow.java
2147483647
-2147483648
2147483648
A
65
B
```

`Integer.MAX_VALUE + 1` is `-2147483648`, the smallest `int`, with no error and no warning. The same
sum on a `long` gives the right answer, `2147483648`, because a `long` has room for it. **Choosing
`int` for something that can grow past two billion is a bug that waits**: a count of page views, a
size in bytes, the milliseconds since 1970. Lesson 8 shows `Math.addExact`, which throws instead of
wrapping.

The last three lines are about `char`. It prints as a letter, `A`, and it is a number underneath:
`letter + 0` turned it into an `int` and printed `65`, its code. `letter++` added one to that code,
and the variable printed `B`.

## Literals, and the one that does not fit

A number written in the source is a **literal**, and its type comes from how it is written. A plain
whole number is an `int`, so a whole number too big for an `int` is an error **even when the
variable it goes into is a `long`**:

```java
// Population.java
public class Population {
    public static void main(String[] args) {
        long people = 8_000_000_000;
        System.out.println(people);
    }
}
```

```
ana@vm:~/types$ java Population.java
Population.java:4: error: integer number too large
        long people = 8_000_000_000;
                      ^
1 error
error: compilation failed
```

The compiler reads `8_000_000_000` as an `int` first, and no `int` is that large. The fix is the
suffix `L`, `8_000_000_000L`, which makes the literal a `long`. The underscores are only for people:
Java ignores them in a number, and `8_000_000_000L` is easier to read than `8000000000L`.

| written | type |
|---|---|
| `42`, `8_000` | `int` |
| `42L`, `8_000_000_000L` | `long` |
| `39.90`, `1e3` | `double` |
| `39.90f` | `float` |
| `'A'` (single quotes) | `char` |
| `"A"` (double quotes) | `String`, not a primitive |
| `true`, `false` | `boolean` |

Use a capital `L`: a lower-case `l` looks like the digit `1` in most fonts.
