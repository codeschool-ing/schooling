---
title: "INP: how long a tap waits"
version: 1
---

**Interaction to Next Paint is how long the page took to show a response to an interaction, taken
for the slowest interaction of the whole visit.** An interaction is a click, a tap or a key press;
scrolling and hovering are not. The response is the next frame the browser paints after it, whatever
that frame shows. A button that turns grey at once and loads data for a second has a short INP,
because the person saw something happen; a button that shows nothing for a second has a long one.

## Three parts of one interaction

Each interaction's time is the sum of three parts, and the `web-vitals` library reports all three:

1. **input delay**: from the tap until the page's code for it starts, which is long when the main
   thread is busy with something else, such as hydrating;
2. **processing**: the page's own event handlers, running;
3. **presentation delay**: from the end of the handlers until the frame is painted: style, layout
   and paint of whatever the handlers changed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"One interaction drawn as a bar along time, in three parts: input delay, from the tap until the handler starts; processing, while the handler runs; and presentation delay, until the next frame is painted. INP is the length of the whole bar.\"><rect x=\"60\" y=\"60\" width=\"120\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><text x=\"120.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">input delay</text><rect x=\"180\" y=\"60\" width=\"330\" height=\"34\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"345.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">processing: the handlers</text><rect x=\"510\" y=\"60\" width=\"160\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"590.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">presentation</text><line x1=\"60\" y1=\"50\" x2=\"60\" y2=\"104\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><text x=\"60\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tap</text><line x1=\"670\" y1=\"50\" x2=\"670\" y2=\"104\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"670\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">next paint</text><line x1=\"60\" y1=\"124\" x2=\"670\" y2=\"124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"365.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">INP: the whole of it, for the slowest interaction of the visit</text></svg>", "caption": "What a person waits for is the paint, not the end of the code."}
```

**The main thread does one thing at a time**, and that is the whole story of INP. A handler that runs
for a second blocks every other tap for that second, and blocks the paint that would show the result.
The fixes follow from the parts: do less in the handler, split long work so the browser can paint in
between, and change less of the page so there is less to lay out.

## The slowest one, almost

A visit can have hundreds of interactions. INP takes the slowest, except that on a page with many
interactions it ignores one in every fifty, so that a single freak delay on a long visit does not
decide the number. **The threshold is 200 milliseconds for good and 500 for poor.** A page with no
interaction has no INP at all, and neither does one whose interactions were all quicker than the
browser bothers to report, as the section "Field data: the number from the visitor" shows.
