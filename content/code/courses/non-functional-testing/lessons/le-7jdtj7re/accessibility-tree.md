---
title: What a screen reader is told
version: 1
---

Every element the browser draws, it also describes, in a parallel structure called the
**accessibility tree**. Each node in it has three things a screen reader reads out: a **role**,
what kind of thing it is (link, button, textbox, heading); a **name**, which one it is ("Book",
"Your name"); and **states**, what condition it is in (selected, checked, expanded, invalid, level
1). A screen reader announces the name, the role and the states, in words and an order of its own
choosing. **What the tree holds is the page's choice**, and it can be read
without a screen reader, from a script.

In `~/a11y`, `nano tree.js`:

```schooling-example
{"language": "javascript", "file": "a11y/tree.js", "parts": [{"code": "// a11y/tree.js\n// Prints what a screen reader is told about a page: its accessibility tree as\n// the page loads, then what changes when Book is pressed with no name typed.\nconst { chromium } = require(\"playwright\");\n\nconst url = process.argv[2] || \"http://localhost:8000/book.html\";", "note": "The third program in `~/a11y`. It needs no axe, only Playwright, and the page's address."}, {"code": "\nfunction shorter(tree) {            // twenty shows: keep the first option, count the rest\n  const lines = tree.split(\"\\n\");\n  const options = lines.filter(l => l.trim().startsWith(\"- option\"));\n  return lines.filter(l => !options.slice(1).includes(l))\n    .map(l => l === options[0] && options.length > 1 ? `${l}  (and ${options.length - 1} more)` : l)\n    .join(\"\\n\");\n}", "note": "The list of shows has twenty options, and printing all of them would bury everything else. `shorter` keeps the first and says how many more there were; nothing else in the tree is touched."}, {"code": "\n(async () => {\n  const browser = await chromium.launch();\n  const page = await browser.newPage();\n  await page.goto(url);\n  await page.waitForLoadState(\"networkidle\");\n  const before = await page.locator(\"body\").ariaSnapshot();\n  console.log(shorter(before));", "note": "**`ariaSnapshot()`** is Playwright's view of the accessibility tree: one line per node, its role, its accessible name in quotes, and its states in brackets, indented by nesting. It is the tree the browser hands to assistive technology, so it is what a screen reader has to work with."}, {"code": "\n  await page.getByText(\"Book\", { exact: true }).click();\n  await page.waitForTimeout(500);\n  const after = (await page.locator(\"body\").ariaSnapshot()).split(\"\\n\");\n  const changed = after.filter(line => !before.split(\"\\n\").includes(line));\n  console.log(\"\\nAfter Book with no name, the tree gains:\");\n  console.log(changed.length ? changed.join(\"\\n\") : \"  nothing\");\n  await browser.close();\n})();", "note": "Then the error case: press Book with the name empty, wait half a second, take the tree again, and print the lines that were not there before. **An error that changes nothing in the tree is an error a screen reader cannot report**, whatever colour it turns the screen."}]}
```

## Before: book.html

```
ana@nft:~/a11y$ node tree.js http://localhost:8000/book.html
- img
- navigation:
  - link "What's on":
    - /url: /shows
  - link "Prices":
    - /url: /prices
  - link "Access":
    - /url: /access
- heading "Book a seat" [level=1]
- paragraph: Seats are held for ten minutes. The price includes the booking fee.
- paragraph:
  - text: Show
  - combobox "Show":
    - option "Hamlet, 2027-10-02" [selected]  (and 19 more)
- paragraph:
  - text: Seat
  - spinbutton "Seat": "1"
- paragraph:
  - text: Your name
  - textbox
- text: Book
- paragraph

After Book with no name, the tree gains:
  nothing
```

Read it the way a screen reader user meets it, line by line:

- **`img`, with no name.** The logo exists, and nothing says what it is. Depending on the reader
  and its settings, the user hears the file name, the word for image, or nothing.
- **`textbox`, with no name**, after a separate line of text that says "Your name". The two are
  next to each other on the screen. In the tree they are unrelated, and a user tabbing to the
  field lands on a nameless box: that is why 1.3.1 talks about **relationships**. The Show and
  Seat fields, which have real labels, come out as `combobox "Show"` and `spinbutton "Seat"`.
- **`text: Book`**, not a button. To the tree the `<div>` is a word on the page. A screen reader
  user reading through the page hears it as text and has no reason to try pressing it.
- **No `main`**, and nothing after the click: the red border changed a style, and a style is not
  in the tree. The error happened only for the eyes.

## After the keyboard fixes: book3.html

```
ana@nft:~/a11y$ node tree.js http://localhost:8000/book3.html
- link "Skip to the booking form":
  - /url: "#main"
- img "boxoffice"
- navigation:
  - link "What's on":
    - /url: /shows
  - link "Prices":
    - /url: /prices
  - link "Access":
    - /url: /access
- main:
  - heading "Book a seat" [level=1]
  - paragraph: Seats are held for ten minutes. The price includes the booking fee.
  - paragraph:
    - text: Show
    - combobox "Show":
      - option "Hamlet, 2027-10-02" [selected]  (and 19 more)
  - paragraph:
    - text: Seat
    - spinbutton "Seat": "1"
  - paragraph:
    - text: Your name
    - textbox "Your name"
  - button "Book"
  - paragraph

After Book with no name, the tree gains:
  nothing
```

`img "boxoffice"`, `textbox "Your name"`, `button "Book"`, a `main` holding the form: the fixes of
lessons 13 and 14 show up here as names and roles, which is the same improvement seen from the
other side. **But the error still adds nothing to the tree.** The one defect left is
exactly the one this tree cannot show yet, and the next section fixes it.

## How a name is computed

The name a node gets is not a guess. It follows the W3C's *Accessible Name and Description
Computation*, which looks in a fixed order and takes the first source that gives something:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l15-name\" aria-label=\"The order in which a browser looks for an element's accessible name, taking the first that gives something. First aria-labelledby, the text of the elements it points at. Then aria-label. Then the native source: a label for a field, alt for an image, the content of a button or link. Last, title, and placeholder for a field. On the booking page, the name field gets &quot;Your name&quot; from its label; the logo gets &quot;boxoffice&quot; from alt; the Book button gets &quot;Book&quot; from its content.\"><defs><marker id=\"l15-name-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-name-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"150.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">looked for in this order</text><text x=\"520.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">on the booking page</text><rect x=\"40.0\" y=\"44.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"56.0\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"76.0\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aria-labelledby</text><text x=\"76.0\" y=\"79.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the text of the ids it names</text><path d=\"M150.0 96.0 L150.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"110.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"56.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"76.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aria-label</text><text x=\"76.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a string on the element</text><path d=\"M150.0 162.0 L150.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"176.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"56.0\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"76.0\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">native</text><text x=\"76.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;label&gt;, alt, a button's content</text><path d=\"M150.0 228.0 L150.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-paper-dim)\"></path><rect x=\"360.0\" y=\"130.0\" width=\"320.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"376.0\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">textbox &quot;Your name&quot;</text><text x=\"376.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from &lt;label for&gt;</text><path d=\"M264.0 201.0 L356.0 149.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-phosphor)\"></path><rect x=\"360.0\" y=\"178.0\" width=\"320.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"376.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">img &quot;boxoffice&quot;</text><text x=\"376.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from alt</text><path d=\"M264.0 201.0 L356.0 197.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-phosphor)\"></path><rect x=\"360.0\" y=\"226.0\" width=\"320.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"376.0\" y=\"239.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">button &quot;Book&quot;</text><text x=\"376.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from its content</text><path d=\"M264.0 201.0 L356.0 245.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-phosphor)\"></path><rect x=\"40.0\" y=\"242.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"56.0\" y=\"259.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"76.0\" y=\"259.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">title, placeholder</text><text x=\"76.0\" y=\"277.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">last resorts, and weak ones</text><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the first source that gives a name wins, and hides the rest</text></svg>", "caption": "How an accessible name is found. On the booking page every name comes from the native source, which is the one to reach for first."}
```

1. **`aria-labelledby`**, which points at the ids of other elements and joins their text.
2. **`aria-label`**, a string on the element itself.
3. **The native source**: the `<label>` tied to a field, the `alt` of an image, the text inside a
   button or a link, the `<caption>` of a table.
4. **`title`**, and for a field, **`placeholder`**, as the last resorts. Both are weak: a `title`
   appears only on hover, and a placeholder disappears as soon as somebody types.

Two consequences matter in testing. **The first source wins and hides the rest**: an
`aria-label="Submit"` on a button whose visible text says "Book" makes its name "Submit", and a
voice-control user who says "click Book" gets nothing, which is *2.5.3 Label in Name* failing.
And a name can be present and wrong, which no tree and no tool can judge; that is the human half
of the test.

## The first rule of ARIA

ARIA, Accessible Rich Internet Applications, is the set of attributes, `role` and the `aria-*`
family, that lets a page set roles, names and states by hand. It exists for widgets HTML has no
element for: a tab list, a tree view, a combobox with suggestions. **The W3C's own first rule for
using it is not to**: if a native HTML element already has the meaning and the behaviour you need,
use it instead of repurposing another element and adding ARIA to it.

The `<div>` shows why. Making it a real button by hand takes all of this:

```html
<div class="book" role="button" tabindex="0" onclick="book()"
     onkeydown="if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); book(); }">Book</div>
```

and that still is not quite a button: it does not submit its form, it is not disabled by
`disabled`, and every copy of it is one more place for the key handler to be wrong. `<button
class="book">Book</button>` is all of it, built in. **ARIA changes what the tree says and nothing
about what the element does**, which is why `role="button"` on a `<div>` with no key handler is
worse than no ARIA at all: it promises a screen reader user a button and delivers a word.
