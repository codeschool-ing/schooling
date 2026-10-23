---
title: The four shapes
version: 1
---

**You rarely need to write a functional interface, because `java.util.function` already has one
for almost every shape a lambda takes.** Shape here means only two things: what goes in, and what
comes out. Four answers cover nearly every case:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four rows, one per interface. Function takes a value of type T and gives back a value of type R. Predicate takes a T and gives back true or false. Supplier takes nothing and gives back a T. Consumer takes a T and gives back nothing.\"><defs><marker id=\"four-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"four-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what goes in</text><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what comes out</text><rect x=\"50\" y=\"44\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">T</text><rect x=\"260\" y=\"44\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"58.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Function&lt;T, R&gt;</text><text x=\"360.0\" y=\"73.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">apply()</text><rect x=\"550\" y=\"44\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">R</text><path d=\"M170 66 L256 66\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-paperdim)\"></path><path d=\"M460 66 L546 66\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-phosphor)\"></path><rect x=\"50\" y=\"108\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">T</text><rect x=\"260\" y=\"108\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Predicate&lt;T&gt;</text><text x=\"360.0\" y=\"137.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">test()</text><rect x=\"550\" y=\"108\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">boolean</text><path d=\"M170 130 L256 130\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-paperdim)\"></path><path d=\"M460 130 L546 130\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-phosphor)\"></path><rect x=\"50\" y=\"172\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nothing</text><rect x=\"260\" y=\"172\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"186.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Supplier&lt;T&gt;</text><text x=\"360.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">get()</text><rect x=\"550\" y=\"172\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">T</text><path d=\"M170 194 L256 194\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-paperdim)\"></path><path d=\"M460 194 L546 194\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-phosphor)\"></path><rect x=\"50\" y=\"236\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">T</text><rect x=\"260\" y=\"236\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"250.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Consumer&lt;T&gt;</text><text x=\"360.0\" y=\"265.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">accept()</text><rect x=\"550\" y=\"236\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nothing</text><path d=\"M170 258 L256 258\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-paperdim)\"></path><path d=\"M460 258 L546 258\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#four-ah-phosphor)\"></path></svg>", "caption": "The four shapes are told apart by what goes in and what comes out."}
```

| interface | method | in | out | a question it answers |
|---|---|---|---|---|
| `Function<T, R>` | `R apply(T t)` | one value | one value | what is this turned into? |
| `Predicate<T>` | `boolean test(T t)` | one value | `true` or `false` | does this one pass? |
| `Supplier<T>` | `T get()` | nothing | one value | give me one |
| `Consumer<T>` | `void accept(T t)` | one value | nothing | do something with this |

The names are worth learning because **an API's signature tells you what it will do with your
lambda**. `removeIf(Predicate)` will test each element; `forEach(Consumer)` will hand each one over
and ignore what comes back; `orElseGet(Supplier)` in lesson 10 will call your lambda only when it
needs a value.

## Each one, run

```schooling-example
{
  "language": "java",
  "file": "TheFour.java",
  "parts": [
    {
      "code": "// TheFour.java: the four shapes, and their two-argument cousins\nimport java.util.ArrayList;\nimport java.util.List;\nimport java.util.function.BiFunction;\nimport java.util.function.BinaryOperator;\nimport java.util.function.Consumer;\nimport java.util.function.Function;\nimport java.util.function.Predicate;\nimport java.util.function.Supplier;\nimport java.util.function.UnaryOperator;\n\npublic class TheFour {\n    public static void main(String[] args) {"
    },
    {
      "code": "        Function<String, Integer> words = s -> s.split(\" \").length;",
      "note": "A `Function` turns a `String` into an `Integer`. The two type arguments are the input and the output, in that order."
    },
    {
      "code": "        Predicate<String> longTitle = s -> words.apply(s) > 3;",
      "note": "A `Predicate` is a test. This one calls the `Function` above, which it captured like any other local."
    },
    {
      "code": "        Supplier<List<String>> newShelf = () -> new ArrayList<>();",
      "note": "A `Supplier` takes nothing. Each call to `get` runs the body again, so each shelf is a new list."
    },
    {
      "code": "        Consumer<String> announce = s -> System.out.println(\"new: \" + s);",
      "note": "A `Consumer` takes a value and returns nothing. It is there for its effect: printing, saving, sending."
    },
    {
      "code": "        BiFunction<String, Integer, String> cut = (s, n) -> s.substring(0, n);\n        UnaryOperator<String> shout = s -> s.toUpperCase();\n        BinaryOperator<Integer> larger = (a, b) -> a >= b ? a : b;",
      "note": "The cousins: `Bi` takes two inputs. `UnaryOperator<T>` is a `Function<T, T>` and `BinaryOperator<T>` a `BiFunction<T, T, T>`, named for the common case where everything has one type."
    },
    {
      "code": "\n        List<String> shelf = newShelf.get();\n        for (String title : List.of(\"Dune\", \"One Hundred Years of Solitude\", \"Emma\")) {\n            if (longTitle.test(title)) {\n                shelf.add(title);\n                announce.accept(title);\n            }\n        }\n        System.out.println(shelf + \" \" + newShelf.get());\n        System.out.println(cut.apply(\"Solitude\", 4) + \" \" + shout.apply(\"emma\") + \" \" + larger.apply(3, 7));\n    }\n}\n",
      "note": "None of the lambdas ran until here. `newShelf.get()` was called twice and gave two different lists, one filled and one empty."
    }
  ],
  "output": "new: One Hundred Years of Solitude\n[One Hundred Years of Solitude] []\nSoli EMMA 7"
}
```

`longTitle` let one title through, and `announce` printed it. The two shelves at the end are the
proof that **a `Supplier` is a recipe, not a value**: `get` ran the body twice and built two lists.
The same idea makes a `Supplier` the right type for anything expensive that may not be needed,
because nothing is built until somebody asks.

## When the names are not enough

There are interfaces for two inputs (`BiFunction`, `BiPredicate`, `BiConsumer`) and none for three.
That is deliberate: **a lambda that needs three inputs is usually asking for a record** (lesson 29
of `java`) that groups them, or for an interface of your own with a name that says what the three
mean. Section 05 writes one, for a different reason.
