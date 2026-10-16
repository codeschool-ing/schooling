---
title: A browser with no screen
version: 1
---

Every test in this course so far has run in Chromium with no window. That makes "headless" sound
like the name of a cheaper kind of browser, and **it is not one**. Headless Chromium is the whole
browser: it lays the page out, paints it into memory, and lesson 16's screenshots are pictures of
that memory. A **simulated browser** is a different thing. It is a library, written from scratch,
that does the first half of a browser's work and none of the second.

## What a browser does with a page

When Chromium opens the shop, the work comes in a fixed order. It fetches the bytes, parses the
HTML into the tree of elements lesson 2 walked, and runs `app.js` against that tree. It matches
the rules of `style.css` to each element, then works out where every box goes and how big it is:
that step is **layout**. Then it paints pixels, and composites the layers onto the screen.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 212\" role=\"img\" aria-label=\"Seven steps from left to right: fetch the bytes, parse the HTML into a DOM, run scripts against it, match CSS rules, layout, paint, composite to the screen. A simulated browser keeps the first four; only a real browser does layout, paint and composite. A script asking for scrollWidth needs layout: Chromium at 360 pixels wide answers 400 for the shop, and jsdom answers 0 for the same page.\"><rect x=\"16\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"62.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fetch</text><text x=\"62.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the bytes</text><rect x=\"122\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"168.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parse HTML</text><text x=\"168.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">into a DOM</text><path d=\"M109 95.0 L119 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M115 91.0 L120 95.0 L115 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"228\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"274.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">run scripts</text><text x=\"274.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">against it</text><path d=\"M215 95.0 L225 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M221 91.0 L226 95.0 L221 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"334\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"380.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">match CSS</text><text x=\"380.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rules</text><path d=\"M321 95.0 L331 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M327 91.0 L332 95.0 L327 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"440\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"486.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">layout</text><text x=\"486.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sizes, places</text><path d=\"M427 95.0 L437 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M433 91.0 L438 95.0 L433 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"546\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"592.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">paint</text><text x=\"592.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pixels</text><path d=\"M533 95.0 L543 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M539 91.0 L544 95.0 L539 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"652\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"698.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">composite</text><text x=\"698.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">to the screen</text><path d=\"M639 95.0 L649 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M645 91.0 L650 95.0 L645 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M16 52 L16 44 L426 44 L426 52\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"221.0\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">kept by a simulated browser</text><path d=\"M440 52 L440 44 L744 44 L744 52\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"592.0\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">only a real browser</text><path d=\"M274.0 120 L274.0 154 L486.0 154 L486.0 124\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M482.0 129 L486.0 123 L490.0 129\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"380.0\" y=\"148\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">scrollWidth?</text><text x=\"486.0\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Chromium, 360 px wide: 400</text><text x=\"486.0\" y=\"194\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">jsdom, the same page: 0</text></svg>", "caption": "What a browser does with a page, and where a simulated one stops. The matching of CSS rules is partial: jsdom knew that the basket has a min-width of 384px, and could not say how wide that made anything."}
```

**A simulated browser keeps the first four steps and drops the last three.** It has a parser, a
DOM, a JavaScript engine to run the page's scripts, and some of the CSS cascade. It has no layout,
so it cannot tell you where anything is or how wide it is. It paints nothing, so nobody can look
at it. And because nothing is on a screen, a click is a function call on an element, with no
pointer and no question of what the pointer would have landed on.

**What it buys with that is a browser that lives inside your program.** No separate process to
start, no protocol between your code and the page, no driver. `document.querySelector` in your test
is the same object the page's own script holds. That is why simulated browsers were the fast route
for years. Before Chrome 59 shipped headless mode in 2017, driving a real browser on a build server
meant a virtual display or a special build of one engine.

## The three this lesson meets

| | language | JavaScript runs in | release used here |
|---|---|---|---|
| Zombie.js | Node | jsdom 11.12.0, which Zombie pins | 6.1.4, from 2018: the last one |
| HtmlUnit | Java | its own fork of Mozilla Rhino | 5.6.0, current |
| jsdom | Node | Node's own V8, in a separate context | 30.1.2 |

They are not three competitors of equal standing. **Zombie is an API on top of jsdom**, from the
years when Node testing tools wanted a whole browser in a callback. Its last release is eight years
old, and the next section shows what that means for a page written today. **HtmlUnit is the Java
one**, still released, and the one Selenium can drive through a driver of its own. **jsdom is the
DOM itself**, without the browser around it, and it is the one most JavaScript developers run
without knowing: it is what a Jest test gets when its environment is `jsdom`.

## What the word "browser" promises here

None of the three is a fourth browser next to Chrome, Firefox and Safari. Each implements the
standards its authors had time for. HtmlUnit runs them on a JavaScript engine no user's browser
uses, and jsdom on whatever V8 came with the Node you installed. **A page can
pass in one of them and fail in every real browser**, and the other way round. Lesson 10 runs
one suite in Chromium, Firefox and WebKit because three real engines treat the same page in
slightly different ways; a simulated one is a fourth engine that none of your users have.

So the question this lesson keeps asking is not "is it fast?" It is: **what did the check I wrote
actually look at?** For the HTML a server sends, and for code that only reads and writes the tree,
the answer is the same in a simulated browser and a real one. For anything that depends on where a
box landed, there is no answer at all, and the next sections measure how that shows.
