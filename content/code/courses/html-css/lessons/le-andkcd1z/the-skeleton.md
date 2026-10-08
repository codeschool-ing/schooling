---
title: The document every page starts from
version: 2
---

Every HTML page you write starts from the same dozen lines. Here they are for the bookshop's first page, with what each part is for beside it:

```schooling-example
{"language": "html", "file": "skeleton.html", "parts": [
 {"code": "<!doctype html>", "note": "Says the page is modern HTML. Without it the browser falls back to an older set of rules, section 08."},
 {"code": "<html lang=\"en\">", "note": "The root element: everything else is inside it. `lang` names the language of the content, which decides the voice a screen reader uses and how words are hyphenated."},
 {"code": "  <head>\n    <meta charset=\"utf-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n    <title>Andorinha Books</title>\n  </head>", "note": "Information about the page, none of it drawn. The character encoding, how to size the page on a phone (both section 10), and the title the browser shows on its tab."},
 {"code": "  <body>\n    <h1>Andorinha Books</h1>\n    <p>Second-hand books in Pinheiros, São Paulo.</p>\n  </body>", "note": "The page itself: everything the reader sees is in here."},
 {"code": "</html>", "note": "Closes the root, and the document ends."}
]}
```

Open the file in a browser and you get a heading and a sentence on a white page: exactly what the body says, drawn in the browser's default styles. Everything above `<body>` is invisible, and it is still read by every browser that opens the page.

## The tree the browser builds

The browser does not keep the text. It reads it once, from top to bottom, and builds a **tree** of elements: the **DOM**, which lesson 10 of `web-fundamentals` introduced. The file above becomes this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The skeleton document as a tree. html is the root, with lang set to en. It has two children: head, which holds the meta charset, the meta viewport and the title, and body, which holds the h1 and the paragraph. Nothing in head is drawn on the page; everything in body is what the reader sees.\"><rect x=\"410\" y=\"66\" width=\"296\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"14\" y=\"66\" width=\"352\" height=\"200\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><line x1=\"360\" y1=\"48\" x2=\"190\" y2=\"90\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"48\" x2=\"530\" y2=\"90\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"118\" x2=\"70\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"118\" x2=\"190\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"118\" x2=\"318\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"530\" y1=\"118\" x2=\"470\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"530\" y1=\"118\" x2=\"600\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"283.4\" y=\"20\" width=\"153.2\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;html lang=&quot;en&quot;&gt;</text><rect x=\"154.4\" y=\"90\" width=\"71.2\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;head&gt;</text><rect x=\"494.4\" y=\"90\" width=\"71.2\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;body&gt;</text><rect x=\"11\" y=\"166\" width=\"118\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;meta charset&gt;</text><rect x=\"128\" y=\"166\" width=\"124\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;meta viewport&gt;</text><rect x=\"275\" y=\"166\" width=\"86\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;title&gt;</text><rect x=\"440\" y=\"166\" width=\"60\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;h1&gt;</text><rect x=\"570\" y=\"166\" width=\"60\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;p&gt;</text><text x=\"308\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Andorinha Books</text><text x=\"470\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Andorinha Books</text><text x=\"600\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Second-hand books…</text><text x=\"190\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">about the page: nothing here is drawn</text><text x=\"540\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the page itself: what the reader sees</text></svg>", "caption": "Every element has exactly one parent, and the whole document hangs from the html element."}
```

Three words for positions in the tree come up in every CSS lesson, so they are worth fixing now. `<head>` and `<body>` are **children** of `<html>`, and `<html>` is their **parent**. `<h1>` and `<p>` are **siblings**, because they share a parent. And every element inside `<body>`, at any depth, is one of its **descendants**. Lesson 5 picks elements by exactly these relations: "a paragraph that is a child of a section" is a CSS selector.

The tree is also what a screen reader uses, and `probe tree` prints its view of it. For the skeleton it found a heading at level 1 and a paragraph, and nothing from the head, which is correct:

```
ana@laptop:~/site$ probe skeleton.html title tree
title: "Andorinha Books"
- heading "Andorinha Books" [level=1]
- paragraph: Second-hand books in Pinheiros, São Paulo.
```

`head` and `body` do not appear: they are structure, and nothing in the head is content. The first line comes from a separate step, `title`, which prints the name of the whole document: the name a screen reader announces when the page opens.

## Indentation is for you

The browser ignores the indentation, and the lines would mean the same written as one long line. It is there because a person reading the file needs to see which element is inside which. Two spaces per level is common and is what this course uses; what matters is that the file is consistent, because inconsistent indentation hides a missing closing tag better than anything else.
