---
title: Preflight, and the layers it lives in
version: 1
---

The stylesheet opens with `@layer theme, base, components, utilities;`, lesson 10 section 11's layer order. **`theme`** holds the custom properties. **`base`** holds **Preflight**, Tailwind's reset. **`components`** is empty until you add something, section 10. **`utilities`** holds the classes, last, so a utility wins over anything in the earlier layers whatever its specificity.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"The four cascade layers of a Tailwind stylesheet, weakest at the bottom: theme, holding the tokens; base, holding Preflight; components, holding your own classes such as .btn; and utilities, holding the utility classes. A button with btn and bg-stone-700 gets the stone background, because utilities comes after components.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">stronger</text><rect x=\"20\" y=\"26\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer utilities</text><text x=\"190\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the classes: p-4, bg-stone-700, md:grid-cols-2</text><rect x=\"20\" y=\"70\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer components</text><text x=\"190\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">yours, such as .btn with @apply</text><rect x=\"20\" y=\"114\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer base</text><text x=\"190\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Preflight, the reset, and your element rules</text><rect x=\"20\" y=\"158\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer theme</text><text x=\"190\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the tokens, as custom properties on :root</text><text x=\"20\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">weaker</text><text x=\"480\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">class=&quot;btn bg-stone-700&quot;:</text><text x=\"480\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the background is stone,</text><text x=\"480\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">because utilities comes</text><text x=\"480\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">after components.</text><text x=\"480\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The layer decides before</text><text x=\"480\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">specificity is compared,</text><text x=\"480\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lesson 10 section 11.</text></svg>", "caption": "Tailwind's output is lesson 10's layered stylesheet, generated."}
```

Preflight goes further than the reset of lesson 10. Here is a page with no classes at all, built with Tailwind:

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
    <main>
      <h1>This week</h1>
      <ul>
        <li><a href="events.html">Events</a></li>
        <li><a href="order.html">Order a book</a></li>
      </ul>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd bare -i input.css -o out.css --silent
ana@laptop:~/site$ probe bare/index.html style h1 font-size,font-weight style ul list-style-type,padding-left style a color,text-decoration-line
h1  font-size: 16px
h1  font-weight: 400
ul  list-style-type: none
ul  padding-left: 0px
a  color: rgb(0, 0, 0)
a  text-decoration-line: none
a  color: rgb(0, 0, 0)
a  text-decoration-line: none
```

The `<h1>` is **16px** and weight **400**: the same size and weight as body text. The list has no bullets and no indent. The links are **black like the text around them, with no underline**. Preflight removes every default the browser had, so that what you see is only what your classes say.

**Two of those defaults were doing a job.** The heading's size told a sighted reader it was a heading; give it a size back, `text-2xl`, and keep it an `<h1>`, because its role, lesson 2, is still what a screen reader announces. And **a link that looks like text cannot be found** without hovering over every word. WCAG's success criterion 1.4.1 asks that colour is not the only way to tell a link in a paragraph from the text around it, and Preflight has removed even the colour. Put an underline back on links inside text, with `underline` or with one rule in your input stylesheet:

```css
@layer base {
  main a { text-decoration-line: underline; }
}
```

Putting it in `base` keeps it below the utilities, so `no-underline` on a particular link still works.
