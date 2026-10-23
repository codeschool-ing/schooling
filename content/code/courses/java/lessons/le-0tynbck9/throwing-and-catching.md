---
title: Reading a stack trace, and catching what you expected
version: 1
---

Several lessons of this course have ended a program with a stack trace, and each was the last thing
the program printed.
This lesson is about what they are. The wrong picture is that an exception is an error message.
**An exception is an object, thrown by one method and travelling back through every method that
called it**, until one of them catches it or there are none left. The stack trace is the list of
those methods.

Save this in a new directory, `~/exc`. It works out a fine at fifty cents a day, twice:

```java
// Fine.java
public class Fine {
    static int centsPerDay = 50;

    static int daysLate(String text) {
        return Integer.parseInt(text);
    }

    static int fine(String text) {
        return daysLate(text) * centsPerDay;
    }

    public static void main(String[] args) {
        System.out.println(fine("3"));
        System.out.println(fine("ten"));
        System.out.println("done");
    }
}
```

```
ana@vm:~/exc$ java Fine.java; echo "exit $?"
150
Exception in thread "main" java.lang.NumberFormatException: For input string: "ten"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Fine.daysLate(Fine.java:6)
	at Fine.fine(Fine.java:10)
	at Fine.main(Fine.java:15)
exit 1
```

The first fine came out as `150`. The second never did, and neither did `done`: the program printed
a stack trace and ended with exit status 1.

## Top to bottom

A stack trace is read from the top. The first line says **what** was thrown and why:
`NumberFormatException`, with the message `For input string: "ten"`. Every line after it is one
method call that was in progress when it was thrown, **the most recent first**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The call stack when Fine.java failed, drawn as frames stacked from main at the bottom to Integer.parseInt at the top. main called fine at line 15, fine called daysLate at line 10, daysLate called Integer.parseInt at line 6, and parseInt threw NumberFormatException. The exception travels down through every frame, none of which catches it, and the thread ends. The stack trace prints the frames top first: where it was thrown, then each caller.\"><defs><marker id=\"jv36-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"330\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Integer.parseInt</text><text x=\"56\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">throws NumberFormatException</text><text x=\"30\" y=\"41\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"40\" y=\"72\" width=\"330\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Fine.daysLate</text><text x=\"56\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">line 6 called parseInt</text><text x=\"30\" y=\"93\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"40\" y=\"124\" width=\"330\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Fine.fine</text><text x=\"56\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">line 10 called daysLate</text><text x=\"30\" y=\"145\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"40\" y=\"176\" width=\"330\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Fine.main</text><text x=\"56\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">line 15 called fine</text><text x=\"30\" y=\"197\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M390 41 V210\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#jv36-a)\"></path><text x=\"404\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the exception travels down the stack,</text><text x=\"404\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">looking for a catch that matches it</text><text x=\"404\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no frame here has one, so each method</text><text x=\"404\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ends where it stood, and so does the thread</text><text x=\"404\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">exit 1</text><text x=\"40\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the stack trace prints this column top first: where it was thrown, then who called whom</text></svg>", "caption": "A stack trace is the call stack at the moment of the throw, printed from the top. The frames from java.base above daysLate are inside the library; the first frame of your own code is where to look first."}
```

The first three `at` lines start with `java.base/`: they are inside the JDK's own `Integer` class,
whose source you did not write. **The first line that names your own class is where to start
reading**, here `Fine.daysLate(Fine.java:6)`, the call to `parseInt`. The lines under it say how the
program got there: `fine` at line 10 called `daysLate`, and `main` at line 15 called `fine` with
`"ten"`.

That last frame is often the most useful one. The library did what it was told; the bug is in what
it was given, and that came from line 15.

## Catching what you expected

A `try` block marks code you expect may fail, and a `catch` block after it says what to do when it
does. Catch only what you expected; for anything else, the stack trace above is better than any
handling. This program expects bad input:

```schooling-example
{
  "language": "java",
  "file": "Desk.java",
  "parts": [
    {
      "code": "public class Desk {\n    static int perBook(int totalCents, String books) {\n        return totalCents / Integer.parseInt(books);\n    }",
      "note": "**One line, two ways to fail.** `parseInt` throws `NumberFormatException` for text that is not a number, and integer division by zero throws `ArithmeticException`."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        for (String books : new String[] {\"4\", \"four\", \"0\", \"2\"}) {\n            try {\n                System.out.println(books + \" -> \" + perBook(600, books));",
      "note": "**The `try` block is the code you are prepared to see fail.** Six hundred cents of fines split between a number of books, four times, one of them a word and one of them zero."
    },
    {
      "code": "            } catch (NumberFormatException e) {\n                System.out.println(books + \" -> not a number: \" + e.getMessage());",
      "note": "**A `catch` names the exception class it handles**, and receives the exception object as `e`. `getMessage()` is the text after the colon in a stack trace."
    },
    {
      "code": "            } catch (ArithmeticException e) {\n                System.out.println(books + \" -> \" + e.getMessage());\n            }\n        }\n    }\n}",
      "note": "**The `catch` blocks are tried in order**, and the first whose class matches handles it. Once one has, the loop carries on with the next value, which is the point of catching at all."
    }
  ]
}
```

```
ana@vm:~/exc$ java Desk.java
4 -> 150
four -> not a number: For input string: "four"
0 -> / by zero
2 -> 300
```

**Two values failed and the loop survived both**, which is what the two `catch` blocks bought. `four`
was handled by the first and `0` by the second, with the message each exception carried.

When two exceptions are handled the same way, one `catch` can name both, separated by a bar:
`catch (NumberFormatException | ArithmeticException e)`. That is a **multi-catch**, and inside it
`e` has the type both classes share. It saves writing the same block twice; it does not change which
exceptions are caught.
