---
title: Returning behaviour
version: 1
---

**A method can return a lambda, and the lambda it returns can use the method's arguments long after
the method has finished.** That makes a method into a factory of rules: you give it the numbers,
and it gives you back behaviour built around them.

```schooling-example
{
  "language": "java",
  "file": "Factories.java",
  "parts": [
    {
      "code": "// Factories.java: methods that build rules and hand them back\nimport java.util.List;\nimport java.util.concurrent.atomic.AtomicInteger;\nimport java.util.function.Predicate;\nimport java.util.function.Supplier;\nimport java.util.function.UnaryOperator;\n\npublic class Factories {\n    record Book(String title, int pages) {}"
    },
    {
      "code": "\n    static Predicate<Book> atLeast(int pages) {\n        return b -> b.pages() >= pages;\n    }",
      "note": "`atLeast` returns a test. The `pages` it was called with is captured by the lambda, so each call builds a different test."
    },
    {
      "code": "\n    static UnaryOperator<Long> percentOff(int percent) {\n        return cents -> cents - cents * percent / 100;\n    }",
      "note": "The same idea for prices: give it a percentage, get back a function from a price to a lower price. Integer division rounds down to the cent."
    },
    {
      "code": "\n    static Supplier<String> orderNumbers(String prefix) {\n        AtomicInteger next = new AtomicInteger();\n        return () -> prefix + \"-\" + next.incrementAndGet();\n    }",
      "note": "A rule with state. `next` is never reassigned, so the lambda may capture it; the counter inside it changes, and lesson 15 explains why `AtomicInteger` is the safe way to do that."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        Predicate<Book> doorstop = atLeast(450);\n        Predicate<Book> anything = atLeast(0);\n        Book dune = new Book(\"Dune\", 412);\n        System.out.println(doorstop.test(dune) + \" \" + anything.test(dune));",
      "note": "Two tests from one factory. They differ only in the number each one captured."
    },
    {
      "code": "\n        UnaryOperator<Long> student = percentOff(15);\n        System.out.println(student.apply(8990L));",
      "note": "8990 cents with 15% off: 8990 minus 1348, the discount rounded down."
    },
    {
      "code": "\n        Supplier<String> lumen = orderNumbers(\"LUM\");\n        Supplier<String> atlas = orderNumbers(\"ATL\");\n        System.out.println(List.of(lumen.get(), lumen.get(), atlas.get(), lumen.get()));\n    }\n}\n",
      "note": "Each supplier has its own counter, made when `orderNumbers` was called. Asking `atlas` did not move `lumen` on."
    }
  ],
  "output": "false true\n7642\n[LUM-1, LUM-2, ATL-1, LUM-3]"
}
```

## Each call builds a new closure

`atLeast(450)` and `atLeast(0)` are two objects. Each holds its own copy of `pages`, copied when
it was built (lesson 1 section 06), so the two answer differently for the same book. A function
together with the values it captured is called a **closure**, and the factory pattern is closures
made on purpose.

`orderNumbers` shows the one way a closure carries state that changes. The variable `next` is
effectively final, because it always refers to the same `AtomicInteger`; what changes is the
counter inside that object. **The rule about captured locals is about the variable, not the
object it points at.** That is legal and sometimes exactly right, as here, and it is also the door
through which shared mutable state walks into code that was meant to be functional. When two
threads call `lumen.get()` at once, only the atomic counter keeps their numbers apart.

## Where this is used

The standard library is full of factories that return behaviour, and you have been reading their
names already:

| factory | returns |
|---|---|
| `Comparator.comparing(Book::title)` (lesson 5) | a `Comparator` built from a key |
| `Predicate.not(String::isBlank)` (lesson 5) | the opposite test |
| `Collectors.groupingBy(...)` (lesson 8) | a recipe for collecting a stream |
| `Function.identity()` | a function that returns its argument unchanged |

A configuration value read once at start-up, a threshold, a locale, a tax rate, can be turned into
a rule by a factory like `atLeast`, and the rest of the program then passes the rule around without
knowing the number inside it.
