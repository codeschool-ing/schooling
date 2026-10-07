---
title: Headings and the outline of a page
version: 2
---

Headings are the most useful thing on a page for anybody skimming it, and the most common thing to get wrong. HTML has six levels, `<h1>` to `<h6>`, and **the level says where the heading sits in the outline of the page, not how big it is**.

Read a page's headings on their own and they should work as its table of contents: one `<h1>` naming the page, `<h2>` for each major part, `<h3>` for the parts inside those. The events page, with a section per month and an article per event, has this outline:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two heading outlines. On the left, levels that follow on: h1 Events, h2 October, h3 Poetry reading, h2 November, each indented one step under its parent. On the right, a level skipped: h1 Opening hours, then two h4 headings, Weekdays and Weekends, with the h2 and h3 levels missing between them, which axe reports as heading-order.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">levels that follow on</text><rect x=\"20\" y=\"36\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h1</text><text x=\"72\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Events</text><rect x=\"50\" y=\"74\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h2</text><text x=\"102\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">October</text><rect x=\"80\" y=\"112\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h3</text><text x=\"132\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Poetry reading: Hilda Hilst</text><rect x=\"50\" y=\"150\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h2</text><text x=\"102\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">November</text><text x=\"400\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">a level skipped</text><rect x=\"400\" y=\"36\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h1</text><text x=\"452\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Opening hours</text><rect x=\"490\" y=\"112\" width=\"210\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h4</text><text x=\"542\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Weekdays</text><rect x=\"490\" y=\"150\" width=\"210\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h4</text><text x=\"542\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Weekends</text><rect x=\"430\" y=\"74\" width=\"260\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"440\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">h2 and h3: missing</text><text x=\"400\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">axe: heading-order</text></svg>", "caption": "Heading levels are a table of contents. A level is chosen by its place in the outline, never by its size."}
```

The figure's right-hand side is a real page, the opening-hours page, where somebody wanted the two subheadings to be small and reached for `<h4>`. Here it is as `headings.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Opening hours · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Opening hours</h1>
      <h4>Weekdays</h4>
      <p>10 am to 7 pm.</p>
      <h4>Weekends</h4>
      <p>10 am to 4 pm.</p>
    </main>
  </body>
</html>
```

And here is what the tree and axe make of it:

```
ana@laptop:~/site$ probe headings.html tree axe
- main:
  - heading "Opening hours" [level=1]
  - heading "Weekdays" [level=4]
  - paragraph: 10 am to 7 pm.
  - heading "Weekends" [level=4]
  - paragraph: 10 am to 4 pm.
heading-order (moderate, 1 element): Heading levels should only increase by one
```

The tree reports the levels as they were written: 1, then 4, then 4. To somebody navigating by headings that says there are two missing levels, a part and a sub-part they never found. axe, the accessibility checker from section 11, reports exactly that as **heading-order**. The fix is `<h2>`, and if `<h2>` is too big, that is CSS: `h2 { font-size: 1.1rem; }` is lesson 5's first rule.

## Three rules worth keeping

**One `<h1>` per page, naming what the page is.** On the events page it is *Events*, not the shop's name, which every page shares and the title already carries. The site name usually sits in the header as a link or a paragraph, which is what the semantic version in the last section did.

**Do not skip levels on the way down.** From `<h2>` you go to `<h3>`, not to `<h4>`. Going back up is fine and necessary: after the last `<h3>` of one part, the next part starts with an `<h2>`.

**A heading needs content under it.** Text made bold to look like a heading is not one, and a heading used only because the text should be big is not one either: a slogan in an `<h2>` puts a section in the outline that has nothing in it.

## Where to check

DevTools has an accessibility pane beside the styles that shows each element's role and level, and browser extensions list a page's headings as an outline. Both show you the same thing `probe tree` does, which is the only view of headings that matters: the one somebody navigating by them will get.
