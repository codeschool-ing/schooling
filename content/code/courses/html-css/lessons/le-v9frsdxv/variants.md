---
title: Variants: states, widths, dark and motion
version: 2
---

A utility applies always. A **variant** is a prefix that applies it only in some condition: `hover:bg-andorinha-900`, `md:grid-cols-2`, `dark:bg-black`. Here is a page that uses several, `variants/index.html`, with a copy of `theme/input.css` beside it, built:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="out.css">
  </head>
  <body>
    <main id="page" class="min-h-screen bg-andorinha-50 p-4 text-andorinha-900 dark:bg-andorinha-900 dark:text-andorinha-50">
      <h1 class="text-2xl font-bold">This week</h1>
      <div id="events" class="mt-4 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <article class="bg-white p-4 dark:bg-black">Poetry reading</article>
        <article class="bg-white p-4 dark:bg-black">Book swap</article>
        <article class="bg-white p-4 dark:bg-black">Bookbinding</article>
      </div>
      <button id="reserve" type="button" class="mt-4 rounded-md bg-andorinha-700 px-4 py-2 text-white hover:bg-andorinha-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-andorinha-700 motion-safe:transition-colors">Reserve a place</button>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd variants -i input.css -o out.css --silent
ana@laptop:~/site$ grep -n "@media" variants/out.css
223:  @media (hover: hover) {
238:  @media (prefers-reduced-motion: no-preference) {
245:  @media (width >= 48rem) {
250:  @media (width >= 64rem) {
255:  @media (prefers-color-scheme: dark) {
```

Each variant became something this course has taught. **`hover:`** is wrapped in **`@media (hover: hover)`**, lesson 11 section 08, so a hover style is never stuck on a phone after a tap. **`motion-safe:`** is **`(prefers-reduced-motion: no-preference)`**, lesson 12 section 09's better pattern. **`md:`** and **`lg:`** are **`(width >= 48rem)`** and **`(width >= 64rem)`**, and **`dark:`** is **`(prefers-color-scheme: dark)`**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"Six variants and what each became in the built stylesheet. hover: became a hover rule inside a media query for hover-capable devices, lesson 11. focus-visible: became the :focus-visible pseudo-class, lesson 5. md: and lg: became width queries at 48 and 64rem, lesson 11. dark: became prefers-color-scheme dark, lesson 10. motion-safe: became prefers-reduced-motion no-preference, lesson 12.\"><defs><marker id=\"ah13v\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in the HTML</text><text x=\"300\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in the stylesheet</text><rect x=\"20\" y=\"26\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hover:bg-andorinha-900</text><line x1=\"256\" y1=\"38\" x2=\"292\" y2=\"38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (hover: hover) { … :hover … }</text><text x=\"700\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L11 · 08</text><rect x=\"20\" y=\"58\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">focus-visible:outline-2</text><line x1=\"256\" y1=\"70\" x2=\"292\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">:focus-visible</text><text x=\"700\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L5 · 05</text><rect x=\"20\" y=\"90\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">md:grid-cols-2</text><line x1=\"256\" y1=\"102\" x2=\"292\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (width &gt;= 48rem)</text><text x=\"700\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L11 · 03</text><rect x=\"20\" y=\"122\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lg:grid-cols-3</text><line x1=\"256\" y1=\"134\" x2=\"292\" y2=\"134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (width &gt;= 64rem)</text><text x=\"700\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L11 · 03</text><rect x=\"20\" y=\"154\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dark:bg-andorinha-900</text><line x1=\"256\" y1=\"166\" x2=\"292\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (prefers-color-scheme: dark)</text><text x=\"700\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L10 · 06</text><rect x=\"20\" y=\"186\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">motion-safe:transition-colors</text><line x1=\"256\" y1=\"198\" x2=\"292\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (prefers-reduced-motion: no-preference)</text><text x=\"700\" y=\"198\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L12 · 09</text></svg>", "caption": "Every variant is something an earlier lesson taught, with a shorter name."}
```

## Mobile first, built in

The breakpoints are `min-width` queries, so Tailwind is **mobile first**, lesson 11 section 02: a class with no prefix applies at every width, and `md:` adds to it from 48rem up.

```
ana@laptop:~/site$ probe --width 700 variants/index.html style "#events" grid-template-columns width 800 style "#events" grid-template-columns width 1100 style "#events" grid-template-columns
div#events  grid-template-columns: 668px
div#events  grid-template-columns: 376px 376px
div#events  grid-template-columns: 345.328px 345.328px 345.344px
```

At **700** the events are one column, **668** wide. At **800**, `md:grid-cols-2` gives two. At **1100**, `lg:grid-cols-3` gives three. `md:` does **not** mean "only on medium screens"; it means "from medium up", and to stop at a width you combine it with a `max-` variant: `md:max-lg:grid-cols-2`.

## States, and the reader's preferences

```
ana@laptop:~/site$ probe variants/index.html style "#reserve" background-color hover "#reserve" at 150 style "#reserve" background-color
button#reserve  background-color: rgb(47, 111, 78)
button#reserve  background-color: rgb(29, 29, 27)
ana@laptop:~/site$ probe --dark variants/index.html style "#page" background-color,color
main#page  background-color: rgb(29, 29, 27)
main#page  color: rgb(251, 248, 242)
```

The button is `rgb(47, 111, 78)` and becomes **`rgb(29, 29, 27)`** on hover, read 150 ms in, at the end of the colour transition that `motion-safe:transition-colors` gave it. In the dark scheme the page is **`rgb(29, 29, 27)`** with light text. Other variants work the same way: `focus-visible:`, `disabled:`, `aria-expanded:`, `first:`, `print:`, `motion-reduce:`. The button's `focus-visible:outline-2 focus-visible:outline-offset-2` is a visible focus ring, and lesson 5 section 05's rule holds here as everywhere: **whatever a hover changes, a keyboard focus needs too**.
