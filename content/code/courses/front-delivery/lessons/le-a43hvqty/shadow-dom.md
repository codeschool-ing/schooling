---
title: Shadow DOM
version: 1
---

**A shadow root is a second tree of elements attached to one element, and the page's selectors stop at its
edge.** `<planner-session>` has two trees from the moment its constructor runs. The **light DOM** is what
the page wrote: the tag, its attributes, and the text *JavaScript* between its tags. The **shadow tree**
is what the element draws: a style sheet, a slot, a span for the date, a button and a hidden *done*. The
browser renders the shadow tree in place of the light one, with the light content shown wherever the
shadow tree puts a slot.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two trees for one element. The light DOM is what the page wrote: planner-session with the attributes id, date and minutes, holding the text JavaScript. The shadow tree is what the element draws: a style sheet, a slot, a span with class when, a button with part button, and a hidden span saying done. The light text is drawn where the slot is, and the row on screen reads JavaScript, 2026-10-15 · 45 min, and a Mark done button.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">light DOM: what the page wrote</text><rect x=\"20\" y=\"36\" width=\"300\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;planner-session id=\"session-6\"</text><text x=\"48\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">date=\"2026-10-15\" minutes=\"45\"&gt;</text><text x=\"48\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">JavaScript</text><text x=\"32\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;/planner-session&gt;</text><text x=\"400\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shadow tree: what the element draws</text><rect x=\"400\" y=\"36\" width=\"300\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"412\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">#shadow-root (open)</text><text x=\"428\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;style&gt;…&lt;/style&gt;</text><text x=\"428\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;slot&gt;&lt;/slot&gt;</text><text x=\"428\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;span class=\"when\"&gt;</text><text x=\"428\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;button part=\"button\"&gt;</text><text x=\"428\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;span class=\"done\" hidden&gt;</text><path d=\"M 125 104 C 220 104, 300 99, 418 99\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"410\" y1=\"99\" x2=\"418\" y2=\"99\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,99.0 410.6,102.1 410.6,95.9\" fill=\"var(--phosphor)\"></polygon><text x=\"250\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">drawn where the slot is</text><rect x=\"20\" y=\"200\" width=\"680\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">on screen</text><text x=\"120\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">JavaScript</text><text x=\"206\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2026-10-15 · 45 min</text><rect x=\"350\" y=\"207\" width=\"90\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Mark done</text></svg>", "caption": "The page writes the light DOM and the element draws the shadow tree; the light content appears at the slot."}
```

## What the boundary keeps apart

Three things the page does every day stop working across the edge, and each is the point:

- **Selectors do not match inside it.** The demo page's `main button { background: red }` reaches every button
  in the page's own tree and none in a shadow tree. The same is true the other way: the `.when` rule in
  the element's style sheet cannot paint a `.when` somewhere else in the page.
- **`querySelector` does not find what is inside it.** `document.querySelector("button")` in the demo page
  returns `null`; the button is reached through the element, as
  `document.querySelector("#session-6").shadowRoot.querySelector("button")`.
- **Ids are private to their tree.** Two rows can both contain an element with the same id inside their
  shadow trees, and neither clashes with the page. That also means a page's `<label for="…">` or
  `aria-labelledby` cannot point at something inside, which the section on accessibility comes back to.

What the boundary does not stop is just as important. The shadow tree is still part of the page as the
browser draws it: it is laid out with everything else, it is read by screen readers, and its button is in
the order the Tab key follows.

## Open or closed

`attachShadow({ mode: "open" })` lets any script reach the tree through `element.shadowRoot`, which is
how a test or a browser's developer tools look inside. `mode: "closed"` makes `shadowRoot` return `null`
for everybody but the class that kept the reference. **Closed is not security**: a script running in the
same page can still replace `attachShadow` before the element is defined, and the tree is visible in
developer tools either way. It mostly makes a component harder to test, which is why the planner's element
is open and almost every published design system's is too.

## Without JavaScript

A shadow tree built in a constructor exists only once the script runs. For a page rendered on the server,
HTML has a way to write one directly, **declarative shadow DOM**: a `<template shadowrootmode="open">` as
the element's first child becomes its shadow root as the HTML is parsed, before any script. Every current
browser supports it. The planner is drawn in the browser, so its element builds its tree in the
constructor; a server-rendered page would send the template and let the class find the root already
attached, which `this.shadowRoot` would then return.
