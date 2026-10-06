---
title: The page is a tree
version: 1
---

::: track frontend backend qa
You wrote pages in html-css, so the markup in this section is familiar. What is new is the other side
of it: **the browser does not keep your HTML as text**. It reads it once and builds a structure of
objects that a script can reach.
:::

::: track *
A web page is written in **HTML**: elements in angle brackets, such as `<h1>My shelf</h1>`, nested
inside each other. The `html-css` course teaches it properly; this one needs only that much. What
matters here is the other side of it: **the browser does not keep the HTML as text**. It reads it once
and builds a structure of objects that a script can reach.
:::

That structure is the **DOM**, the Document Object Model. A script can walk it:

```html
<!doctype html>
<html lang="en">
<head><title>Shelf</title></head>
<body>
  <h1>My shelf</h1>
  <ul id="books">
    <li class="book">Iracema</li>
    <li class="book read">Dom Casmurro</li>
  </ul>
  <script>
    function walk(node, depth) {
      const pad = "  ".repeat(depth);
      if (node.nodeType === Node.TEXT_NODE) {
        if (node.textContent.trim()) console.log(pad + "#text " + JSON.stringify(node.textContent));
        return;
      }
      if (node.nodeType === Node.ELEMENT_NODE && node.tagName !== "SCRIPT") {
        console.log(pad + node.tagName.toLowerCase());
        for (const child of node.childNodes) walk(child, depth + 1);
      }
    }
    walk(document.documentElement, 0);
    console.log(document.body.childNodes.length, document.body.children.length);
  </script>
</body>
</html>
```

```
ana@dev:~/js$ page tree.html
html
  head
    title
      #text "Shelf"
  body
    h1
      #text "My shelf"
    ul
      li
        #text "Iracema"
      li
        #text "Dom Casmurro"
6 3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The tree the browser built from tree.html. The html element has two children, head and body. head holds title, which holds the text Shelf. body holds h1, with the text My shelf, and ul with the id books, which holds two li elements with the texts Iracema and Dom Casmurro.\"><rect x=\"305.0\" y=\"14\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">html</text><rect x=\"95.0\" y=\"74\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">head</text><rect x=\"415.0\" y=\"74\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">body</text><rect x=\"95.0\" y=\"134\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><rect x=\"95.0\" y=\"194\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"150.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;Shelf&quot;</text><rect x=\"275.0\" y=\"134\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">h1</text><rect x=\"500.0\" y=\"134\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ul#books</text><rect x=\"275.0\" y=\"194\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"330.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;My shelf&quot;</text><rect x=\"425.0\" y=\"194\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">li.book</text><rect x=\"575.0\" y=\"194\" width=\"130\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">li.book.read</text><rect x=\"425.0\" y=\"254\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"480.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;Iracema&quot;</text><rect x=\"575.0\" y=\"254\" width=\"130\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"640.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;Dom Casmurro&quot;</text><path d=\"M360 40 L150 74\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M360 40 L470 74\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M150 100 L150 134\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M150 160 L150 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M470 100 L330 134\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M470 100 L560 134\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M330 160 L330 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M560 160 L480 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M560 160 L640 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M480 220 L480 254\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M640 220 L640 254\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"20\" y=\"44\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">element</text><rect x=\"20\" y=\"14\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"80.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">text node</text></svg>", "caption": "A page's markup becomes a tree of objects, and a script changes the page by changing the tree."}
```

**Every element became an object, and so did every piece of text inside one.** They are all called
**nodes**, and they hang in a tree: `html` at the root, `head` and `body` below it, the list below the
body, each item below the list, and each title as a text node below its item. The script printed the
tree by asking every node for its children, which is the shape of almost every DOM program.

## Elements and text nodes

The last line, `6 3`, is worth reading closely. `document.body.childNodes` counted **six**, while
`children` counted **three**: `h1`, `ul` and `script`. The other three are **text nodes holding only
whitespace**, the line breaks and indentation between the tags, which the walk skipped and the
browser kept. `children` gives only elements, which is nearly always what you want; the rest of this
lesson uses the element versions of every property.

## What the tree is for

The tree is not a copy of the page; **it is the page**. Change a node and the browser redraws what it
shows. That is the whole of this lesson: find a node, change it, make new ones. The global
`document` is the tree's entry point, and every method in the next sections hangs off it or off an
element found through it.
