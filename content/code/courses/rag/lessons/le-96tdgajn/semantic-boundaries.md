---
title: Cutting where the meaning changes
version: 1
---

Headings are where an author said a topic changes. **Semantic chunking** tries to find where the topic
actually changes, by measuring it: embed every sentence, compare each with the next, and cut where two
neighbours are least alike. It needs no structure at all, which makes it attractive for transcripts
and other text with no headings.

```schooling-example
{
  "language": "python",
  "file": "chunking.py",
  "parts": [
    {
      "code": "def sentences(text):\n    flat = \" \".join(line for line in text.splitlines() if not line.startswith(\"#\"))\n    return [s for s in re.split(r\"(?<=[.!?])(?<!\\b\\d\\.)\\s+(?=[A-Z0-9])\", \" \".join(flat.split())) if s]",
      "note": "Sentences, split after a full stop followed by a capital or a digit. The `(?<!\\b\\d\\.)` keeps a list marker such as `1.` attached to its item."
    },
    {
      "code": "def semantic(text, quantile=0.25):\n    \"\"\"Cut between two sentences wherever their similarity is in the lowest QUANTILE.\"\"\"\n    sents = sentences(text)\n    v = embed(sents)\n    sim = (v[:-1] * v[1:]).sum(axis=1)\n    cut = np.quantile(sim, quantile)\n    chunks, start = [], 0\n    for i, s in enumerate(sim):\n        if s <= cut:\n            chunks.append(\" \".join(sents[start:i + 1]))\n            start = i + 1\n    chunks.append(\" \".join(sents[start:]))\n    return chunks",
      "note": "Every sentence is embedded, and each one is compared with the next. Where that similarity is among the lowest quarter in the document, the topic probably changed, and a chunk ends there."
    }
  ]
}
```

## What it found in the returns policy

```
ana@lab:~/rag$ python boundaries_semantic.py
 1   31 words  This policy applies to every order placed on marginalia.example ...
 2   84 words  It covers printed books, gifts and items sold by ...
 3   66 words  A book is in the condition you received it ...
 4   10 words  The statutory right of withdrawal is seven days from ...
 5   17 words  This policy gives you more than the law requires, ...
 6   35 words  1. Open the order in your account and choose ...
 7   24 words  3. Print the prepaid label we email you. If ...
 8   20 words  4. Pack the books so that they cannot move ...
 9   75 words  Returns are free. You do not pay for the ...
10  132 words  Delivery costs are refunded when you return the whole ...
11   23 words  If we sent a different title from the one ...
12  223 words  We send the right book at once with a ...
13   99 words  Items marked Sold by, followed by a seller's name, ...
```

Some of the cuts are good. Chunk 9 starts exactly at *Returns are free*, which no other strategy in
this lesson isolated so cleanly, and chunk 13 starts at the marketplace section.

Others are not. **Chunk 2 joins the end of the introduction to the start of the return window**, a
cut the heading put in the right place and the similarities did not. The four numbered steps of
starting a return are split three ways, chunks 6, 7 and 8, because consecutive instructions about
different actions are not very similar to each other even though they belong together. Chunk 4 is a
single sentence of ten words. And **chunk 12 is 223 words**, because the paragraphs on wrong titles, faulty
books, items that cannot be returned, gifts and e-books all read alike to the model, so nothing
between them fell in the lowest quarter.

## Two weaknesses, both fixable, neither free

**It has no size limit.** A semantic cut only happens where similarity drops, so a long passage on one
topic becomes one long chunk, and a chunk of 223 words is close to the limit the first section of this
lesson measured. Practical versions combine it with a maximum size, which brings back a fixed-size cut
inside long passages.

**It costs an embedding per sentence**, before any chunk is embedded. The last section of this lesson
indexed the corpus sentence by sentence and counted 319 of them; for a large corpus, embedding every
sentence first roughly doubles the indexing bill.

The measurement at the end of the lesson is the verdict on this corpus: semantic chunking found the
answer for 20 of 26 questions, one more than fixed 60-word chunks and five fewer than cutting at the
headings. **On documents with good headings, the author's own marks beat an estimate of them.** On
text with no marks it is a reasonable choice, and the choice there is between it and fixed-size cuts
with overlap.
