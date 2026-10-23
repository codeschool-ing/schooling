---
title: Building a string piece by piece
version: 1
---

If a string can never change, then `s = s + "x"` cannot add an `x` to `s`. **It builds a whole new
string**, copies every character of the old one into it, adds the `x`, and points `s` at the result.
Once is nothing. In a loop it is a copy of everything so far, every time round, and the work grows
with the square of the length. `StringBuilder` is the class for this job: a buffer of characters
that **does** change, which you fill and then turn into a `String` once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 264\" role=\"img\" aria-label=\"Building a five-character string two ways. With s = s + x, each step makes a new string and copies the old one into it: 0, 1, 2, 3 and 4 characters, ten in all, and the work grows with the square of the length. With a StringBuilder, five appends fill one buffer in place, and toString copies the five characters once.\"><rect x=\"16\" y=\"16\" width=\"380\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">s = s + \"x\", five times</text><rect x=\"36\" y=\"56\" width=\"32\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><text x=\"260\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a new string; 0 copied</text><rect x=\"36\" y=\"90\" width=\"54\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"63.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">xx</text><text x=\"260\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a new string; 1 copied</text><rect x=\"36\" y=\"124\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"74.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">xxx</text><text x=\"260\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a new string; 2 copied</text><rect x=\"36\" y=\"158\" width=\"98\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">xxxx</text><text x=\"260\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a new string; 3 copied</text><rect x=\"36\" y=\"192\" width=\"120\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">xxxxx</text><text x=\"260\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a new string; 4 copied</text><text x=\"206\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0+1+2+3+4 = 10 characters copied</text><rect x=\"412\" y=\"16\" width=\"292\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"558\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">StringBuilder, five appends</text><rect x=\"440\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"453\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"470\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"483\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"500\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"513\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"530\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"543\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"560\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"590\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"620\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"650\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"558\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one buffer, filled in place, with room left</text><text x=\"558\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">sb.toString()</text><text x=\"558\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">copies the 5 characters once</text><text x=\"558\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 characters copied</text></svg>", "caption": "Five steps of each. The left column grows with the square of the length; the right one grows with the length."}
```

This program builds the same 50,000-character string both ways and times each:

```java
// Concat.java
public class Concat {
    public static void main(String[] args) {
        int n = 50_000;

        long start = System.nanoTime();
        String s = "";
        for (int i = 0; i < n; i++) {
            s = s + "x";
        }
        long plus = System.nanoTime() - start;

        start = System.nanoTime();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < n; i++) {
            sb.append("x");
        }
        String t = sb.toString();
        long builder = System.nanoTime() - start;

        System.out.println(s.length() + " " + t.length() + " " + s.equals(t));
        System.out.println("with +:             " + plus / 1_000_000 + " ms");
        System.out.println("with StringBuilder: " + builder / 1_000_000 + " ms");
    }
}
```

```
ana@vm:~/strings$ javac Concat.java && java Concat
50000 50000 true
with +:             1715 ms
with StringBuilder: 5 ms
```

Same string, `true`, and the `+` loop took over 300 times as long. **The two timings are one run's
and they move**: across three runs of this same program on the same machine, the first moved by a
factor of five and the second stayed in single digits. The ratio is the finding, and
it grows as `n` grows, because the copies grow with it. `System.nanoTime()` is the clock for
measuring an interval like this; `/ 1_000_000` turns nanoseconds into milliseconds, and the
underscores in `50_000` are only there for the reader.

## When `+` is fine

None of that makes `+` wrong. **Outside a loop, `+` is the clearer choice and costs nothing extra.**
The compiler does not even turn it into a chain of copies. This method joins four pieces:

```java
// Greeting.java
public class Greeting {
    static String greet(String name, int books) {
        return "Hello, " + name + ", you have " + books + " books";
    }

    public static void main(String[] args) {
        System.out.println(greet("Ana", 3));
    }
}
```

```
ana@vm:~/strings$ javac Greeting.java && java Greeting
Hello, Ana, you have 3 books
ana@vm:~/strings$ javap -c Greeting | grep -A5 "greet(java"
  static java.lang.String greet(java.lang.String, int);
    Code:
         0: aload_0
         1: iload_1
         2: invokedynamic #7,  0              // InvokeDynamic #0:makeConcatWithConstants:(Ljava/lang/String;I)Ljava/lang/String;
         7: areturn
```

Lesson 1 read bytecode with `javap -c`, and this method is four instructions: load `name`, load
`books`, one `invokedynamic`, return. **The whole expression became a single call** to
`makeConcatWithConstants`, which the JVM sets up the first time it runs and which sizes the result
once. The literal parts, `"Hello, "` and the rest, travel as a template rather than as separate
strings. `int` needed no conversion in the source either: when one side of `+` is a `String`, the
other side is turned into text, whatever its type.

So the rule is narrow. **Inside a loop that grows one string, use a `StringBuilder`.** Anywhere
else, write `+` and let the compiler do the rest. `StringBuilder`'s methods return the builder
itself, so `sb.append(a).append(b)` is one statement, and lesson 26 is about that style of method.
