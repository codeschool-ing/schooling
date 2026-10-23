---
title: Where objects live while the program runs
version: 1
---

A running JVM keeps two kinds of memory apart, and the difference is what section 03 was about.
**Local variables live on the stack**, in a frame that belongs to one call of one method and goes
away when the call returns. **Objects live on the heap**, a region shared by the whole program, and
they stay there for as long as some reference still leads to them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Stack and heap during Refs. On the stack, main's frame holds five local variables: args, a, b, c and none. a and b both point at one Book object on the heap, whose title points at the string Memorial de Aires. c points at a second Book object whose title points at another string with the same characters. none points at nothing.\"><defs><marker id=\"jv12-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the stack</text><rect x=\"20\" y=\"36\" width=\"180\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">frame of main</text><rect x=\"36\" y=\"70\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">args</text><rect x=\"36\" y=\"106\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a</text><rect x=\"36\" y=\"142\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">b</text><rect x=\"36\" y=\"178\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c</text><rect x=\"36\" y=\"214\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">none = null</text><text x=\"470\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the heap</text><rect x=\"250\" y=\"36\" width=\"450\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"290\" y=\"90\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"365\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">isbn  title  year</text><rect x=\"290\" y=\"176\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"365\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">isbn  title  year</text><rect x=\"500\" y=\"90\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Memorial de Aires\"</text><rect x=\"500\" y=\"176\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Memorial de Aires\"</text><path d=\"M184 120 H230 V114 H288\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><path d=\"M184 156 H230 V126 H288\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><path d=\"M184 192 H230 V206 H288\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><path d=\"M440 110 H498\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><path d=\"M440 196 H498\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><text x=\"475\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">two objects, three references to them, and none from none</text></svg>", "caption": "Refs from section 03 just before its last line. a and b lead to one Book; c leads to another, whose title is an equal string and a different object."}
```

The `title` field is itself a reference, which is why the drawing has two layers on the heap: a
`Book` holds the way to its `String`, not the characters. **Everything that is not one of the eight
primitive types of lesson 4 is reached through a reference.** An `int` field such as `year` holds the
number itself, inside the object.

## Counting the objects in a running JVM

You can count what is on the heap. The JDK's `jcmd`, from lesson 2, can ask a running JVM how many
objects of each class it holds. This program makes a thousand books and keeps them for ten seconds,
long enough to ask:

```java
// Shelf.java
public class Shelf {
    public static void main(String[] args) throws InterruptedException {
        Book[] books = new Book[1000];
        for (int i = 0; i < books.length; i++) {
            books[i] = new Book();
            books[i].year = 1900 + i % 100;
        }
        System.out.println(books.length + " books on the shelf, waiting 10 seconds");
        Thread.sleep(10_000);
        System.out.println("done");
    }
}
```

`throws InterruptedException` is there because `Thread.sleep` demands it, which lesson 36 explains.
Compile it with `javac Shelf.java` and run it in one terminal:

```
ana@vm:~/objects$ java Shelf
1000 books on the shelf, waiting 10 seconds
done
```

While it waits, in a second terminal in the same directory, list the JVMs and ask the one running
`Shelf` for its class histogram:

```
ana@vm:~/objects$ jps
30259 Jps
30222 Shelf
ana@vm:~/objects$ jcmd Shelf GC.class_histogram | head -3
30222:
 num     #instances         #bytes  class name (module)
-------------------------------------------------------
ana@vm:~/objects$ jcmd Shelf GC.class_histogram | grep -E " Book$|\[LBook;"
   9:          1000          24000  Book
  24:             1           4016  [LBook;
```

`jps` listed two JVMs: `Shelf`, and `jps` itself, which is a Java program too. The numbers are
process ids and yours will differ. `jcmd` accepts the class name in place of the id.

**One thousand `Book` objects, 24,000 bytes: 24 bytes each.** That is twelve bytes of header, which
every object carries so the JVM knows its class, then four for each of the two references and four
for the `int`. The `[LBook;` line is the array itself, the JVM's own name for a `Book[]`: one object
of 4,016 bytes, a header and a thousand four-byte references. The array holds references to the
books; it does not contain them. The two `String` fields were never set in this program, so no
string was made for them.

When `main` returns, the frame that held `books` goes, nothing leads to the thousand books any more,
and the program ends. What happens to objects nobody can reach in a program that keeps running is
lesson 19.
