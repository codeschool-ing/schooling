---
title: Why the text flashes, and why the page jumps
version: 1
---

Two annoyances, both extremely common, and both explained by things earlier in this lesson. Neither
is about slowness — they are about arriving **late**, which has different causes and different
fixes.

## The font, and the flash

A web font is a file, discovered when the styles are parsed, fetched like anything else. It usually
arrives after the first paint would otherwise have happened, which leaves the browser with a
decision about text it has to draw now.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two choices while a web font is still loading: draw nothing and leave the text invisible, or draw with a fallback and swap when the font arrives, which moves the text slightly.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">wait for the font</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the text is invisible until it arrives</text> <rect x=\"20\" y=\"92\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">correct from the first moment</text> <rect x=\"20\" y=\"148\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">and it reads as broken while it waits</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">draw a fallback and swap</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">readable immediately, in a system font</text> <rect x=\"380\" y=\"92\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the reader can start before it arrives</text> <rect x=\"380\" y=\"148\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">and the text moves on the swap</text> <text x=\"360\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a fallback of similar width is what makes the right-hand column cheap</text> </svg>", "caption": "There is no third option while the font is in flight. Both columns are a choice about what the reader sees."}
```

**Wait and draw nothing.** The text is invisible until the font arrives, which is the *flash of
invisible text*. The layout is correct from the first moment and the page reads as broken while it
waits.

**Draw with a fallback and swap.** The text appears immediately in a system font, and swaps when
the real one arrives — the *flash of unstyled text*. The reader can read immediately, and the text
moves when the swap happens, because the two fonts are not the same width.

Browsers let you choose, with a `font-display` descriptor. Every choice is a trade between those
two, and there is a sensible default: **show the fallback and swap**, unless the identity of the
font matters more to you than being readable during the wait.

Three things reduce the problem rather than trading it. Fewer weights, because each is a separate
file. A **preload** hint, so the font is discovered with the stylesheet rather than after it. And a
fallback chosen for similar width, so the swap moves the text less.

## The jump, and the layout shift

The second one is more damaging and entirely avoidable.

An image with no declared dimensions occupies no space until it arrives. The browser lays the page
out without it, paints, and then — when the bytes appear — discovers that a 400-pixel-tall image
needs to go there, and moves everything below it down.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"An image with no declared size takes no space until it loads, so everything below it moves down when it arrives. With width and height attributes the space is reserved and nothing moves.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">no declared size</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a heading</text> <rect x=\"20\" y=\"66\" width=\"320\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a paragraph, read first</text> <rect x=\"20\" y=\"100\" width=\"320\" height=\"80\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".26\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the image arrives and claims 400 px</text> <text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">everything below moves down</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">width and height on the tag</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a heading</text> <rect x=\"380\" y=\"66\" width=\"320\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a paragraph, read first</text> <rect x=\"380\" y=\"100\" width=\"320\" height=\"80\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the space was reserved before the bytes</text> <text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nothing moves when it fills</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">this is why a reader taps the wrong link</text> <text x=\"360\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">an old habit, current advice, and a different reason than it used to have</text> </svg>", "caption": "Two attributes, and the browser reserves exactly the right space even when your stylesheet resizes the image."}
```

This is a **layout shift**, and it is the thing that makes a reader tap the wrong link, because the
page moved between deciding and touching.

The fix is to tell the browser the size before the bytes arrive. Put the `width` and `height`
attributes on every image — the actual pixel dimensions of the file — and modern browsers use them
to reserve exactly the right space even when your stylesheet resizes the image responsively. It
looks like a return to a very old habit and it is the current advice, for a new reason.

The same applies to anything arriving late into a space it will need: an embedded frame, a video,
an advertisement, a banner a script inserts at the top of the page. Reserve the space, or accept
that everything below it will move.

## Images, and the two numbers that matter

While we are here, because it is the largest thing most pages download.

**Dimensions.** Sending a 4000-pixel image to display it at 400 is four megabytes to draw a hundred
thousand pixels. Browsers scale it happily and the download was still four megabytes.

**Format.** The modern formats from lesson six's negotiation are frequently half the size of the
old ones for the same picture, chosen automatically, with no address changed.

And one attribute that is nearly free: `loading="lazy"` on images below the fold, which defers
fetching them until the reader approaches. It is a single word and on a long page it removes most
of the download.

Do not put it on the image at the top. That one is what the reader is waiting for, and deferring it
is the one case where this attribute makes a page worse.

## The measurements these two have names in

Both problems are measured, by name, in every performance tool, which is worth knowing before the
next lesson.

**The largest thing drawn in the visible area** — usually the main image or the headline — has a
metric for when it appears. A hero image sent in an old format at four times the needed size is the
most common reason that number is bad.

**Movement after drawing** has one too: a score that adds up how much of the screen moved and how
far, over the whole visit. Unreserved images and late banners are what push it up.

The reason to know the names is that these are the numbers a client, a search engine or a manager
will quote at you, and both of them are produced by the two mechanisms in this reading rather than
by anything a server did.

## Neither of these is slowness

Worth ending on, because it changes what you would measure.

The font was not slow; it was discovered late and drawn twice. The image was not slow; it was
allowed to arrive into a space that was not reserved.

Both are visible in a way that a two-hundred-millisecond difference in a response time never is,
and both are fixed by an attribute rather than by a faster server. That is the argument for knowing
this lesson: it separates the problems a network can solve from the problems only the page can.
