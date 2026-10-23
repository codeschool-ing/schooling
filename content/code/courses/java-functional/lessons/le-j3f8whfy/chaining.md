---
title: Working with the box closed
version: 1
---

**You use an `Optional` without opening it.** `map`, `flatMap` and `filter` work on the value if there
is one and pass an empty box through untouched; `orElse`, `orElseGet` and `orElseThrow` decide, once,
at the end, what an empty box means. The methods have the names they have on streams because an
`Optional` behaves like a stream of zero or one element.

```schooling-example
{
  "language": "java",
  "file": "Chaining.java",
  "parts": [
    {
      "code": "// Chaining.java: an Optional used without ever being opened\nimport java.util.Optional;\n\npublic class Chaining {"
    },
    {
      "code": "    static String translatorOf(String title) {\n        return Catalogue.find(title)\n                .map(Catalogue.Edition::translator)\n                .orElse(\"no translator\");\n    }",
      "note": "`map` turns the edition into its translator. If the edition is missing, or the translator is `null`, the result is an empty box, and `orElse` supplies the words to print instead."
    },
    {
      "code": "\n    static Optional<String> affordableTitle(String title, long maxCents) {\n        return Catalogue.find(title)\n                .filter(e -> e.priceCents() <= maxCents)\n                .map(Catalogue.Edition::title);\n    }",
      "note": "`filter` empties the box when the value fails the test. The caller gets an `Optional<String>` and still decides what an empty one means."
    },
    {
      "code": "\n    static String expensiveDefault() {\n        System.out.println(\"  (computing a default)\");\n        return \"unknown\";\n    }",
      "note": "A default that costs something, and says when it runs."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        System.out.println(translatorOf(\"The Devil to Pay in the Backlands\"));\n        System.out.println(translatorOf(\"Dom Casmurro\"));\n        System.out.println(translatorOf(\"Moby-Dick\"));",
      "note": "Three calls: a translation, an original with a `null` translator, and a title the catalogue lacks. None of them needed an `if`."
    },
    {
      "code": "\n        System.out.println(affordableTitle(\"Dom Casmurro\", 4000));\n        System.out.println(affordableTitle(\"Grande Sertão: Veredas\", 4000));",
      "note": "Present and under the limit; present and over it, so `filter` emptied the box."
    },
    {
      "code": "\n        System.out.println(\"orElse:\");\n        System.out.println(Catalogue.find(\"Dom Casmurro\").map(Catalogue.Edition::author).orElse(expensiveDefault()));\n        System.out.println(\"orElseGet:\");\n        System.out.println(Catalogue.find(\"Dom Casmurro\").map(Catalogue.Edition::author).orElseGet(Chaining::expensiveDefault));",
      "note": "`orElse` takes a value, so its argument is computed before the call, whether or not it is needed. `orElseGet` takes a `Supplier` (lesson 2) and calls it only for an empty box."
    },
    {
      "code": "\n        Catalogue.find(\"Moby-Dick\").ifPresentOrElse(\n                e -> System.out.println(\"found \" + e.title()),\n                () -> System.out.println(\"not in the catalogue\"));\n        System.out.println(Catalogue.find(\"Moby-Dick\").or(() -> Catalogue.find(\"Dom Casmurro\")).map(Catalogue.Edition::title).orElseThrow());\n    }\n}\n",
      "note": "`ifPresentOrElse` runs one of two actions. `or` tries another `Optional` when the first is empty: here, a fallback title."
    }
  ],
  "output": "James L. Taylor and Harriet de Onís\nno translator\nno translator\nOptional[Dom Casmurro]\nOptional.empty\norElse:\n  (computing a default)\nMachado de Assis\norElseGet:\nMachado de Assis\nnot in the catalogue\nDom Casmurro"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three rows run through the same chain: find, then map to the translator, then orElse. For a translation, the box holds the edition, then the translator's name, and orElse returns the name. For Dom Casmurro, the box holds the edition, then map gets null and the box becomes empty, and orElse returns no translator. For Moby-Dick, find returns an empty box, map is skipped, and orElse returns no translator.\"><defs><marker id=\"chain-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"215\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">find(title)</text><text x=\"405\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">map(translator)</text><text x=\"605\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">orElse(...)</text><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a translation</text><rect x=\"140\" y=\"36\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Edition</text><path d=\"M290 58 L326 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"330\" y=\"36\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"James L. ...\"</text><path d=\"M480 58 L526 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"530\" y=\"36\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">\"James L. ...\"</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Dom Casmurro</text><rect x=\"140\" y=\"100\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Edition</text><path d=\"M290 122 L326 122\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"330\" y=\"100\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">empty: null</text><path d=\"M480 122 L526 122\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"530\" y=\"100\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">\"no translator\"</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Moby-Dick</text><rect x=\"140\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"215.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">empty</text><path d=\"M290 186 L326 186\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"330\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">empty</text><path d=\"M480 186 L526 186\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#chain-ah-paperdim)\"></path><rect x=\"530\" y=\"164\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">\"no translator\"</text></svg>", "caption": "An empty box passes through every step untouched, and orElse decides once, at the end, what it means."}
```

## `map` and `null`

`translatorOf("Dom Casmurro")` found the edition, and `map(Edition::translator)` got `null` back.
**`map` turns a `null` result into an empty box**, so the chain carried on as if there had been no
edition at all, and `orElse` answered. That is how `Optional` absorbs the old `null` fields without a
check at every step.

When the function you map with already returns an `Optional`, `map` would wrap it again into an
`Optional<Optional<String>>`; `flatMap` unwraps one level, exactly as it flattened streams in lesson
7 section 02.

## `orElse` computes its argument anyway

The output shows `(computing a default)` under `orElse:` although Dom Casmurro has an author and the
default was thrown away. **The argument of `orElse` is an ordinary value, evaluated before `orElse`
is called.** For a constant that costs nothing; for a database query, a log line or an object built
from scratch it costs every time. `orElseGet` takes a recipe instead and runs it only when the box is
empty, which is why nothing was printed under `orElseGet:`.
