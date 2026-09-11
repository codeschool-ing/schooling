---
title: From text to a tree
version: 1
---

What arrived is a stream of characters. What the browser needs is a structure it can ask questions
about — *what is inside this?*, *what is this inside of?* — and the first job is to turn one into
the other.

```
<article>
  <h1>Preço</h1>
  <p>Um <em>bom</em> negócio</p>
</article>
```

The nesting in that text is a tree, and the browser builds it as the characters arrive.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The nesting of the markup becomes a tree: an article containing a heading and a paragraph, with the paragraph containing text and an emphasis element.\"> <rect x=\"270\" y=\"30\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">article</text> <path d=\"M330 72 L200 108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M390 72 L520 108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"110\" y=\"114\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"200\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h1</text> <rect x=\"430\" y=\"114\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"520\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">p</text> <path d=\"M200 156 L200 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M490 156 L420 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M550 156 L620 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"130\" y=\"196\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"200\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"Preço\"</text> <rect x=\"350\" y=\"196\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"420\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"Um \"</text> <rect x=\"550\" y=\"196\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"620\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">em</text> <text x=\"360\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">built as the characters arrive, not after the file has finished</text> </svg>", "caption": "The nesting in the text was always a tree. The parser is what makes it one the browser can ask questions about."}
```

That tree is the **DOM** — the document object model. It is not the HTML file; it is what the file
produced, and the difference matters more than it sounds. The file is a fixed set of bytes. The
tree is a live structure that scripts can change, that the browser repairs when the file is wrong,
and that ends up containing things the file never mentioned.

## It happens as the bytes arrive

The parser does not wait for the file to finish. It reads the first chunk, builds what it can, and
carries on when the next arrives.

This is why a large page can start appearing before it has finished downloading, and it is why the
**order of a file matters** in ways that a file format alone would not suggest. Everything in this
lesson that blocks something else blocks it at the point in the file where it sits.

It also explains a detail worth knowing: a server that can begin sending the first part of a page
before the rest is ready gives the browser work to do during the wait. That is what the chunked
encoding of lesson six is for, seen from the other end.

## What the browser does with broken markup

HTML parsing has one property that no other format in this course shares: **it does not fail.**

A missing closing tag, a tag nested where it may not go, an attribute without quotes — none of
these produces an error. The specification says exactly what to do with each case, in detail, and
every browser does the same thing. The result is a tree, always.

That is a deliberate decision with a real cost and a real benefit.

The benefit is the web's back catalogue. Pages written in 1996 by people who had never read a
specification still render, and a format that refused them would have made the web a smaller and
much less interesting place.

The cost is that **nothing tells you when you were wrong.** The page looks right, the tree is not
what you wrote, and the surprise arrives later — usually when a script looks for an element and
finds it somewhere you did not put it. A validator is the tool that tells you what the parser
silently forgave, and it is worth running once on anything you suspect.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Markup written with a mistake and the tree the parser produces from it, which is valid and is not what the file implied. Nothing reports an error.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">what was written</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"40\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;p&gt;</text> <text x=\"56\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;div&gt;preço&lt;/div&gt;</text> <text x=\"40\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;/p&gt;</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">what the tree holds</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"96\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"400\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;p&gt;&lt;/p&gt;</text> <text x=\"400\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;div&gt;preço&lt;/div&gt;</text> <text x=\"400\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">the paragraph was closed early</text> <text x=\"360\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">no error, no warning, and every browser agrees on this result</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">which is what keeps thirty years of pages rendering</text> <text x=\"360\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">and what makes a script that looks for the wrong place find nothing</text> </svg>", "caption": "HTML parsing does not fail. It repairs, silently, and the tree it produces is what your script will meet."}
```

The clearest case is the one that catches everybody: a table row placed outside a table, or a
paragraph containing a block-level element. The parser moves things, closes things and inserts
things until the tree is valid, and what you get is correct by the specification and not what the
file implied.

## The scanner that runs ahead

One mechanism worth knowing by name, because it explains something that would otherwise look
impossible.

When the parser stops — and the scripts reading will show you exactly when it does — the browser
does not idle. A second, much simpler reader runs ahead through the rest of the bytes looking for
one thing: addresses. Stylesheets, scripts, images. It starts fetching them immediately, while the
real parser is still blocked.

This is the **preload scanner**, and it is why a page with a blocking script near the top does not
serialise every download behind it. The fetches overlap; only the *parsing* is stopped.

Two practical consequences. It only sees what is written in the markup — a resource whose address
is assembled by a script is invisible to it, and arrives late. And it is the reason an explicit
hint, telling the browser about something important before it is discovered, is a real technique
rather than a superstition.

## Which is why the tree is what you inspect

The practical conclusion, and it prepares the next lesson.

When a page is not behaving, reading the HTML file tells you what was sent. The **elements panel**
of a browser's tools shows the tree, which is what exists. Between those two are the parser's
repairs and everything any script has done since.

Beginners read the file. The habit worth building now is to read the tree.

## Two names for the same thing, nearly

One clarification, because the words are used loosely and the distinction becomes important later.

The **document** is the tree. The **render tree** of two readings from now is a different thing
built from it, containing only what will be drawn. An element removed from the document is gone; an
element hidden by a style is still in the document and absent from the render tree.

Keeping those apart explains a great deal of behaviour that otherwise looks arbitrary — including,
in that later reading, why two ways of hiding something behave completely differently.
