---
title: Fixtures, nested classes and AssertJ
version: 1
---

`Isbn` has no state, so its tests need nothing prepared. A `Book` has a stock that `take` changes,
and an `Order` adds up its lines. Testing them raises two new questions: where the object a test
starts from comes from (the **fixture**), and how to say more in an assertion than true or false.

## BookTest

Create `src/test/java/com/example/bookshop/catalogue/BookTest.java`:

```schooling-example
{
  "language": "java",
  "file": "BookTest.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport static org.junit.jupiter.api.Assertions.assertEquals;\nimport static org.junit.jupiter.api.Assertions.assertThrows;\n\nimport org.junit.jupiter.api.BeforeEach;\nimport org.junit.jupiter.api.DisplayName;\nimport org.junit.jupiter.api.Nested;\nimport org.junit.jupiter.api.Test;\n",
      "note": "`assertThrows` is the one new assertion. `@BeforeEach`, `@Nested` and `@DisplayName` are about how the tests are arranged, not about what they check."
    },
    {
      "code": "class BookTest {\n\n    private Book book;\n\n    @BeforeEach\n    void aBookWithTwoCopies() {\n        book = new Book(\"9786500000016\", \"Dom Casmurro\", new Author(\"Machado de Assis\"), 3990, 2);\n    }\n",
      "note": "**`@BeforeEach` runs before every test of this class, nested classes included.** Every test changes the book, so every test needs a new one with two copies. Writing `new Book(...)` in the field's declaration would work too, because the instance itself is new for every test (the figure below shows it); `@BeforeEach` is the conventional place, and the one that still works when the set-up takes more than one statement."
    },
    {
      "code": "    @Nested\n    @DisplayName(\"take\")\n    class Take {\n",
      "note": "A **nested class** groups the tests about one method, `take`. It is an inner class, not `static`, so its tests see `book` from the outer instance. `@DisplayName(\"take\")` is the name JUnit gives the group instead of `Take`."
    },
    {
      "code": "        @Test\n        void lowersTheStock() {\n            book.take(2);\n            assertEquals(0, book.getStock());\n        }\n",
      "note": "The plain claim: take two of two, and none are left."
    },
    {
      "code": "        @Test\n        void refusesMoreThanThereIs() {\n            OutOfStockException e = assertThrows(OutOfStockException.class, () -> book.take(3));\n            assertEquals(\"Only 2 of 'Dom Casmurro' left, 3 wanted\", e.getMessage());\n        }\n",
      "note": "`assertThrows` runs the lambda and passes only if it throws that exception type, or a subclass of it. It returns the exception, so the test can go on to check the message."
    },
    {
      "code": "        @Test\n        void leavesTheStockAloneWhenItRefuses() {\n            assertThrows(OutOfStockException.class, () -> book.take(3));\n            assertEquals(2, book.getStock());\n        }",
      "note": "The claim nobody thinks to write: a refused `take` changes nothing. The detour below is about this test."
    },
    {
      "code": "    }\n}"
    }
  ]
}
```

The wrong picture of a test class is the one ordinary Java gives: one object, its methods called one
after another, each seeing what the last one left behind. **JUnit makes a new instance of the test
class for every test method**, runs the `@BeforeEach` methods on it, runs the one test, and throws
the instance away. With a nested class it makes a new outer instance and a new inner one:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Three rows, one per test of the nested class Take. In every row JUnit makes a new BookTest, numbered 1, 2 and 3, then a new Take inside it, then runs the @BeforeEach method aBookWithTwoCopies, which builds a book with two copies, and then runs one test: lowersTheStock takes 2 and leaves the stock at 0; refusesMoreThanThereIs asks for 3 and is refused; leavesTheStockAloneWhenItRefuses asks for 3 and finds the stock still at 2. Nothing a test changes reaches the next one.\"><text x=\"66.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the outer class</text><text x=\"196.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the nested class</text><text x=\"355.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">@BeforeEach</text><text x=\"578.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one @Test</text><rect x=\"6\" y=\"44\" width=\"120\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"66\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new BookTest()</text><text x=\"66\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">#1</text><rect x=\"144\" y=\"44\" width=\"104\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"196\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new Take()</text><text x=\"196\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inside #1</text><rect x=\"266\" y=\"44\" width=\"178\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">aBookWithTwoCopies()</text><text x=\"355\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a book with 2 copies</text><rect x=\"462\" y=\"44\" width=\"232\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"578\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">lowersTheStock()</text><text x=\"578\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">takes 2: the stock is 0</text><line x1=\"126\" y1=\"70\" x2=\"137\" y2=\"70\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"144,70 136,66 136,74\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"248\" y1=\"70\" x2=\"259\" y2=\"70\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"266,70 258,66 258,74\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"444\" y1=\"70\" x2=\"455\" y2=\"70\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"462,70 454,66 454,74\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"6\" y=\"118\" width=\"120\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"66\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new BookTest()</text><text x=\"66\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">#2</text><rect x=\"144\" y=\"118\" width=\"104\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"196\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new Take()</text><text x=\"196\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inside #2</text><rect x=\"266\" y=\"118\" width=\"178\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">aBookWithTwoCopies()</text><text x=\"355\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a book with 2 copies</text><rect x=\"462\" y=\"118\" width=\"232\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"578\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">refusesMoreThanThereIs()</text><text x=\"578\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">asks for 3: refused</text><line x1=\"126\" y1=\"144\" x2=\"137\" y2=\"144\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"144,144 136,140 136,148\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"248\" y1=\"144\" x2=\"259\" y2=\"144\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"266,144 258,140 258,148\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"444\" y1=\"144\" x2=\"455\" y2=\"144\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"462,144 454,140 454,148\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"6\" y=\"192\" width=\"120\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"66\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new BookTest()</text><text x=\"66\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">#3</text><rect x=\"144\" y=\"192\" width=\"104\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"196\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new Take()</text><text x=\"196\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inside #3</text><rect x=\"266\" y=\"192\" width=\"178\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">aBookWithTwoCopies()</text><text x=\"355\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a book with 2 copies</text><rect x=\"462\" y=\"192\" width=\"232\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"578\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">leavesTheStockAloneWhenItRefuses()</text><text x=\"578\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">asks for 3: still 2</text><line x1=\"126\" y1=\"218\" x2=\"137\" y2=\"218\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"144,218 136,214 136,222\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"248\" y1=\"218\" x2=\"259\" y2=\"218\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"266,218 258,214 258,222\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"444\" y1=\"218\" x2=\"455\" y2=\"218\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"462,218 454,214 454,222\" fill=\"var(--phosphor-dim)\"></polygon><text x=\"350\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Nothing a test changes reaches the next one: each starts from the same book.</text></svg>", "caption": "How JUnit runs the three tests of BookTest.Take: a new pair of instances and a new book for every test, in whatever order it picks."}
```

That is why `leavesTheStockAloneWhenItRefuses` can expect two copies even if `lowersTheStock`, which
took both, happened to run before it. The tests do not know about each other, and **the order JUnit
runs them in is fixed, but deliberately not tied to the order of the file**: nothing should depend
on it.

## A detour: one book for all three

`@BeforeAll` runs once per class, before any test, and has to be `static` because no instance exists
yet. It is the place for set-up that is expensive and that no test changes, such as starting a
server the tests only read from. Use it here for the book, which every test changes, and see what happens:

```
(capture beforeall-edit missing)
```

```
(capture beforeall-run missing)
```

Two of three fail, and the messages say why: `but was: <0>`, `Only 0 of 'Dom Casmurro' left`.
`lowersTheStock` ran first and took both copies from the one shared book, and the other two tests
found it empty. **Neither failing test is wrong, and neither is the code; the fixture is.** In a
bigger class the symptom is worse than this, because it moves: a test that passes alone and fails in
the full run, or the other way round, depending on what ran before it. Put the file back:

```
(capture beforeall-back missing)
```

## OrderTest, with AssertJ

`assertEquals(2, book.getStock())` puts the expected value first and the actual second, and nothing
but habit stops you writing them the other way round. **AssertJ** starts from the actual value
instead: `assertThat(actual)`, then a method that says what it should be. The starter brought it,
and `OrderTest` uses it. Create `src/test/java/com/example/bookshop/ordering/OrderTest.java`:

```schooling-example
{
  "language": "java",
  "file": "OrderTest.java",
  "parts": [
    {
      "code": "package com.example.bookshop.ordering;\n\nimport static org.assertj.core.api.Assertions.assertThat;\n\nimport java.time.Instant;\n\nimport org.junit.jupiter.api.Test;\n\nimport com.example.bookshop.catalogue.Author;\nimport com.example.bookshop.catalogue.Book;\n",
      "note": "One static import, `assertThat`, is the whole of AssertJ's entry point. Everything else is a method on the object it returns."
    },
    {
      "code": "class OrderTest {\n\n    private final Author machado = new Author(\"Machado de Assis\");\n",
      "note": "A field shared by the tests is fine when nothing changes it: no test modifies an `Author`."
    },
    {
      "code": "    @Test\n    void totalIsTheSumOfQuantityTimesPrice() {\n        Order order = new Order(\"ana\", Instant.parse(\"2026-10-16T12:00:00Z\"));\n        order.add(new Book(\"9786500000016\", \"Dom Casmurro\", machado, 3990, 5), 2);\n        order.add(new Book(\"9786500000054\", \"Quincas Borba\", machado, 3690, 5), 1);\n\n        assertThat(order.totalCents()).isEqualTo(11670);\n        assertThat(order.getLines()).extracting(OrderLine::getQuantity).containsExactly(2, 1);\n    }\n",
      "note": "`assertThat(x)` picks an assertion object by the type of `x`, here an `int`, and **the editor's completion then offers only what makes sense for that type**. `11670` is 2 × 3990 + 3690. `extracting` turns the list of lines into the list of their quantities, and `containsExactly` checks those values in that order."
    },
    {
      "code": "    @Test\n    void anEmptyOrderCostsNothing() {\n        assertThat(new Order(\"ana\", Instant.EPOCH).totalCents()).isZero();\n    }",
      "note": "`isZero()` reads better than `isEqualTo(0)` and fails with the same message."
    },
    {
      "code": "}"
    }
  ]
}
```

Run every test in the project:

```
(capture all-run missing)
```

Fifteen tests in three classes. One line is odd: `Running take` and `Tests run: 3 ... in take`,
followed by `Tests run: 0 ... in com.example.bookshop.catalogue.BookTest`. **Surefire reports a nested
class as a class of its own, under its display name**, and the outer class, which holds no test
methods directly, as zero. The three tests ran once each. The console launcher shows the structure
JUnit sees:

```
(capture launcher-book missing)
```

## What AssertJ says when it fails

The reason to prefer it is the message. Change the expected quantities to `containsExactly(1, 2)`,
the wrong order, and run the class:

```
(capture assertj-order missing)
```

The message shows the whole list it got, the whole list it expected, and **each position where the
two differ**. A bare `assertTrue(quantities.equals(List.of(1, 2)))` would have printed `expected:
<true> but was: <false>`, and you would be adding a `println` to find out what the list held. Put
the order back and break the total instead:

```
(capture assertj-total missing)
```

`expected: 11680` and `but was: 11670`, each on its own line, so the two numbers sit one above the
other. Put the file back and check that all fifteen pass:

```
(capture assertj-back missing)
```

Both libraries are on the classpath and the bookshop uses both, which is common: JUnit's
`assertThrows` for exceptions and its assertions for one-line checks, AssertJ where a message has to
describe a collection or an object. AssertJ has its own way to check an exception,
`assertThatThrownBy`, for a project that wants one style throughout.
