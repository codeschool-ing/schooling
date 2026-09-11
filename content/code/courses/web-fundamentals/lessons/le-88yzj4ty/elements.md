---
title: The tree, live
version: 1
---

The elements panel shows the DOM of lesson ten — not the file that was sent, but the tree that
exists right now, including every repair the parser made and everything any script has done since.

That distinction is the whole reason to use it, and it is worth proving to yourself once: open any
page, view the source, then open this panel, and find something that differs.

## What is on the screen

Three areas, and each answers a different question.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The elements panel in three areas: the tree of nodes, the rules that matched the selected element with the losing ones struck through, and the computed value of every property.\"> <rect x=\"20\" y=\"34\" width=\"220\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">the tree</text> <text x=\"130\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;article&gt;</text> <text x=\"130\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;h1&gt; ... &lt;/h1&gt;</text> <text x=\"130\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;p class=\"sale\"&gt;</text> <text x=\"130\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the selected one is highlighted</text> <rect x=\"252\" y=\"34\" width=\"216\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">what matched it</text> <text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">#price color: green</text> <text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">.sale color: red</text> <text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">p color: black</text> <text x=\"360\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the losers are struck through</text> <rect x=\"480\" y=\"34\" width=\"220\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"590\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the computed value</text> <text x=\"590\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">color: rgb(0 128 0)</text> <text x=\"590\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">margin-left: 17px</text> <text x=\"590\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">display: block</text> <text x=\"590\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the answer, not the rules</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the cascade of lesson ten, made visible</text> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and when a thing is 17 pixels from the left, the right-hand column is where the 17 is</text> </svg>", "caption": "Three areas, three questions: what is here, what matched it, and what the answer turned out to be."}
```

**The tree**, on one side, expandable, with the element under your pointer highlighted on the page
itself. Selecting a node is how every other panel in this lesson learns which element you mean.

**The styles**, on the other, showing every rule that matched the selected element, in cascade
order, with the losers struck through. This is the cascade of lesson ten made visible, and it
settles in one glance what reading a stylesheet settles in twenty minutes.

**The computed values**, usually a tab beside the styles, showing the final number for every
property — not the rules, the answer. When a thing is 17 pixels from the left and nobody can say
why, this is where the 17 is.

## The four things worth learning to do

**Inspect.** Right-click anything on any page and choose inspect, and the panel opens with that
element selected. It is the fastest route from *what is this?* to an answer, and it works on sites
you did not build, which is how a great deal of front-end knowledge is actually acquired.

**Edit, temporarily.** Every value in the styles panel is editable, and the page updates as you
type. Change a colour, a size, a margin; see it immediately. Nothing is saved — a reload discards
all of it — which is exactly what makes it safe.

**Toggle a state.** A small control lets you force an element into hover, focus or active, so you
can inspect a menu that would otherwise vanish the moment you moved the pointer away. This is the
one people do not discover on their own and then use every day afterwards.

**Read the box.** A diagram of the four rings from lesson ten — content, padding, border, margin —
with the real numbers in them. It answers *where is this space coming from?* faster than any amount
of reading.

## The panel changes the page it is showing

One consequence worth being deliberate about, because it produces confusing afternoons.

Opening the panel makes the window narrower. On a responsive site that can change which layout is
being used, which means the thing you are inspecting is not quite the thing a visitor sees. The
panel can be moved to the bottom or into a separate window, and on a layout question that is worth
doing.

Editing a value changes the live page and nothing else. It is not a fix and it does not reach your
files — which is obvious when written down and is nonetheless the source of the occasional lost
hour.

## Two other tabs in the same panel

Worth naming because both come straight out of earlier lessons.

**Accessibility**, which shows what a screen reader would make of the selected element: its role,
its name, whether it is in the tree that assistive software reads at all. This is where the
`opacity: 0` problem of lesson ten becomes visible rather than theoretical.

**Event listeners**, which lists the code attached to the element. When a button does nothing, this
answers whether anything is listening — which is a different question from whether the code is
wrong, and a much quicker one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four things to learn to do in this panel: inspect anything on any site, edit values temporarily, force a hover or focus state, and read the box model with real numbers.\"> <rect x=\"20\" y=\"34\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"188\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">inspect anything, on any site</text> <rect x=\"20\" y=\"84\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"188\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">edit a value and see it at once</text> <rect x=\"364\" y=\"34\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"532\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">force hover, so a menu stays open</text> <rect x=\"364\" y=\"84\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"532\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">read the box, with real numbers</text> <rect x=\"20\" y=\"140\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nothing here is saved: a reload discards all of it, which is what makes it safe</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the third one is the one nobody discovers alone and everybody then uses daily</text> </svg>", "caption": "Four moves. The edits are temporary on purpose, which is why experimenting here costs nothing."}
```

## Where the cookies and the caches are

One more panel worth naming here, because it holds everything from lesson seven and people look for
it in the wrong place.

The storage panel — *application* in some browsers — lists the cookies for this site with their
attributes as columns: the value, the domain, the path, the expiry, and ticks for `Secure`,
`HttpOnly` and `SameSite`. Three ticks, each of which closes an attack that has taken somebody's
account.

It also holds local storage, the caches a service worker is keeping, and a button that clears all
of it. That button is the honest way to test what a first-time visitor experiences, and it is worth
knowing that clearing site data is a different thing from disabling the cache in the network panel:
one removes what is stored, the other refuses to use it.

## The habit

When a page is not behaving, the sequence is: inspect the thing, look at what actually matched it,
and read the computed value.

Almost every styling argument ends there. The rule you expected is present and struck through
because something more specific won; or it is absent because the selector does not match what the
parser produced; or it is applying perfectly and the element you are looking at is not the element
you think it is.

All three are visible in about four seconds, and all three are invisible in the file.
