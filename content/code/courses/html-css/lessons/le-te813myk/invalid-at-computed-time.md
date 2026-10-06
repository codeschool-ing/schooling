---
title: When a variable holds the wrong kind of value
version: 1
---

Lesson 5 section 02 said that a declaration the browser does not understand is skipped, and that the declaration before it then applies. **With `var()`, that is not what happens**, and the difference catches everybody once. The last paragraph in `fallback.html` sets its colour twice:

```css
.wrong {
  color: #8a1c1c;
  color: var(--gap);
}
```

`--gap` is `24px`, a length. A length is not a colour. The obvious expectation is that the second declaration is thrown away and the paragraph is red. Here is what the browser decided:

```
ana@laptop:~/site$ probe fallback.html rules .wrong color
.wrong (0,1,0)  color: #8a1c1c                  <style> in the page
.wrong (0,1,0)  color: var(--gap)               <style> in the page
computed color: rgb(47, 111, 78)
```

**The paragraph is green**, `rgb(47, 111, 78)`, the colour of `<main>`. The red was not used, although it was right there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Why .wrong came out green. At parsing, both color declarations are accepted, because a var() cannot be checked until it is resolved. In the cascade, the later one, the line that reads --gap, wins. At computed-value time, --gap turns out to be 24px, not a colour, so the declaration is invalid, and the red declaration has already lost. The property then behaves as unset, and colour inherits the green of main.\"><defs><marker id=\"ah10\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">1. parsing</text><text x=\"196\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the red is valid; the line that reads --gap is accepted too,</text><text x=\"196\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">because nothing can check a var() before it is resolved.</text><line x1=\"100\" y1=\"58\" x2=\"100\" y2=\"74\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah10)\"></line><rect x=\"20\" y=\"76\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">2. cascade</text><text x=\"196\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Both match .wrong at (0,1,0). The later one wins:</text><text x=\"196\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the line that reads --gap.</text><line x1=\"100\" y1=\"120\" x2=\"100\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah10)\"></line><rect x=\"20\" y=\"138\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">3. computed value</text><text x=\"196\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">--gap is 24px, which is not a colour. The declaration is</text><text x=\"196\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">invalid at computed-value time, and the red is long gone.</text><line x1=\"100\" y1=\"182\" x2=\"100\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah10)\"></line><rect x=\"20\" y=\"200\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">4. result</text><text x=\"196\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">color behaves as unset, and colour inherits:</text><text x=\"196\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the green of main, rgb(47, 111, 78).</text></svg>", "caption": "A fallback written earlier in the same rule does not help: by the time the var() fails, it has already lost."}
```

The reason is when the check happens. When the stylesheet is read, `color: var(--gap)` cannot be checked: a `var()` could hold anything, and its value is not known until it is used on a particular element. So the declaration is accepted, the cascade runs, and the later declaration wins, exactly as lesson 5 section 09 described. Only then, when the browser computes the value for this element, does it find a length where a colour should be. By then the red has already lost, and the browser cannot go back to it. The declaration is **invalid at computed-value time**, and the property behaves as if it were `unset`: an inherited property, like `color`, inherits, and anything else takes its initial value.

## What follows from it

**A fallback inside the `var()` is the fallback that works**: `color: var(--gap, #8a1c1c)` would have been red, because the fallback is used when the variable is missing. It is not used when the variable has the wrong type, however; then the result is still the inherited green. **The real fix is to use variables for one kind of value each**, and to name them so that their kind is obvious: `--color-accent`, `--space-2`, never a name that could hold either.

There is a way to tell the browser the type, `@property`, which registers a custom property with a syntax such as `<color>` and an initial value. A registered property with a wrong value then falls back to that initial value instead of `unset`. It is also what lets a custom property be animated, which lesson 12 does not need. For a stylesheet of tokens, careful names do most of the work.
