---
title: Word in practice, and the feature behind most of the pain
version: 1
---

Four things in Word cause almost all the difficulty people have with it, and three of them are
one feature misunderstood.

## Section breaks, which is the one

A **page break** starts a new page. A **section break** starts a new *region of the document* that
can have its own margins, orientation, headers, footers and page numbering.

Almost every "my page numbers went wrong" and "my header changed on page four" is a section
break somebody inserted without meaning to, usually by choosing *Next Page* from the wrong menu.

Two things make this tractable:

- **Turn on the formatting marks** — the `¶` button, or `Ctrl+Shift+8`. Breaks, spaces and tabs
  become visible, and a document you can see the structure of is a document you can fix.
- **Headers are linked to the previous section by default.** Changing one changes both until you
  turn *Link to Previous* off, which is the setting behind most of the confusion.

## Lists that renumber themselves

Automatic numbering is genuinely good and it has one behaviour that catches everybody: a list
that continues after an interruption sometimes restarts at one, and sometimes a new list
continues from the old one.

Right-click the number: *Continue Numbering* and *Restart at 1* are both there, and they are the
fix rather than typing the numbers by hand — which works until a step is inserted.

## Paste, which has four meanings

Pasting from a web page or another document brings the other document's formatting with it, and
this is where a clean document acquires three fonts.

| | what arrives |
|---|---|
| **Keep Source Formatting** | the other document's fonts, sizes, colours |
| **Merge Formatting** | the text, adapted to where it lands |
| **Keep Text Only** | the characters, and nothing else |
| `Ctrl+Shift+V` | the shortcut for the last one, and the one to learn |

**Paste as text by default and apply your own styles.** It is one extra keystroke and it is the
difference between a document that can be restyled and one that cannot.

## Find and replace, which does more than people use

Beyond words, it will find **formatting** — every instance of eighteen-point bold — and replace
it with a **style**. That is the tool that converts a document somebody formatted by hand into a
structured one, in about five minutes rather than an afternoon.

It also takes `^p` for a paragraph mark, which makes *replace two paragraph marks with one* the
one-move fix for a document full of blank lines.

## The shortcuts that are worth the memory

| | |
|---|---|
| `Ctrl+Shift+V` | paste without formatting |
| `Ctrl+Alt+1`, `2`, `3` | apply Heading 1, 2, 3 |
| `Ctrl+Shift+N` | back to Normal |
| `Ctrl+Enter` | page break |
| `F4` | repeat the last action, which is the most underused key in the suite |
| `Ctrl+Shift+8` | show the formatting marks |

`F4` is worth a sentence of its own: apply a style, click somewhere else, press `F4`, and it
happens again. For anything repetitive that has no other shortcut, it is the whole answer.
