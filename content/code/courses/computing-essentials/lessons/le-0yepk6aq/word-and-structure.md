---
title: Word, where the whole program is one distinction
version: 1
---

Word has one idea in it and everything else is a consequence. **A document has structure, and
formatting is what the structure looks like.**

A heading is a heading because it is *marked* as one. Making a line eighteen point and bold
produces a line that looks like a heading and is not one, and the difference is invisible on the
page and decides what the program can do for you.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"Two panels showing the same page of a document. Both draw an identical large bold line followed by three lines of body text. The left panel, marked as a heading style, records the line as Heading 1 followed by Normal paragraphs, and can build a contents page. The right panel, marked as direct formatting, records only a Normal paragraph set to eighteen point bold, and has nothing to build a contents page from.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The same page, twice, and what the program has written down</text><rect x=\"24\" y=\"36\" width=\"322\" height=\"230\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">marked with a heading style</text><text x=\"44\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">A note on the method</text><path d=\"M44 104 L326 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M44 115 L286 115\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M44 126 L246 126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M44 140 L326 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"374\" y=\"36\" width=\"322\" height=\"230\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">made large and bold by hand</text><text x=\"394\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">A note on the method</text><path d=\"M394 104 L676 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M394 115 L636 115\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M394 126 L596 126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M394 140 L676 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"44\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what Word has recorded</text><text x=\"44\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Heading 1</text><text x=\"44\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Normal</text><text x=\"44\" y=\"218\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Normal</text><text x=\"44\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a contents page falls out of it</text><text x=\"394\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what Word has recorded</text><text x=\"394\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Normal, 18 pt, bold</text><text x=\"394\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Normal</text><text x=\"394\" y=\"218\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Normal</text><text x=\"394\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">there is nothing to build one from</text><text x=\"24\" y=\"288\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Both pages print identically. Only one of them can be navigated, renumbered or restyled in one move.</text></svg>", "caption": "Nothing on the page says which of the two you are looking at. The difference shows up the day you need a contents page."}
```

## What falls out of it

Everything on this list is free if the document is marked up and impossible if it is not:

- **A table of contents**, built and rebuilt in one click, with the right page numbers.
- **The navigation pane**, which turns a sixty-page document into a list you can click through
  and reorder by dragging.
- **Restyling the whole document at once.** Change what *Heading 1* looks like and every heading
  changes. With direct formatting, that is a hundred manual edits and one you will miss.
- **Numbering that renumbers itself** — figures, tables, headings, and the cross-references that
  point at them.
- **A screen reader that can navigate it**, which is the reason this is an accessibility matter
  and not only a tidiness one.

## The three styles that cover almost everything

You do not need to learn the style system. You need three:

| | for |
|---|---|
| **Normal** | body text. Everything that is not one of the others |
| **Heading 1, 2, 3** | the structure. Three levels is enough for almost any document |
| **Title** | the one at the top, which is not a heading and should not be in the contents |

**Set them once, in the document's own styles, rather than formatting each use.** Right-click a
style, *Modify*, change the font — and everything using it follows.

## The thing to stop doing

**Do not press Enter to make space.** A blank paragraph is a paragraph, and it moves when the
text above it reflows, which is why documents arrive with a heading alone at the bottom of a page
and its section overleaf.

Space above and below a paragraph is a **property of the style**. Set it once and every paragraph
of that kind is spaced correctly forever, including the ones you have not written.

The same applies to pressing Enter until something reaches the next page. That is what a **page
break** is for, and the difference shows up the moment a sentence is added above it.

## Track changes and comments, which are what it is actually for at work

**Comments** are questions in the margin; they change nothing. **Track changes** records every
edit as a proposal that somebody else accepts or rejects.

Two things worth knowing before sending a document to anybody:

- **Tracked changes travel in the file.** A document sent with changes still tracked carries
  every rejected sentence, every earlier price, every deleted paragraph — readable by whoever
  opens it.
- **So does the document's history in the metadata**: author names, the time it was edited, and
  sometimes the path it was saved from. *Inspect Document* removes all of it, and it is worth
  running once on anything leaving the building.
