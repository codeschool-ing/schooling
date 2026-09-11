---
title: Where everything goes, and what colour it is
version: 1
---

The render tree says what will be drawn. It does not say where. Nothing in the markup or the styles
gave a coordinate for anything, and yet the finished page has one for every box, every line of text
and every letter.

Producing them is **layout**, and it is usually the most expensive thing on this list.

## Layout

The browser walks the tree and computes, for every box, a position and a size, in pixels, for this
window at this width.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The same markup laid out at two window widths, producing different positions, different line breaks and a different height. Nothing in the markup gave a coordinate.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">at 1200 pixels wide</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <rect x=\"36\" y=\"52\" width=\"140\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"106\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">heading</text> <rect x=\"184\" y=\"52\" width=\"140\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"254\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">an image</text> <rect x=\"36\" y=\"90\" width=\"288\" height=\"50\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">two lines of text</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">at 400 pixels wide</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <rect x=\"396\" y=\"52\" width=\"288\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">heading</text> <rect x=\"396\" y=\"86\" width=\"288\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">an image, now below</text> <rect x=\"396\" y=\"120\" width=\"288\" height=\"70\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">four lines of text</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a calculation rather than a lookup — which is why turning a phone sideways is a full one</text> </svg>", "caption": "Every position on the finished page was computed, for this window, at this width, a moment ago."}
```

That last clause is the important one. Almost nothing on a page has a fixed size: a width is a
percentage of a parent whose width is a consequence of the window, a height is whatever the content
turned out to need, a line of text breaks wherever it happens to reach the edge.

So layout is a calculation, not a lookup, and it depends on things that change. Turning a phone
sideways is a complete layout. Changing a font is a layout. Adding a sentence to a paragraph is a
layout of everything after it.

The word you will see in tools and in older writing is **reflow**, which means the same thing.

## Paint, and composite

Once every box has a rectangle, **paint** fills in what is inside it: colours, borders, text,
shadows, images. This produces pixels, usually into several separate surfaces rather than one.

Then **composite** puts those surfaces together in the right order and hands the result to the
screen. Overlapping things, transparency, and anything the hardware can draw quickly are resolved
here.

The split matters because of what it makes cheap.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three kinds of change and what each costs: a size or position change costs layout, paint and composite; a colour change costs paint and composite; a transform or opacity change costs composite alone.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"44\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"160\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">width, height, top, left, font size</text> <text x=\"440\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">layout, then paint, then composite</text> <rect x=\"20\" y=\"88\" width=\"680\" height=\"44\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"160\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">colour, background, shadow</text> <text x=\"440\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">paint, then composite</text> <rect x=\"20\" y=\"142\" width=\"680\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"160\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">transform, opacity</text> <text x=\"440\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">composite alone</text> <text x=\"360\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">animate the bottom row, and the budget for one frame is 16 ms</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">one layout of a large page on a modest phone has already spent it</text> </svg>", "caption": "The most actionable fact in the lesson, and it is a consequence of the pipeline rather than a fashion."}
```

A change that affects only compositing — moving something with a transform, changing its opacity —
can be done without laying anything out and without repainting anything. That is why an animation
built on those two properties is smooth and an animation built on `top` and `left` is not: one of
them is a composite per frame and the other is a layout and a paint per frame.

This is the single most actionable fact in the lesson. **Animate transform and opacity.** Not
because they are fashionable, but because of where they sit in this pipeline.

## What triggers what

A short table, and it is worth knowing rather than looking up.

| a change to | costs |
|---|---|
| width, height, position, font size, text | layout, then paint, then composite |
| colour, background, shadow, border colour | paint, then composite |
| transform, opacity | composite alone |

Anything higher in that table includes everything below it. There is no way to lay something out
without painting it afterwards.

## The trap with a name

One pattern is worth recognising because it turns a fast page into a slow one without any single
line looking wrong.

A script changes a style, then reads a value that depends on layout — a width, a position, the
height of something. The browser cannot answer without laying out, so it does, immediately. The
script changes another style and reads another value, and it lays out again. In a loop over forty
elements, that is forty layouts where one would have done.

This is **layout thrashing**, and the fix is to do all the reading first and all the writing
afterwards, so one layout serves the whole batch.

You do not need to write scripts to benefit from knowing it. It is one of the two or three things
that make a page stutter while the network is idle, and recognising the shape is most of the
diagnosis.

## Layers, and the temptation to make more of them

The composite step works on surfaces, and a browser decides which parts of a page get one of their
own. Something being animated, something fixed to the viewport, a video — each may be promoted to
its own layer so that moving it costs nothing but re-composing.

There is a property that asks for this deliberately, and it is worth knowing in both directions.
Used on the one or two things you are actually animating, it removes a stutter. Used on everything,
it is a well-documented way of making a page slower: each layer costs memory, and a page with
hundreds of them spends more time managing surfaces than it saved by having them.

The instinct is the same as everywhere else in this lesson. **Promote the thing that moves, not the
page it moves on.**

## Where the numbers are

Everything above is visible. A browser's performance tools record these steps with their durations,
in the lesson that follows this one.

Two numbers to carry into it. A layout of a large page on a modest phone is measured in tens of
milliseconds, and sixteen milliseconds is the budget for one frame of smooth animation — which
means a single layout inside a frame has already spent it.
