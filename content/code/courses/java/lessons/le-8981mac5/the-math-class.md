---
title: The `Math` class, and rounding on purpose
version: 1
---

Everything mathematical that is not an operator lives in one class, `java.lang.Math`: absolute
values, powers, roots, rounding, trigonometry. **It is a class you never create an object of.** Its
methods are `static`, called on the class's name, `Math.sqrt(2)`, and lesson 15 explains what that
word means. Being in `java.lang`, it needs no `import`.

The program below calls the ones a business program actually uses, and most of its lines hold
an answer a calculator would not have given:

```schooling-example
{
  "language": "java",
  "file": "MathClass.java",
  "parts": [
    {
      "code": "import java.util.Random;\n\npublic class MathClass {\n    public static void main(String[] args) {\n        System.out.println(Math.abs(-42));\n        System.out.println(Math.abs(Integer.MIN_VALUE));",
      "note": "**`Math.abs` of the smallest `int` is still negative.** Its positive twin, 2,147,483,648, is one more than an `int` can hold, so the answer wraps back to where it started: `-2147483648`. `Math.absExact` throws instead."
    },
    {
      "code": "        System.out.println(Math.max(3, 9) + \" \" + Math.min(3, 9));\n        System.out.println(Math.pow(2, 10));\n        System.out.println(Math.sqrt(2));",
      "note": "`max` and `min` keep the type they were given. **`pow` and `sqrt` always return a `double`**, which is why 2 to the 10th printed as `1024.0`."
    },
    {
      "code": "        System.out.println(Math.round(2.5) + \" \" + Math.round(-2.5) + \" \" + Math.round(2.4));\n        System.out.println(Math.floor(-2.5) + \" \" + Math.ceil(-2.5));\n        System.out.println((int) 2.5 + \" \" + (int) -2.5);",
      "note": "`round` takes a half **upwards, towards positive infinity**: 2.5 became 3 and -2.5 became -2. `floor` goes down and `ceil` up, and both return a `double`: `-3.0` and `-2.0`. A cast to `int` cuts towards zero: `2` and `-2`."
    },
    {
      "code": "        System.out.println(-7 / 2 + \" \" + Math.floorDiv(-7, 2));\n        System.out.println(-7 % 2 + \" \" + Math.floorMod(-7, 2));",
      "note": "`/` cut -3.5 towards zero and gave `-3`; **`floorDiv` rounds down and gives `-4`**. Their remainders follow: `%` gave `-1` and `floorMod` gave `1`, which is never negative for a positive divisor."
    },
    {
      "code": "\n        Random dice = new Random(42);\n        for (int roll = 0; roll < 5; roll++) {\n            System.out.print(\" \" + dice.nextInt(1, 7));\n        }\n        System.out.println();\n    }\n}",
      "note": "Five dice. `nextInt(1, 7)` gives a whole number from 1 up to but not including 7. **The seed, 42, fixes the sequence**: this program prints the same five rolls on every run, which is what a test needs. `new Random()` with no seed starts somewhere different each time."
    }
  ],
  "output": "42\n-2147483648\n9 3\n1024.0\n1.4142135623730951\n3 -2 2\n-3.0 -2.0\n2 -2\n-3 -4\n-1 1\n 3 4 1 3 1\n"
}
```

## Three ways to round, and they disagree on negatives

Rounding is where `Math` most often gives an answer the programmer did not expect, because "round"
is several operations that agree on positive numbers and part company below zero:

| method | 2.5 | -2.5 | returns |
|---|---|---|---|
| `Math.round` | 3 | -2 | `long` |
| `Math.floor` | 2.0 | -3.0 | `double` |
| `Math.ceil` | 3.0 | -2.0 | `double` |
| a cast, `(int)` | 2 | -2 | `int` |

**`Math.round(-2.5)` is `-2`, not `-3`**: it adds one half and then rounds down, so a half always
goes towards positive infinity. The cast in the last row is lesson 6's narrowing, which cuts
towards zero. None of these is the rounding an accountant means by "half up" on negative amounts,
and section 05 shows the class that lets you say which rule you want.

## `floorDiv` and `floorMod`

Section 02 showed that `/` cuts towards zero and `%` takes the sign of the left operand. That is
the wrong behaviour for anything that wraps round: which day of the week is 10 days **before** a
Wednesday, which slot of a ring of 7 is index `-3`. **`Math.floorMod(n, 7)` always lands between 0
and 6** for any `n`, where `n % 7` can land between -6 and 6. `floorDiv` is its partner, and the two
always agree: `floorDiv(-7, 2) * 2 + floorMod(-7, 2)` gives back `-7`, just as `-7 / 2 * 2 + -7 % 2`
does.

## Random numbers

`Math.random()` exists and returns a `double` from 0 up to 1. **`java.util.Random` is the better
tool**, because it gives whole numbers in a range directly, `nextInt(1, 7)` for a die, and because it
takes a seed. A seeded `Random` is a recipe: the same seed always produces the same sequence, which
is why the output above will read `3 4 1 3 1` on your machine too. A program that must not be
predictable, a password or a token, uses `java.security.SecureRandom` instead, and never a seed.
