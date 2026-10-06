---
title: Cascade layers
version: 1
---

Lesson 5 section 07 drew the cascade as four questions, and the second one, **layers**, was left for this lesson. A cascade layer is a named group of rules, and **between layers, the order of the layers decides before specificity is asked**. That makes section 09's file order something the browser enforces instead of something everybody has to remember. Here are four layers, three of them with rules, and a link that two of them style:

```css
@layer reset, base, components, utilities;

@layer base {
  #events a { color: #1d1d1b; text-decoration: underline; }
}

@layer components {
  .button { color: white; background: #2f6f4e; text-decoration: none; }
}

@layer utilities {
  .muted { color: #555555; }
}
```

The first line declares the layers' **order**: `reset` is the weakest, `utilities` the strongest. The rules then go into their layer with `@layer name { … }`. The link has the class `button` and sits inside `#events`:

```
ana@laptop:~/site$ probe layers.html rules .button color
a:-webkit-any-link (0,1,1)  color: -webkit-link             browser default
#events a (1,0,1)           color: #1d1d1b                  layers.css @layer base
.button (0,1,0)             color: white                    layers.css @layer components
computed color: rgb(255, 255, 255)
```

`#events a` has an id, **(1,0,1)**, and without layers it would beat `.button` at **(0,1,0)** easily. **It lost**, and the link is white: `#events a` is in `base`, `.button` is in `components`, and `components` comes later in the order. Specificity was never compared, because the two rules were in different layers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The layers declared by @layer reset, base, components, utilities, drawn from weakest at the bottom to strongest at the top, with unlayered styles above them all. The base layer&#x27;s #events a, specificity 1,0,1, loses to the components layer&#x27;s .button, 0,1,0, because components comes later. An unlayered a, 0,0,1, beats both.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">stronger</text><rect x=\"20\" y=\"26\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">unlayered styles</text><text x=\"210\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a { color: #8a1c1c; }  (0,0,1)</text><rect x=\"20\" y=\"72\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer utilities</text><text x=\"210\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">.muted { color: #555555; }  (0,1,0)</text><rect x=\"20\" y=\"118\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer components</text><text x=\"210\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">.button { color: white; }  (0,1,0)</text><rect x=\"20\" y=\"164\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer base</text><text x=\"210\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">#events a { color: #1d1d1b; }  (1,0,1)</text><rect x=\"20\" y=\"210\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer reset</text><text x=\"20\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">weaker</text><text x=\"510\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">For normal declarations, a later</text><text x=\"510\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">layer beats an earlier one</text><text x=\"510\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">whatever the specificity, and</text><text x=\"510\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">unlayered styles beat every</text><text x=\"510\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">layer.</text><text x=\"510\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Specificity only decides between</text><text x=\"510\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">rules in the same layer.</text><text x=\"510\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">!important turns the layer</text><text x=\"510\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">order round.</text></svg>", "caption": "Layer order is decided before specificity, which is the point of having layers."}
```

## Unlayered styles win

One more rule, appended outside any layer, `a { color: #8a1c1c; }`:

```
ana@laptop:~/site$ probe layers-plus.html rules .button color
a:-webkit-any-link (0,1,1)  color: -webkit-link             browser default
#events a (1,0,1)           color: #1d1d1b                  layers-plus.css @layer base
.button (0,1,0)             color: white                    layers-plus.css @layer components
a (0,0,1)                   color: #8a1c1c                  layers-plus.css
computed color: rgb(138, 28, 28)
```

A plain `a`, specificity **(0,0,1)**, and it **beat the layered rules**: the link is red. **Styles that are in no layer beat every layer.** That is designed for a reason: a site can put a third-party stylesheet or its own older CSS into a low layer, and anything new written outside layers wins over it without a fight. It is also the trap: a stylesheet that layers some of its rules and not others gets surprises like this one.

## Using them

`@import url("reset.css") layer(reset);` puts an imported file into a layer, which is what `main.css` in section 09 did. Two details: **`!important` reverses the layer order**, so an important declaration in `reset` beats one in `utilities`, for the same reason as the origins in lesson 5; and **DevTools shows the layer** beside each rule in the Styles pane, as `probe rules` printed it. Layers are supported in every current browser. They do not replace keeping specificity low; they make it matter less.
