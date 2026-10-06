---
title: Following the document's structure
version: 1
---

A document written by a person already says where its topics begin and end. Headings mark sections,
blank lines mark paragraphs, a list marks items that belong together. Cutting along those marks keeps
every chunk about one thing, and it costs nothing but reading the marks.

## Sections, then paragraphs

`structured` in `chunking.py` cuts in two levels. First every `## ` section is separated, so that no
chunk crosses from one topic into the next. Then, inside a section, whole paragraphs are packed into a
chunk until the next paragraph would take it over the size limit:

```schooling-example
{
  "language": "python",
  "file": "chunking.py",
  "parts": [
    {
      "code": "def sections(text):\n    \"\"\"(heading path, body) for every '## ' section, the document's title first.\"\"\"\n    title = re.search(r\"^# (.+)$\", text, re.M).group(1)\n    out = []\n    for part in re.split(r\"\\n(?=## )\", text)[1:]:\n        heading, _, body = part.partition(\"\\n\")\n        out.append((f\"{title} > {heading[3:]}\", body.strip()))\n    return out",
      "note": "A section is everything from one `## ` heading to the next. Its name is a path, the document's title and then the heading, so that a chunk can say where it came from after it has been cut away."
    },
    {
      "code": "def structured(text, size):\n    \"\"\"Inside each section, whole paragraphs packed together up to SIZE words.\"\"\"\n    chunks = []\n    for path, body in sections(text):\n        pack = []\n        for para in re.split(r\"\\n\\s*\\n\", body):\n            if pack and len(\" \".join(pack + [para]).split()) > size:\n                chunks.append((path, \"\\n\\n\".join(pack)))\n                pack = []\n            pack.append(para)\n        if pack:\n            chunks.append((path, \"\\n\\n\".join(pack)))\n    return chunks",
      "note": "Inside a section, paragraphs are packed together until the next one would take the chunk over `size` words. A paragraph is never split, and a chunk never crosses into the next section."
    }
  ]
}
```

```
ana@lab:~/rag$ python structure.py
12 chunks
 120 words  Returns and refunds policy > The return window
  27 words  Returns and refunds policy > The return window
 117 words  Returns and refunds policy > How to start a return
  94 words  Returns and refunds policy > Refunds
  29 words  Returns and refunds policy > Refunds
  90 words  Returns and refunds policy > Damaged, faulty and wrong items

If a book arrives with a torn cover, bent corners or water damage, photograph it next to the
packaging and send the pictures within 14 days of delivery. We replace damaged books at no cost and
you do not need to send the damaged copy back.

If we sent a different title from the one you ordered, tell us within 14 days. Keep the parcel
closed if you can. We send the right book at once with a prepaid label for the wrong one, and you
are not charged twice.
```

**Twelve chunks for the policy, and every one starts and ends on a paragraph.** They are uneven, 27
words here and 120 there, because paragraphs are uneven; that is the price of not cutting through
them. The *How to start a return* section is one chunk of 117 words, the numbered steps and *Returns
are free* together, which is exactly the passage the postage question needs.

## The heading path travels with the chunk

Each chunk carries a path: *Returns and refunds policy > Damaged, faulty and wrong items*. The chunk
printed above never says it is about Marginalia's returns policy; it says *a book*, *we*, *14 days*.
Without the path, a reader of the retrieved chunk, person or model, cannot tell whether those 14 days
belong to returns, e-books or the seller agreement, all of which use the phrase. With it, the chunk is
self-describing.

The path is also what fixes lesson 2's lost clause numbers and lost *Rate limits* heading. Lesson 5
stores it beside every chunk, prints it in every citation, and measures what happens when it is also
embedded with the chunk's text.

## Recursive splitting

Libraries implement this idea as **recursive splitting**: try to cut at the coarsest separator, a
section break; if a piece is still too big, cut it at the next one, a blank line; then at a line
break, then at a sentence end, and only as a last resort at a word. LangChain's
`RecursiveCharacterTextSplitter` is the best known, and lesson 10 runs it on this corpus. `structured`
is the same idea with two levels, and it has one weakness the recursive version does not: a single
paragraph longer than the limit is kept whole, so a document with one enormous paragraph defeats it.
The policy's longest paragraph is well under the limit, which is why it was safe here.

## Structure that needs reading first

Markdown makes the marks easy to find. Other formats hide them: a PDF stores positioned text, not
headings; an HTML page wraps its structure in markup; a spreadsheet is a grid. The extraction step
that turns those into text decides whether any structure survives, and a pipeline that feeds PDFs
through a plain text extractor and then cuts by count has thrown the structure away twice. Lesson 11
looks at RAGFlow, a tool built mostly around that extraction problem.
