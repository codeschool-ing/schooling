---
title: A string never changes
version: 1
---

Most people meet `String` with a picture of a box of characters that methods edit in place:
call `toUpperCase` and the box now holds capitals. **No method of `String` changes the string it is
called on.** Every one that seems to returns a new `String`, and the old one is left exactly as it
was. A program that forgets to keep the result throws the change away. Make a directory for this
lesson, `~/strings`, and save this as `Immutable.java`:

```java
// Immutable.java
public class Immutable {
    public static void main(String[] args) {
        String name = "ana";
        name.toUpperCase();
        System.out.println(name);

        String upper = name.toUpperCase();
        System.out.println(upper);
        System.out.println(name);
    }
}
```

```
ana@vm:~/strings$ java Immutable.java
ana
ANA
ana
```

The first `toUpperCase()` built `"ANA"`, returned it, and nothing caught it, so the first line
printed `ana`. The second call kept its result in `upper`. **The last line printed `ana` again**:
`name` still points at the string it was given, because that string cannot change. Lesson 2 showed
`java Immutable.java`, the source launcher, and this lesson uses it for every program, since each
one is a single file run once.

Immutability is what lets Java share strings freely. A `String` handed to a method, stored in two
lists or used as a key in a map cannot be altered behind anybody's back. Lesson 26 comes back to
the cost of forgetting a result, `s.toUpperCase();` on its own line, which compiles and does nothing.

## `==` is the wrong question

Because strings are objects, a variable holds a **reference** to one, and `==` compares references.
Lesson 12 explains references properly; here it is enough to see what the two operators answer:

```schooling-example
{
  "language": "java",
  "file": "Equality.java",
  "parts": [
    {
      "code": "public class Equality {\n    public static void main(String[] args) {\n        String a = \"java\";\n        String b = \"java\";",
      "note": "**Two literals with the same text are one object.** The compiler writes `\"java\"` once into the class file, and the JVM keeps one `String` for it, so `a` and `b` hold the same reference."
    },
    {
      "code": "        String c = new StringBuilder(\"jav\").append('a').toString();",
      "note": "**Built while the program runs, so a new object.** Same four characters, somewhere else in memory. Any string read from a file, a keyboard or a network arrives this way."
    },
    {
      "code": "\n        System.out.println(a == b);\n        System.out.println(a == c);",
      "note": "`==` on objects asks **is this the same object?** For `a` and `b` it is. For `a` and `c` it is not, whatever the characters say."
    },
    {
      "code": "        System.out.println(a.equals(c));",
      "note": "`equals` asks **do these hold the same characters?**, which is nearly always the question you meant."
    },
    {
      "code": "        System.out.println(a == c.intern());\n    }\n}",
      "note": "`intern()` returns the JVM's one shared copy of that text. It explains the first line, and you will seldom call it yourself."
    }
  ],
  "output": "true\nfalse\ntrue\ntrue\n"
}
```

The second line is the classic bug. It compares a string the program built with a literal and
answers `false`, and in a quick test with two literals it would have answered `true`. **Compare
strings with `equals`, always**, and save `==` for the question of identity, which strings almost
never need answering.

## Text blocks

A string with several lines, or with quotes inside it, is awkward to write as a literal. Since
Java 15 a **text block** opens with three double quotes and a line break, and closes with three
more:

```java
// Receipt.java
public class Receipt {
    public static void main(String[] args) {
        String receipt = """
            Loan receipt
              Book:   "Dom Casmurro"
              Due:    2026-11-06
            """;
        System.out.print(receipt);
        System.out.println(receipt.lines().count() + " lines");
    }
}
```

```
ana@vm:~/strings$ java Receipt.java
Loan receipt
  Book:   "Dom Casmurro"
  Due:    2026-11-06
3 lines
```

The quotes around the title needed no backslash. The indentation inside the program vanished, and
the rule is mechanical: **the compiler removes as many leading spaces as the least indented line
has**, counting the closing `"""`. Here that line and `Loan receipt` sat at the same depth, so the
receipt kept only the two extra spaces of the indented lines. The block also ends with a line
break, because the closing quotes are on a line of their own, which is why it is printed with
`print` and not `println`.
