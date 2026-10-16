---
title: Taking behaviour as an argument
version: 1
---

**A higher-order function is a function that takes another function as an argument, or returns
one.** The term comes from mathematics, and in Java it means a method with a functional interface
among its parameters or as its return type. `List.sort(Comparator)` is one, and so is
`removeIf(Predicate)`. This section writes one, starting from the code that asks for it.

## Three methods that differ in one line

A bookshop's shelf, and a question asked of it in several ways. Written without lambdas, each
question is a method:

```java
// Select.java: a method per question, then one method that takes the question
import java.util.ArrayList;
import java.util.List;
import java.util.function.Predicate;

public class Select {
    record Book(String title, int pages, long priceCents) {}

    static List<Book> longerThan(List<Book> books, int pages) {
        List<Book> out = new ArrayList<>();
        for (Book b : books) {
            if (b.pages() > pages) {
                out.add(b);
            }
        }
        return out;
    }

    static <T> List<T> select(List<T> items, Predicate<T> rule) {
        List<T> out = new ArrayList<>();
        for (T item : items) {
            if (rule.test(item)) {
                out.add(item);
            }
        }
        return out;
    }

    static List<String> titles(List<Book> books) {
        List<String> out = new ArrayList<>();
        for (Book b : books) {
            out.add(b.title());
        }
        return out;
    }

    public static void main(String[] args) {
        List<Book> shelf = List.of(
                new Book("Dune", 412, 6990),
                new Book("Emma", 474, 3990),
                new Book("Beowulf", 96, 2490),
                new Book("Ulysses", 730, 8990));
        System.out.println("longerThan:  " + titles(longerThan(shelf, 450)));
        System.out.println("long:        " + titles(select(shelf, b -> b.pages() > 450)));
        System.out.println("cheap:       " + titles(select(shelf, b -> b.priceCents() < 4000)));
        System.out.println("odd request: " + titles(select(shelf, b -> b.title().startsWith("U") || b.pages() < 100)));
        System.out.println("short words: " + select(List.of("an", "epic", "of", "the", "sea"), w -> w.length() <= 2));
    }
}
```

```
ana@vm:~/fp/higher-order$ java Select.java
longerThan:  [Emma, Ulysses]
long:        [Emma, Ulysses]
cheap:       [Emma, Beowulf]
odd request: [Beowulf, Ulysses]
short words: [an, of]
```

`longerThan` is one question hard-coded into a loop. The next question, cheaper than some price,
would be a copy of it with one line changed, and so would the one after. **`select` keeps the loop
and takes the line that changes as an argument.** The first two results are identical, which is
the proof that nothing was lost, and the third and fourth are questions nobody wrote a method for.

## Generic, because the loop does not care

`select` is declared `<T>`, so it works on any list with a rule about that list's type. The last
line used it on plain strings with no change. That is the general shape of a higher-order
function: **the method owns the part that is always the same, here the loop and the new list, and
the caller supplies the part that varies.** It is the same split the Stream API makes on a much
larger scale. Lesson 7's `filter` is this `select`, built into the library and able to run on
several processors.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two panels. On the left, taking behaviour: the caller passes the lambda b -&gt; b.pages() &gt; 450 into select, which owns the loop and calls the lambda once per book. On the right, returning behaviour: the caller passes the number 450 into atLeast, which hands back a lambda that has captured it.\"><defs><marker id=\"flow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">taking behaviour</text><rect x=\"45\" y=\"70\" width=\"280\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">b -&gt; b.pages() &gt; 450</text><path d=\"M185 106 L185 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#flow-ah-phosphor)\"></path><rect x=\"45\" y=\"138\" width=\"280\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">select(shelf, rule)</text><text x=\"185.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">owns the loop, calls the rule</text><text x=\"185.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">once per book</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">returning behaviour</text><rect x=\"395\" y=\"70\" width=\"280\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">atLeast(450)</text><path d=\"M535 106 L535 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#flow-ah-phosphor)\"></path><rect x=\"395\" y=\"138\" width=\"280\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">b -&gt; b.pages() &gt;= pages</text><text x=\"535.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pages = 450, captured</text></svg>", "caption": "Taking behaviour puts the caller's rule inside somebody else's loop; returning it builds a rule for the caller to keep."}
```

## What to watch for

The lambda runs inside `select`, once per item, at a moment `select` chooses. So a rule that
**does something** besides answer, such as printing or changing a field, does it as many times as
`select` decides to call it. A rule that only reads its argument and returns an answer is safe to
call any number of times, in any order. Lessons 9 and 11 come back to why that difference matters
as soon as more than one thread is calling.
