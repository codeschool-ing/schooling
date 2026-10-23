---
title: `for`, `while` and `do-while`
version: 1
---

A loop runs a block again and again while a condition holds. Java has three kinds, and **they
differ in one thing: when the condition is checked**. Picking the right one is about saying what
the loop is for, so that a reader knows at the first line. Make a directory for this lesson,
`~/loops`, and save this as `Counting.java`:

```schooling-example
{
  "language": "java",
  "file": "Counting.java",
  "parts": [
    {
      "code": "public class Counting {\n    public static void main(String[] args) {\n        for (int i = 1; i <= 3; i++) {\n            System.out.println(\"copy \" + i);\n        }",
      "note": "**`for` is for counting.** Its header holds three parts, separated by semicolons: where `i` starts, the test that keeps the loop going, and what happens after each pass. Three passes, `copy 1` to `copy 3`."
    },
    {
      "code": "\n        int pages = 300;\n        int days = 0;\n        while (pages > 0) {\n            pages -= 70;\n            days++;\n        }\n        System.out.println(days + \" days, \" + pages + \" pages\");",
      "note": "**`while` is for repeating until something becomes true**, when nobody knows in advance how many passes it takes. Reading 70 pages a day, a 300-page book takes 5 days, and the counter ends at `-50`: the last day needed only 50 pages, and the loop subtracted 70 anyway."
    },
    {
      "code": "\n        int n = 0;\n        while (n < 0) {\n            System.out.println(\"never printed\");\n        }\n        do {\n            System.out.println(\"do-while ran once, n = \" + n);\n        } while (n < 0);",
      "note": "Same test, two loops. **`while` tests first**, so with the test false from the start its body ran zero times. **`do-while` tests after the body**, so it always runs at least once."
    },
    {
      "code": "\n        int count = 0;\n        for (int i = 0; i <= 3; i++) {\n            count++;\n        }\n        System.out.println(\"i from 0 to 3 inclusive: \" + count + \" passes\");\n    }\n}",
      "note": "The **off-by-one error**. From 0 up to and including 3 is four values, not three. `i <= 3` where `i < 3` was meant runs one extra pass, and on an array it reads one place past the end, which is lesson 9's exception."
    }
  ],
  "output": "copy 1\ncopy 2\ncopy 3\n5 days, -50 pages\ndo-while ran once, n = 0\ni from 0 to 3 inclusive: 4 passes\n"
}
```

## The order a `for` runs in

The header of a `for` reads left to right, and it does not run left to right. Its three parts run at
three different moments:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"The order in which a for loop runs. The initialiser, int i = 1, runs once. Then the test, i <= 3, runs before every pass: when it is true the body runs, then the update, i++, and control goes back to the test. When the test is false the loop ends. Because the test comes before the body, a test that is false at the start runs the body zero times.\"><defs><marker id=\"jv11-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"150\" y=\"14\" width=\"420\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">for (int i = 1; i <= 3; i++) { body }</text><rect x=\"40\" y=\"90\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int i = 1</text><text x=\"100\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">once, first</text><rect x=\"220\" y=\"90\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">i <= 3</text><text x=\"280\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">before every pass</text><rect x=\"400\" y=\"90\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">body</text><text x=\"460\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">if the test was true</text><rect x=\"580\" y=\"90\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">i++</text><text x=\"640\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after every pass</text><path d=\"M160 116 H218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\"></path><path d=\"M340 116 H398\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\"></path><text x=\"369\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">true</text><path d=\"M520 116 H578\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\"></path><path d=\"M640 142 V176 H280 V144\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\"></path><text x=\"460\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">back to the test</text><path d=\"M280 90 V66 H700 V200\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\" stroke-dasharray=\"5 4\"></path><text x=\"500\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">false: leave the loop</text><rect x=\"40\" y=\"212\" width=\"640\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">checked before the body, so a test false at the start runs the body zero times</text></svg>", "caption": "The three parts of a for header run at three different moments. A while loop is the same diagram with the first and last boxes moved out of the header."}
```

So `for (int i = 1; i <= 3; i++)` runs the test four times and the body three: the fourth test finds
`i` at 4 and ends the loop. And **`i` exists only inside the loop**. Declared in the header, it
disappears with the loop, which is lesson 5's scope, and the next loop can declare its own `i`.

Any `for` can be rewritten as a `while` by moving the first part above the loop and the third to the
end of the body. The reason to keep the `for` is that all three parts sit on one line, where a reader
checks them together. **Use `for` when you are counting, and `while` when you are waiting** for a
condition, like a book with pages left to read.

## A loop that never ends

If nothing in the body moves the condition towards `false`, the loop runs until somebody stops it.
This one forgets to add 1 to `i`:

```java
// Forever.java
public class Forever {
    public static void main(String[] args) {
        int i = 0;
        while (i < 10) {
            System.out.println("i = " + i);
        }
    }
}
```

```
ana@vm:~/loops$ javac Forever.java && timeout 1 java Forever | head -3
i = 0
i = 0
i = 0
ana@vm:~/loops$ timeout 1 java Forever | wc -l
514426
```

`timeout 1` is a Linux command that stops a program after one second, used here because a
transcript cannot press a key. **At your own terminal, `Ctrl+C` stops it.** In that one second the
program printed 514,426 lines, all of them `i = 0`, and the count is different on every run. An
endless loop is the kind of bug that shows up as a program that simply never answers; the first
thing to read is what, inside the loop, was supposed to change the condition.
