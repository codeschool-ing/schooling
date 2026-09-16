---
title: The other tree, and the blank screen
version: 1
---

Markup says what things are. Styles say what they look like. Both have to be understood before
anything can be drawn, and the second one is the reason a page can sit blank while the browser is
demonstrably working.

## Styles become a tree too

A stylesheet is parsed into its own structure, the **CSSOM**, and the reason it is a tree rather
than a list is inheritance: a colour set on the body reaches a paragraph inside a section inside an
article unless something stops it.

So the browser cannot know the final style of one element by looking at one rule. It has to
combine every rule that matches, in the right order, and let inherited values fall through the
structure.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three rules matching the same element, with the most specific one winning, the later of two equal ones winning, and an inherited value used where nothing matched at all.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">#price { color: green }</text> <text x=\"470\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">wins: most specific</text> <rect x=\"20\" y=\"82\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">.sale { color: red }</text> <text x=\"470\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a class loses to an id</text> <rect x=\"20\" y=\"130\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">p { color: black }</text> <text x=\"470\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">an element name loses to both</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">specificity first, then order, and inheritance for what matched nothing</text> <text x=\"360\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">which is why the final style of one element cannot be read off one rule</text> </svg>", "caption": "Three mechanisms, applied in one order. Reading a single rule tells you almost nothing about the result."}
```

Three things decide what wins, and they are applied in this order.

**Specificity.** A more specific selector beats a less specific one — an id beats a class beats an
element name — regardless of where it appears.

**Order.** Between rules of equal specificity, the last one wins.

**Inheritance**, which is not a competition: it is what an element gets when nothing matched it at
all.

## Why the screen stays blank

Here is the part that explains a symptom you have seen.

The browser will not paint until it has the styles. Not because it cannot — it could draw the text
immediately — but because drawing it unstyled and then drawing it again would produce a flash of
unstyled content on every page load, and the second version would look nothing like the first.

So CSS is **render-blocking**: while a stylesheet is outstanding, the page stays blank.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline in which the HTML arrives quickly and the screen stays blank until the slowest stylesheet has arrived, because the browser refuses to paint unstyled content.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the server answered in 40 ms, and the visitor waited two seconds</text> <rect x=\"20\" y=\"38\" width=\"120\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"80\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">the HTML</text> <rect x=\"146\" y=\"38\" width=\"420\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"356\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">waiting for the slowest stylesheet</text> <rect x=\"572\" y=\"38\" width=\"128\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"636\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">first paint</text> <rect x=\"20\" y=\"92\" width=\"546\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"293\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the screen, entirely blank, while the browser works</text> <text x=\"360\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">the slowest stylesheet sets the earliest moment anything can appear</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and a stylesheet that imports another adds a round trip in front of it</text> <text x=\"360\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">a blank screen is not evidence of a slow server</text> </svg>", "caption": "The browser could paint immediately. It refuses, because painting twice would look worse than waiting once."}
```

That has a consequence worth stating as a rule. **The slowest stylesheet on the page sets the
earliest possible moment anything appears.** A stylesheet on a slow third-party host, a stylesheet
that imports another stylesheet which imports a third — each of those is a round trip in front of
the first pixel.

And it is why a blank screen is not evidence of a slow server. Lesson three separated the numbers;
this is a case where the server answered in forty milliseconds and the visitor waited two seconds.

## What does not block

Not all of it blocks, and the distinctions are useful.

A stylesheet with a **media condition that does not match** is fetched at low priority and does not
block: a print stylesheet does not delay the screen.

Styles **inside the page**, in a `<style>` block, arrived with the HTML and cost no request at all.
That is the reason for the technique of putting the handful of rules needed for the top of the page
directly in the document and loading the rest afterwards — the page can paint from what it already
has.

**Imports inside a stylesheet** are the opposite case and are worth avoiding: the browser cannot
discover the second file until it has parsed the first, so two round trips happen one after the
other where they could have happened at once.

## The cascade has more layers than people expect

Worth a short section, because the full order explains arguments that otherwise end in somebody
adding an exclamation mark.

The browser has its own stylesheet — that is why an unstyled heading is large and bold and a link
is blue and underlined. Your rules sit on top of it. And the visitor's own settings sit on top of
that in the cases where they are allowed to.

Within your own rules, there is one more level nobody enjoys: `!important`, which lifts a
declaration above ordinary specificity entirely. It exists for genuine cases — overriding something
in a stylesheet you cannot edit — and in practice it is usually one person winning an argument with
another person's stylesheet, after which the only way to win the next one is another `!important`.

The instinct worth building: when a rule is not applying, the question is which of these levels beat
it, and a browser's tools will show you the whole list with the losers struck through. That display
is the cascade made visible, and it settles in a second what reading a stylesheet settles in twenty
minutes.

## The cost of the styles themselves

One practical note, because it is measurable and easy to get wrong.

Every rule in a stylesheet is a rule the browser matches against elements. A file of twenty
thousand rules, of which a page uses forty, costs the download, the parse, and a matching pass
against every element.

Most of that is fast — browsers are extremely good at this — but on a large page on a modest phone
it is a real number, and it is the reason a build that removes unused rules shows up in
measurements rather than only in a file size.

The instinct: a stylesheet is not a cost you pay once. It is a cost you pay again at every layout,
and the next readings are about how often those happen.
