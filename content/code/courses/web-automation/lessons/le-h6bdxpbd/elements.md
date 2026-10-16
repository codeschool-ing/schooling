---
title: The Elements panel, and the page a test sees
version: 1
---

Every browser you are likely to use has developer tools built in. Open the shop in Chrome, Edge
or Firefox, right-click the **Banana** card and choose **Inspect**: a panel opens, beside or below
the page, with the element you clicked highlighted in a tree of tags. **F12** opens the same panel,
and so does Ctrl+Shift+I, or Cmd+Option+I on a Mac. `javascript` lesson 22 uses these tools to
debug a script you wrote. This lesson uses them the way a tester does: to find out what a test
will meet before writing one.

## The tree is not the file

The usual first belief about the Elements panel is that it shows the page's HTML. **It shows the
page as it is now**, which is a different thing, and the shop makes the difference easy to see.
Here is what the server sends when the browser asks for `/`, the part about products:

```
ana@laptop:~/quitanda$ curl -s http://localhost:3000/ | grep -n products
22:    <ul id="products" aria-busy="true"></ul>
```

An empty list, with `aria-busy="true"` on it. In the Elements panel, the same `<ul>` holds eight
`<li>` elements and says `aria-busy="false"`. Nothing in the file changed. The script ran after
the page loaded, asked the server for the products and built the cards into the page.

What the panel shows is the **DOM**, the Document Object Model: the tree of objects the browser
builds from the HTML and that scripts then change. `javascript` lesson 11 covers how a script
reads and changes it. For automation the consequence is one sentence long: **a test sees the DOM,
never the file**. Right-click and **View page source** shows the file, which is useful for exactly
one question, what arrived before any script ran, and that question comes back in lesson 6.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"On the left, the HTML the server sent: an empty list marked aria-busy true. An arrow labelled app.js runs and asks for /api/products leads to the right, the DOM a moment later: the same list with eight cards and aria-busy false.\"><rect x=\"20\" y=\"40\" width=\"250\" height=\"170\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"66\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">what the server sent</text><text x=\"36\" y=\"104\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;ul id=\"products\"</text><text x=\"36\" y=\"124\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">    aria-busy=\"true\"&gt;</text><text x=\"36\" y=\"144\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;/ul&gt;</text><text x=\"36\" y=\"186\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">no products in it</text><path d=\"M280 125 L430 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M430 125 L420 119 L420 131 Z\" fill=\"var(--phosphor)\"></path><text x=\"355\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">app.js runs</text><text x=\"355\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and asks for</text><text x=\"355\" y=\"166\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/api/products</text><rect x=\"440\" y=\"20\" width=\"260\" height=\"210\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"456\" y=\"46\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">the DOM, a moment later</text><text x=\"456\" y=\"76\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;ul id=\"products\"</text><text x=\"456\" y=\"96\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">    aria-busy=\"false\"&gt;</text><rect x=\"470\" y=\"108\" width=\"200\" height=\"16\" rx=\"3\" fill=\"var(--scan)\"></rect><rect x=\"470\" y=\"128\" width=\"200\" height=\"16\" rx=\"3\" fill=\"var(--scan)\"></rect><rect x=\"470\" y=\"148\" width=\"200\" height=\"16\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"570\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">… eight cards in all</text><text x=\"456\" y=\"212\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;/ul&gt;</text></svg>", "caption": "The same list twice. A test that looks between the two moments finds nothing to click."}
```

## What to read on an element

Click the **Add to basket** button inside the Banana card in the Elements panel. Four things on
it, and on the elements around it, decide how a test can find it again:

- **the tag and its text**: a `<button>` whose text is *Add to basket*. That is also how a person
  finds it;
- **its role and accessible name**, shown in the panel's **Accessibility** tab: the role is
  `button` and the name is *Add to basket*. These are what a screen reader announces, and what
  Playwright's `getByRole`, the locator the smoke test used for the heading, looks for;
- **attributes written for tests**: the card around it carries `data-testid="product-banana"`, an
  attribute that exists for no other reason than to be found;
- **attributes that happen to be there**: the card's `id`, which reads something like `card-4821`.

**Reload the page and look at that `id` again.** It has a different number, because `app.js`
draws it at random each time, and the comment beside that line calls it a known flaw. A test that
copied the card's `id` from this panel would fail on its very first run, because the page it opens draws a new number. Lesson 2 is about
telling these four apart, and about why the last one is the trap.

## Trying a locator before writing it

In the Elements panel, Ctrl+F (Cmd+F on a Mac) opens a search box that accepts plain text, a CSS
selector or an XPath expression, and says how many elements match: `1 of 8` for `.card button`
while the products are showing, for instance. **A locator that matches the wrong number of
elements is wrong before any test runs**, and this box is the cheapest place to find that out.
Lesson 2 uses it for every selector it shows.

You can also change the page here: double-click an attribute to edit it, or delete an element with
the Delete key. The change lasts until the next reload and touches nothing on the server, which
makes it a safe way to ask *what would my test do if this button were missing?*
