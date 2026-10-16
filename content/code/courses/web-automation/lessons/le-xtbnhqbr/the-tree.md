---
title: The page as a tree
version: 1
---

**A test can only act on what it can find, and a locator is the part of a test that finds it.**
Every click, every check of a price and every count of cards starts with one. This lesson is about
writing locators that still find the right element after the page has changed in ways that have
nothing to do with the defect you are looking for.

The usual first picture of a locator is an address: the element lives somewhere, and the locator
says where. **The page has no addresses.** It has a tree of elements, and a locator is a
description of one of them: *the card whose test id is `product-banana`*, *the second card in the
list*, *the button inside the card whose heading says Mango*. Several descriptions match the same
element today. What separates them is what has to stay true for each one to keep matching it.

## A program that counts

Lesson 1 used the Elements panel's search box to ask how many elements a selector matches. This
script asks the same question from a terminal, so that every selector in this lesson comes with
what it found on the real shop rather than what it ought to find. Save it as `count.mjs`:

```schooling-example
{"language": "javascript", "file": "count.mjs", "parts": [{"code": "// What the Elements panel's search box answers, printed: how many elements\n// each locator matches on the shop. Start the shop, then:\n//   node count.mjs 'locator' 'another locator' ...\nimport { chromium } from '@playwright/test';", "note": "The comment says how to run it. Like `look.mjs` in lesson 1, it uses Playwright's library and not its test runner."}, {"code": "const browser = await chromium.launch();\nconst page = await browser.newPage();\nawait page.goto('http://localhost:3000/');\nawait page.locator('#products[aria-busy=\"false\"]').waitFor();", "note": "Opens the shop and waits until the list says it is no longer busy. Counting straight after `goto` would count an empty list, because the cards arrive with a later request. Lesson 3 is about that wait."}, {"code": "for (const locator of process.argv.slice(2)) {\n  const found = page.locator(locator);\n  const n = await found.count();\n  console.log(String(n).padStart(3) + '  ' + locator);", "note": "`page.locator` takes a CSS selector, or XPath when the string starts with `//` or `xpath=`. `count()` answers at once and never waits, which is why the wait above is there."}, {"code": "  if (n === 1) {\n    const html = await found.evaluate((element) => element.outerHTML);\n    console.log(html.replace(/^/gm, '       '));\n  }\n}\nawait browser.close();", "note": "When exactly one element matches, it prints that element's HTML as the DOM holds it now, indented under the count. One is the number a locator for one thing has to find."}]}
```

With the shop running in another terminal (`npm start`), ask it for the Banana card by the
attribute the card carries for tests:

```
ana@laptop:~/quitanda$ node count.mjs '[data-testid="product-banana"]'
  1  [data-testid="product-banana"]
       <li class="card" id="card-3031" data-testid="product-banana"><h2>Banana</h2>
           <p class="price">R$&nbsp;5,90 <small>/ dozen</small></p>
           <button type="button">Add to basket</button></li>
```

One match, and the card as the browser holds it after `app.js` built it.

## Parent, child, sibling

That `<li>` is one node of the tree, and everything inside it hangs from it. The vocabulary is a
family's, and every locator language uses it:

- the `li` is the **parent** of the `h2`, the `p` and the `button`, which are its **children**,
  and **siblings** of one another;
- the `small` is a child of the `p`, so it is a **descendant** of the `li` two levels down, and
  the `li` is one of its **ancestors**;
- the words are nodes too, **text nodes**, children of the element they sit in. The `p` holds a
  text node and then the `small` element;
- **attributes** belong to an element and are not its children: `class`, `id`, `data-testid` and
  `type` are all on the element they describe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The Banana card drawn as a tree. The li element, with the attributes class card, id card-4821 and data-testid product-banana, is the parent of three children: h2, p with class price, and button. Beneath them, dashed, are the text nodes: Banana, the price with a non-breaking space, and Add to basket; a small element sits inside the price. Beside the tree, four locators for the card: the test id and the heading's text keep matching it; the id and the position break with no defect in the shop.\"><rect x=\"70\" y=\"16\" width=\"250\" height=\"72\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"84\" y=\"38\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">li class=\"card\"</text><text x=\"84\" y=\"57\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">id=\"card-4821\"</text><text x=\"84\" y=\"76\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">data-testid=\"product-banana\"</text><text x=\"16\" y=\"56\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">parent</text><path d=\"M150 88 L55 130\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M195 88 L190 130\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M250 88 L375 130\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"15\" y=\"130\" width=\"80\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"55\" y=\"151\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h2</text><rect x=\"120\" y=\"130\" width=\"140\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"190\" y=\"151\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">p class=\"price\"</text><rect x=\"320\" y=\"130\" width=\"110\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"375\" y=\"151\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">button</text><path d=\"M55 162 L55 210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M175 162 L165 210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M210 162 L280 210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M375 162 L375 210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"10\" y=\"210\" width=\"90\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect><text x=\"55\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"Banana\"</text><rect x=\"105\" y=\"210\" width=\"125\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect><text x=\"167\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">\"R$&amp;nbsp;5,90 \"</text><rect x=\"245\" y=\"210\" width=\"70\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"280\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">small</text><rect x=\"320\" y=\"210\" width=\"120\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect><text x=\"380\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"Add to basket\"</text><text x=\"10\" y=\"268\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">h2, p and button: children of the li, siblings of each other</text><text x=\"10\" y=\"286\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dashed: text nodes</text><text x=\"462\" y=\"36\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">four locators that reach this card</text><text x=\"462\" y=\"74\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">getByTestId('product-banana')</text><text x=\"462\" y=\"92\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">an attribute written for tests</text><text x=\"462\" y=\"126\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">getByText('Banana')</text><text x=\"462\" y=\"144\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what a person reads</text><text x=\"462\" y=\"178\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">#card-4821</text><text x=\"462\" y=\"196\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">drawn again on every load</text><text x=\"462\" y=\"230\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">#products &gt; li:nth-child(1)</text><text x=\"462\" y=\"248\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">first today, maybe not tomorrow</text></svg>", "caption": "The Banana card as the browser holds it, with four ways to point at it. The two in amber match it today and are not promised to tomorrow."}
```

Two details in that output come back in this lesson. The first is `&nbsp;`, which is how the DOM
writes the **non-breaking space** lesson 1 warned about when it turns a page back into HTML. A
locator or a check that types an ordinary space is describing a different string. The second is
the space after `5,90`: the price's text node ends there, before `<small>` begins, so its whole
value is `R$`, the non-breaking space, `5,90` and one ordinary space. The line breaks and spaces
between `</h2>` and `<p>` are text nodes too, made of nothing but whitespace by the template in
`app.js`. The Elements panel hides those; XPath, two sections on, compares text exactly as it is.

## What a test could lean on

From this one card, a test could name it by:

- **its tag and class**, `li.card`, which seven other cards share;
- **its `id`**, which is unique on the page, and drawn at random every time the page loads;
- **its position**, first in the list, because the shop lists the banana first;
- **its `data-testid`**, an attribute that exists only to be found by tests;
- **what a person sees**: a heading that says Banana and a button that says Add to basket.

**Every one of them reaches the Banana card right now**, and that is exactly why a test that
passes today proves nothing about its locator. The next two sections are the two classic
languages for writing these descriptions, CSS and XPath. The two after them are about which
descriptions stop being true, and about the locators Playwright builds around what a person sees.
