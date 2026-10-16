---
title: Folding a stream into one value
version: 1
---

**`reduce` combines all the elements of a stream into one value, two at a time.** It takes a starting
value, called the **identity**, and a function that combines what has been accumulated so far with
the next element. A sum is the plain case: start from 0 and add. Lesson 5 section 05 folded a list of
functions into one with the same idea; `reduce` is the stream's version.

```java
// Reduce.java: reduce with and without an identity, and the rule it relies on
import java.util.Optional;
import java.util.stream.IntStream;
import java.util.stream.Stream;

public class Reduce {
    public static void main(String[] args) {
        long total = Shelf.BOOKS.stream().map(Book::priceCents).reduce(0L, (a, b) -> a + b);
        long sameTotal = Shelf.BOOKS.stream().mapToLong(Book::priceCents).sum();
        System.out.println("total: " + total + " / " + sameTotal);

        Optional<Book> oldest = Shelf.BOOKS.stream().reduce((a, b) -> a.year() <= b.year() ? a : b);
        System.out.println("oldest: " + oldest.map(Book::title).orElse("none"));
        Optional<Long> nothing = Stream.<Long>empty().reduce((a, b) -> a + b);
        System.out.println("sum of nothing, no identity: " + nothing);

        System.out.println("minus, in order:  " + IntStream.rangeClosed(1, 8).reduce(0, (a, b) -> a - b));
        System.out.println("minus, split up:  " + IntStream.rangeClosed(1, 8).parallel().reduce(0, (a, b) -> a - b));
        System.out.println("start 100, in order: " + IntStream.rangeClosed(1, 8).reduce(100, Integer::sum));
        System.out.println("start 100, split up: " + IntStream.rangeClosed(1, 8).parallel().reduce(100, Integer::sum));
    }
}
```

```
ana@vm:~/fp/streams$ java Reduce.java
total: 62480 / 62480
oldest: Beowulf
sum of nothing, no identity: Optional.empty
minus, in order:  -36
minus, split up:  0
start 100, in order: 136
start 100, split up: 836
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two ways of combining the numbers 1 to 8 with subtraction from 0. In order, the result is one chain: 0 minus 1, minus 2, and so on to minus 8, which is minus 36. Split into two pieces, 1 to 4 and 5 to 8, each piece is reduced from 0 separately, giving minus 10 and minus 26, and then the two partial results are combined, which gives a different number.\"><defs><marker id=\"fold-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"fold-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"fold-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">in order</text><rect x=\"20\" y=\"36\" width=\"560\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8</text><rect x=\"610\" y=\"36\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">-36</text><path d=\"M580 54 L606 54\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-phosphor)\"></path><text x=\"20\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">split in two</text><rect x=\"20\" y=\"116\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 - 1 - 2 - 3 - 4</text><rect x=\"20\" y=\"162\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 - 5 - 6 - 7 - 8</text><rect x=\"300\" y=\"116\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">-10</text><rect x=\"300\" y=\"162\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">-26</text><path d=\"M270 134 L296 134\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-paperdim)\"></path><path d=\"M270 180 L296 180\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-paperdim)\"></path><rect x=\"410\" y=\"136\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">(-10) - (-26)</text><path d=\"M370 134 L390 134 L390 150 L406 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-paperdim)\"></path><path d=\"M370 180 L390 180 L390 166 L406 166\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-paperdim)\"></path><rect x=\"610\" y=\"136\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">16</text><path d=\"M580 158 L606 158\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#fold-ah-amber)\"></path></svg>", "caption": "A split stream reduces each piece from the identity and then combines the pieces, so the operation must not care about grouping."}
```

The first line is the shelf's total price, 62,480 cents, computed by `reduce` and again by
`mapToLong(...).sum()`, which is the same fold with the addition built in. **Use the built-in one
when there is one**: `sum`, `count`, `max`, `min` and `average` say what they do, and the primitive
streams compute them without boxing.

## Without an identity, the answer may be missing

`reduce((a, b) -> ...)` with no starting value returns an `Optional`. With no identity there is
nothing to return for an empty stream, so the result says so instead of inventing a value: the empty
stream gave `Optional.empty`. `oldest` folded the shelf two books at a time, always keeping the older,
and Beowulf won. Lesson 10 is about `Optional`; here it is enough that `map` and `orElse` read the
value out safely.

## The rule the compiler cannot check

The last four lines are the reason `reduce` has a rule. A stream may be split into pieces, each piece
reduced on its own, and the partial results combined; lesson 9 does that on purpose, and `parallel()`
here only asks for it. For the answer to be the same however the stream is split, two things must
hold:

- **the combining function is associative**: `(a op b) op c` equals `a op (b op c)`. Addition is;
  subtraction is not. In order, 0 − 1 − 2 − … − 8 is −36. Split up, the pieces were subtracted
  separately and then subtracted from each other, and the answer came out as 0. The figure splits
  the numbers in two, which gives 16; the run cut them into eight pieces;
- **the identity really is neutral**: combining it with any value gives that value back. 0 is the
  identity of addition; 100 is not. In order, 100 was added once and gave 136. Split up, every piece
  started from its own 100, and 836 is 36 plus eight of them: the stream had been cut into eight
  pieces.

Neither run threw an error. **A `reduce` that breaks the rule gives a wrong number, quietly**, and only
when the stream happens to be split. Sums, products, `max`, `min`, string joining and `andThen` are
associative and have a true identity; subtraction, division and averages are not, and an average is
computed with `average()` or a collector instead.
