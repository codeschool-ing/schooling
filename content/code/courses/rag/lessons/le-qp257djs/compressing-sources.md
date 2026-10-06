---
title: Compressing sources
version: 1
---

A chunk of 60 words was chosen in lesson 4 because it usually holds an answer whole. It also usually
holds something else: the sentence before the answer, the exception after it, a sentence about a
different case. **Compression keeps the sentences of each source that are about the question** and
drops the rest, so the source the model reads is shorter and still the document's own words.

```schooling-example
{
  "language": "python",
  "file": "context.py",
  "parts": [
    {
      "code": "def sentences(text):\n    return [s for s in re.split(r\"(?<=[.!?])\\s+(?=[A-Z0-9])|\\n(?=- )|\\n\\n\", text) if s.strip()]",
      "note": "Sentences, cut at a full stop before a capital or a digit, at a list item and at a blank line."
    },
    {
      "code": "def compress(question, source, keep=KEEP):\n    \"\"\"Keep the sentences of a source that are about the question, in their order, and always its best.\"\"\"\n    parts = sentences(source[\"text\"])\n    scores = embed(parts) @ embed(question)[0]\n    chosen = [p for p, s in zip(parts, scores) if s >= keep or s == scores.max()]\n    return {**source, \"text\": \" \".join(\" \".join(p.split()) for p in chosen)}",
      "note": "Each sentence is compared with the question, and the ones at `KEEP` or above stay, in their original order, with the best always kept so that no source becomes empty. The cut is per sentence, so what stays is still text the document says."
    }
  ]
}
```

```
ana@lab:~/rag$ python squeezed.py "How long after my return arrives will I get the refund?"
Returns and refunds policy > Refunds
We refund within three working days of the return reaching our warehouse. The money goes back to the card or account you paid with, and your bank may take another five to ten days to show it. Delivery costs are refunded when you return the whole order; when you return part of it, they are not.
kept:
We refund within three working days of the return reaching our warehouse. The money goes back to the card or account you paid with, and your bank may take another five to ten days to show it.
```

The refunds section has three sentences; the two about when the money arrives stayed, and the one
about delivery costs went. The source is a third shorter and holds the same answer.

## Choosing where to cut

`KEEP` is a threshold, so it is chosen the way lesson 8 chose the floor: measured on the dev
questions, then checked once on the held-out ones. For each value, the three sources lesson 7 would
send are compressed, and the table counts the answers still inside them and the tokens left:

```
ana@lab:~/rag$ python squeeze.py dev
dev: 18 answerable questions
 keep  found  tokens
 0.00  17/18     134
 0.35  17/18     103
 0.45  17/18      84
 0.50  15/18      73
 0.60  15/18      71
 1.00  15/18      69
ana@lab:~/rag$ python squeeze.py held-out
held-out: 8 answerable questions
 keep  found  tokens
 0.00   8/8     167
 0.35   8/8     129
 0.45   8/8     116
 0.50   8/8      97
 0.60   8/8      87
 1.00   7/8      78
```

On the dev questions, **0.45 is the last value that loses nothing**: 17 of 18 found, as with no
compression at all, for 84 tokens instead of 134, 37% fewer. At 0.5 two answers fall out. The
held-out questions, never looked at while choosing, agree: 8 of 8 at 0.45, for 116 tokens instead of
167. A threshold that had only been tuned on the dev set and lost answers on the held-out set would be
a threshold fitted to eighteen questions.

## What compression cannot fix

```
ana@lab:~/rag$ python squeezed.py "Can I return a signed copy?"
Returns and refunds policy > Damaged, faulty and wrong items
If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days of delivery. We replace damaged books at no cost and you do not need to send the damaged copy back.
kept:
We replace damaged books at no cost and you do not need to send the damaged copy back.
```

The best source for this question is about damaged books, not about signed copies; the list of items
that cannot be returned is in a different chunk. Compression kept that source's best sentence,
because it always keeps one, and the sentence is not the answer. **Compression works inside the
sources the search found; it cannot make a wrong source right.** The question above passes the floor
on a chunk that does not answer it, which is lesson 6's problem, and the place to fix it is the
search.

Compression also has a cost lesson 7 cares about. A sentence taken out of its paragraph can lose the
condition that limited it, an "unless" in the sentence before. The threshold above keeps that rare
by keeping every sentence that is reasonably close to the question, and lesson 15, where whole
conversations are shortened, comes back to what must never be cut.
