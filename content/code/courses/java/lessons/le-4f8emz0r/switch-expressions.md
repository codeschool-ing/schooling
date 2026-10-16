---
title: `switch` expressions and pattern matching
version: 1
---

Section 03's `switch` is a statement: it does things and produces nothing, and each `case` runs on
into the next. **Since Java 14 a `switch` can also be an expression that produces a value, with an
arrow after each `case` that runs that case alone.** Since Java 21 it can also test an object's type
and take it apart. Both are in Java 25 and both are how new code is written:

```schooling-example
{
  "language": "java",
  "file": "Fees.java",
  "parts": [
    {
      "code": "public class Fees {\n    static int dailyFine(String kind) {\n        return switch (kind) {\n            case \"book\", \"magazine\" -> 50;\n            case \"dvd\" -> 100;",
      "note": "**A `switch` expression produces a value**, so it can be returned or assigned. Each arrow case runs only its own right-hand side: there is no falling through and no `break`. One `case` may list several constants, separated by commas."
    },
    {
      "code": "            default -> {\n                System.out.println(\"  unknown kind: \" + kind);\n                yield 0;\n            }\n        };\n    }",
      "note": "A case that needs more than one statement takes a block, and **`yield` gives the block's value**. `return` would leave the whole method instead. The `;` after the closing brace ends the `return` statement."
    },
    {
      "code": "\n    static String describe(Object o) {\n        return switch (o) {\n            case null -> \"nothing\";",
      "note": "Since Java 21 a `switch` can take any object, and **`case null` handles `null` directly** instead of throwing, as section 03's did."
    },
    {
      "code": "            case Integer i when i > 100 -> \"a large number, \" + i;\n            case Integer i -> \"a number, \" + i;\n            case String s -> \"text of length \" + s.length();",
      "note": "**Pattern matching**: `case Integer i` matches when `o` is an `Integer` and names it `i`, already of type `Integer`. `when` adds a condition, called a guard. The cases are tried from the top, so the guarded one comes first."
    },
    {
      "code": "            default -> \"something else: \" + o.getClass().getSimpleName();\n        };\n    }",
      "note": "Everything else, here a `Double`. `getClass().getSimpleName()` names the object's class."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        System.out.println(dailyFine(\"book\") + \" \" + dailyFine(\"dvd\"));\n        System.out.println(dailyFine(\"map\"));\n        System.out.println(describe(7));\n        System.out.println(describe(250));\n        System.out.println(describe(\"Dom Casmurro\"));\n        System.out.println(describe(null));\n        System.out.println(describe(2.5));\n    }\n}"
    }
  ],
  "output": "50 100\n  unknown kind: map\n0\na number, 7\na large number, 250\ntext of length 12\nnothing\nsomething else: Double\n"
}
```

## The compiler checks that every value is covered

A `switch` statement may cover only some values, and the rest do nothing. **A `switch` expression
must produce a value for every possible input**, or it would have nothing to return. For a `String`
there are infinitely many inputs, so without a `default` the compiler refuses:

```java
// NoDefault.java
public class NoDefault {
    static int dailyFine(String kind) {
        return switch (kind) {
            case "book", "magazine" -> 50;
            case "dvd" -> 100;
        };
    }

    public static void main(String[] args) {
        System.out.println(dailyFine("book"));
    }
}
```

```
ana@vm:~/cond$ javac NoDefault.java
NoDefault.java:4: error: the switch expression does not cover all possible input values
        return switch (kind) {
               ^
1 error
```

That check is called **exhaustiveness**, and it pays most when the set of values is closed. For an
`enum` with three constants, covering the three is enough and no `default` is needed; when somebody
adds a fourth, every `switch` that forgot it stops compiling. Lesson 28 shows it on an `enum` and
lesson 29 on a sealed family of records.

## The order of patterns matters

Cases are tried from the top, and the first match wins. A general pattern above a more specific one
would make the specific one unreachable, and the compiler refuses that too:

```java
// Dominance.java
public class Dominance {
    static String describe(Object o) {
        return switch (o) {
            case Integer i -> "a number, " + i;
            case Integer i when i > 100 -> "a large number, " + i;
            default -> "something else";
        };
    }

    public static void main(String[] args) {
        System.out.println(describe(250));
    }
}
```

```
ana@vm:~/cond$ javac Dominance.java
Dominance.java:6: error: this case label is dominated by a preceding case label
            case Integer i when i > 100 -> "a large number, " + i;
                 ^
1 error
```

`case Integer i` matches every `Integer`, so the guarded case below it could never be chosen. It is
**dominated**, in the compiler's word. Put the case with the `when` first, as `Fees.java` does.
