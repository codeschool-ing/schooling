---
title: Search small, return big
version: 2
---

The table in the last section showed the tension in one line: small chunks are precise to search and
lose their context, large chunks keep the context and are vague to search. **Small-to-big retrieval**
refuses to choose. It indexes small units, so that the search is precise, and returns the larger unit
each one came from, so that the prompt has the context.

`small_to_big.py` indexes every sentence of every section on its own, and remembers which section each
sentence belongs to. A question is compared with the sentences; the sections of the best-matching
sentences, three distinct ones, go to the prompt:

```schooling-example
{
  "language": "python",
  "file": "small_to_big.py",
  "parts": [
    {
      "code": "import json\n\nimport tiktoken\nfrom chunking import load, sections, sentences\nfrom vectors import embed\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if q[\"facts\"]]\nnorm = lambda t: \" \".join(t.split())",
      "note": "The test set's 26 answerable questions, and the encoding that counts the prompt's tokens."
    },
    {
      "code": "# Index sentences, but remember which section each came from.\nparents, small = [], []\nfor _, body in load().values():\n    for path, text in sections(body):\n        parents.append(text)\n        small += [(s, len(parents) - 1) for s in sentences(text)]\nv = embed([s for s, _ in small])",
      "note": "Every section is a parent, kept whole. Every sentence of it becomes a small unit, stored with the number of its parent, and only the small units are embedded."
    },
    {
      "code": "found, tokens = 0, 0\nfor q in questions:\n    scores = v @ embed(q[\"question\"])[0]\n    keep = []\n    for i in scores.argsort()[::-1]:\n        if small[i][1] not in keep:\n            keep.append(small[i][1])\n        if len(keep) == 3:\n            break\n    context = [parents[p] for p in keep]\n    found += any(f in norm(t) for t in context for f in q[\"facts\"])\n    tokens += len(enc.encode(\"\\n\".join(context)))\nprint(f\"sentences indexed: {len(small)}, sections returned: 3 per question\")\nprint(f\"found: {found}/{len(questions)}  tokens: {tokens / len(questions):.0f}\")",
      "note": "The sentences are ranked against the question, and their parents collected in that order until there are three different ones. Those three sections are the context."
    }
  ]
}
```

```
ana@vm:~/rag$ python small_to_big.py
sentences indexed: 319, sections returned: 3 per question
found: 24/26  tokens: 272
```

**24 of 26 found, for 272 tokens a question.** That is one fewer than searching whole sections, for
slightly more tokens. On this corpus small-to-big did not beat simply searching the sections, and the
reason is visible in the material: Marginalia's sections are short and about one thing each, so a
section's own vector is already precise. The approach earns its place on documents with long sections
that cover several things, where a section's vector is an average of all of them and one sentence is
a much sharper target.

## Variations on the idea

The parent does not have to be a section. Common choices:

- **sentence to window**: return the matching sentence with two or three sentences either side, a
  context window cut around the hit rather than a fixed parent;
- **chunk to section**: index structured 60-word chunks, return the section they belong to;
- **chunk to document**: for short documents, return the whole document. The help centre's articles
  are forty words each, and returning the whole article is returning the chunk.

LlamaIndex calls the first a *sentence window* and the second *auto-merging*; lesson 10 meets both
names.

## What it costs

Small units mean many vectors: 319 sentences against 92 sections, three and a half times the index.
And the parent has to be stored and looked up, so the index needs a column saying which parent each
unit belongs to, which lesson 5 provides with the heading path. The returned context is also less
predictable in size, because a parent is as long as it is; a section of 300 words comes back whole
however small the sentence that matched it.

## The chunking decision, summed up

For documents with good structure, cut along it: sections, and paragraphs packed inside them, with
the heading path stored beside every chunk. Measure two or three sizes against your own test set and
pick the one where the found count stops rising. For text without structure, fixed-size chunks with
10 to 20 per cent overlap, or semantic cuts with a size limit. Reach for small-to-big when sections
are long and mixed. And whatever you choose, keep the numbers that justified it, because the corpus
will change and the choice will need making again.
