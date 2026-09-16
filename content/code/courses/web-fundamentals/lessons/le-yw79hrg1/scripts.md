---
title: Where a script stops everything
version: 1
---

A stylesheet blocks rendering. A script does something stronger: it blocks the **parser**, which
means the tree stops being built while the script is fetched and run.

Knowing exactly where, and what three small words change about it, is most of what there is to know
about making a page appear sooner.

## Why it blocks at all

The reason is historical and still real. A script may write into the document at the point where it
sits — the old `document.write` — and it may read and change everything above it. The parser cannot
safely continue past a script without knowing what the script did, so it stops.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline in which parsing stops at an ordinary script, waits for it to be fetched and run, and resumes afterwards. The screen shows nothing for the whole of the block.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">an ordinary script tag, twelve lines into the head</text> <rect x=\"20\" y=\"38\" width=\"150\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"95\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">parsing</text> <rect x=\"176\" y=\"38\" width=\"230\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".26\" stroke=\"var(--amber)\"></rect> <text x=\"291\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fetching the script</text> <rect x=\"412\" y=\"38\" width=\"120\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".34\" stroke=\"var(--amber)\"></rect> <text x=\"472\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">running it</text> <rect x=\"538\" y=\"38\" width=\"162\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"619\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">parsing, at last</text> <rect x=\"176\" y=\"88\" width=\"356\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"354\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">no tree is built, so nothing is drawn</text> <text x=\"360\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">the parser stops because the script may change what is above it</text> <text x=\"360\" y=\"194\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">other files are still being fetched by the preload scanner — the tree is what waits</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">two words on the tag remove this bar entirely</text> </svg>", "caption": "The block is not about bandwidth. It is the tree not being built, and the tree is what gets drawn."}
```

An ordinary `<script src="...">` in the head therefore costs: a request, a download, an execution,
and only then does parsing continue. On a slow connection, that is a blank screen for the duration.

The preload scanner from the parsing reading softens this — other resources are fetched during the
block — but the tree is not built, so nothing is added to the page and nothing is drawn.

## The two attributes

Both go on the tag and both change the picture completely.

`defer` — fetch it now, alongside parsing, and run it **after** the document has been parsed.
Scripts marked this way run in the order they appear. This is what you want for almost everything:
the page is built at full speed and the code runs on a complete tree.

`async` — fetch it now and run it **the moment it arrives**, interrupting parsing wherever that
happens to be. Order is not preserved; whichever downloads first runs first. This suits a script
with no relationship to the page or to any other script, which in practice means analytics and very
little else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Three script arrangements compared: an ordinary script stops parsing; defer fetches alongside and runs after the document is parsed in order; async fetches alongside and runs the moment it arrives, in no particular order.\"> <rect x=\"20\" y=\"34\" width=\"216\" height=\"130\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"128\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&lt;script src&gt;</text> <text x=\"128\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">parsing stops</text> <text x=\"128\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">fetch, then run</text> <text x=\"128\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a blank screen, for the wait</text> <rect x=\"252\" y=\"34\" width=\"216\" height=\"130\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">defer</text> <text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">fetched alongside</text> <text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">runs after parsing, in order</text> <text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what you want, nearly always</text> <rect x=\"484\" y=\"34\" width=\"216\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"592\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">async</text> <text x=\"592\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">fetched alongside</text> <text x=\"592\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">runs on arrival, any order</text> <text x=\"592\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">for something unrelated to the page</text> <text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">in the head, with defer — discovered early, and run at the right moment</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">both attributes are ignored on a script written into the page, which has already arrived</text> </svg>", "caption": "Three arrangements, and the advice to put scripts at the end of the body predates the middle one."}
```

The third case is a **module**, which behaves like `defer` by default.

One thing that surprises people: both attributes are ignored on an inline script. They describe
when to run something that has to be fetched, and a script written into the page has already
arrived.

## Where to put it, in one paragraph

The advice that circulated for years was to put scripts at the end of the body, and it was right
before `defer` existed. It achieves the same thing — parsing finishes before the script runs — at
the cost of the browser discovering the script late.

Today: **a script tag in the head, with `defer`.** It is discovered early, fetched early, and runs
at the same moment it would have run from the end of the body. Nothing about it is a matter of
taste.

## Two events, and why people wait for the wrong one

Scripts commonly wait for a signal before touching the page, and there are two.

`DOMContentLoaded` fires when the document has been parsed and deferred scripts have run.
Stylesheets may still be outstanding and images almost certainly are. This is the one you want, and
it is what the browser tools label as a distinct line.

`load` fires when **everything** has finished — every image, every font, every frame. On a page with
a large image at the bottom, that can be several seconds later, and a script that waits for it does
nothing while the visitor is already reading.

The rule: *the tree is ready* is a different moment from *everything has downloaded*, and almost
all code wants the first.

## Third-party scripts, which are somebody else's decisions in your page

Worth its own section, because most of the script on a typical page was not written by anybody at
the company that owns the site.

An analytics tag, a chat widget, a consent banner, an advertising script, a font loader. Each is one
line in your markup and an unknown quantity of code, fetched from a host you do not control, running
with exactly the same authority as your own code.

Three consequences follow, and all three have happened publicly.

**Their availability is yours.** A blocking third-party script on a host that is slow today makes
your page slow today. `async` limits it; the safest arrangement is not to block on it at all.

**Their size is yours**, and it changes without warning. A tag that was forty kilobytes in March is
two hundred in September, and nothing in your repository changed.

**Their behaviour is yours.** A script can read the page, read the form fields, and send anything it
likes. When a third-party script is compromised, every site carrying it is compromised at once, and
this is not hypothetical.

The measures worth knowing: load them with `async` or later, keep a list of who is on the page and
why, and periodically remove the ones nobody can name a purpose for — which, on any site more than a
year old, is usually several.

## What a script costs after it arrives

One more thing, because it is the part that modern pages spend most on.

A downloaded script has to be parsed and compiled before it runs, and then it runs. On a modest
phone, a megabyte of script is not a download problem — it is a second or more of processing during
which the page does not respond to anything, because that work happens on the same thread that
handles the page.

That is the reason a site can score well on every network measurement and feel unusable. The bytes
arrived quickly; the phone is still busy with them.

The instinct worth building: ask what a script **costs to run**, not only what it costs to fetch.
The next lesson shows you where that number is.
