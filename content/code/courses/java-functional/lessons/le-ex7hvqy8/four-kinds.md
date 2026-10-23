---
title: Four kinds of reference
version: 1
---

**A method reference is a lambda that only calls one existing method, written as the method's
name.** `s -> s.toUpperCase()` takes a string and calls one method on it with nothing added; the
reference `String::toUpperCase` says the same thing in fewer symbols, and the compiler builds the
same kind of object from it. The `::` separates where the method lives from its name, and there are
no brackets after the name, because nothing is being called yet.

There are four kinds, told apart by what is written before the `::`:

```schooling-example
{
  "language": "java",
  "file": "References.java",
  "parts": [
    {
      "code": "// References.java: the four kinds of method reference, each beside the lambda it replaces\nimport java.util.ArrayList;\nimport java.util.List;\nimport java.util.function.Function;\nimport java.util.function.Predicate;\nimport java.util.function.Supplier;\n\npublic class References {\n    public static void main(String[] args) {"
    },
    {
      "code": "        Function<String, Integer> parseLambda = s -> Integer.parseInt(s);\n        Function<String, Integer> parse = Integer::parseInt;",
      "note": "**Static**: a class name and a static method. The lambda's argument becomes the method's argument."
    },
    {
      "code": "\n        String shop = \"Lumen\";\n        Predicate<String> isShopLambda = s -> shop.equals(s);\n        Predicate<String> isShop = shop::equals;",
      "note": "**Bound**: an object and one of its methods. The object is chosen now; the lambda's argument is passed to the method."
    },
    {
      "code": "\n        Function<String, String> upperLambda = s -> s.toUpperCase();\n        Function<String, String> upper = String::toUpperCase;",
      "note": "**Unbound**: a class name and an instance method. The object is not chosen yet: the first argument becomes the object the method runs on."
    },
    {
      "code": "\n        Supplier<List<String>> shelfLambda = () -> new ArrayList<>();\n        Supplier<List<String>> shelf = ArrayList::new;",
      "note": "**Constructor**: a class name and `new`. Each call builds a new object, as the lambda would."
    },
    {
      "code": "\n        System.out.println(parse.apply(\"42\") + 1);\n        System.out.println(isShop.test(\"Lumen\") + \" \" + isShop.test(\"Atlas\"));\n        System.out.println(upper.apply(\"emma\"));\n        System.out.println(shelf.get());\n    }\n}\n",
      "note": "Each reference is used exactly as the lambda beside it would be: through the interface's own method."
    }
  ],
  "output": "43\ntrue false\nEMMA\n[]"
}
```

`parse.apply("42") + 1` printed 43, so the reference returned an `Integer`, not a string. `isShop`
compared against `"Lumen"`, the string it was bound to. `upper` ran `toUpperCase` on the argument
it was given. `shelf.get()` built a new empty list.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A table of the four kinds of method reference. Static, Integer::parseInt, becomes s -&gt; Integer.parseInt(s). Bound, shop::equals, becomes s -&gt; shop.equals(s), with the object fixed when the reference is made. Unbound, String::toUpperCase, becomes s -&gt; s.toUpperCase(), the first argument being the object. Constructor, ArrayList::new, becomes () -&gt; new ArrayList&lt;&gt;().\"><defs><marker id=\"kinds-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"90\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">kind</text><text x=\"255\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reference</text><text x=\"475\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the lambda it stands for</text><text x=\"645\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the object</text><rect x=\"30\" y=\"38\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">static</text><rect x=\"165\" y=\"38\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Integer::parseInt</text><rect x=\"380\" y=\"38\" width=\"190\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s -&gt; Integer.parseInt(s)</text><rect x=\"585\" y=\"38\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"645.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no object</text><path d=\"M345 62 L376 62\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#kinds-ah-paperdim)\"></path><rect x=\"30\" y=\"102\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">bound</text><rect x=\"165\" y=\"102\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">shop::equals</text><rect x=\"380\" y=\"102\" width=\"190\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s -&gt; shop.equals(s)</text><rect x=\"585\" y=\"102\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"645.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fixed when made</text><path d=\"M345 126 L376 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#kinds-ah-paperdim)\"></path><rect x=\"30\" y=\"166\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">unbound</text><rect x=\"165\" y=\"166\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">String::toUpperCase</text><rect x=\"380\" y=\"166\" width=\"190\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s -&gt; s.toUpperCase()</text><rect x=\"585\" y=\"166\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"645.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the first argument</text><path d=\"M345 190 L376 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#kinds-ah-paperdim)\"></path><rect x=\"30\" y=\"230\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">constructor</text><rect x=\"165\" y=\"230\" width=\"180\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">ArrayList::new</text><rect x=\"380\" y=\"230\" width=\"190\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">() -&gt; new ArrayList&lt;&gt;()</text><rect x=\"585\" y=\"230\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"645.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a new one each call</text><path d=\"M345 254 L376 254\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#kinds-ah-paperdim)\"></path></svg>", "caption": "Each reference is a lambda that only calls one method; where its object comes from is what tells them apart."}
```

## What the compiler checks

**A reference has a target type, exactly like a lambda** (lesson 1 section 05), and the compiler
checks that the named method fits it. `Integer::parseInt` fits `Function<String, Integer>` because
there is a `parseInt` that takes a `String` and returns an `int`, which is boxed to the `Integer` the
function promises. Write the same reference where a `Predicate<String>` is expected and the compiler
refuses it, since `parseInt` returns no `boolean`.

The choice between a lambda and a reference is about reading, never about speed. Both become an
object built through `invokedynamic`, and the JVM treats them alike.
