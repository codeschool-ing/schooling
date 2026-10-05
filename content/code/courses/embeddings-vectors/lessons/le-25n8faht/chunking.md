---
title: Long documents and chunks
version: 1
---

Every article in the help centre is short, one subject and about forty words. Real documents are
often not: a manual, a policy, a page that grew a section a year. The natural first move is to
embed each document whole, one vector per document, and it is the wrong one once a document covers
several subjects.

A vector is one point. A page about three things gets a point somewhere between the three, close to
none of them, and **every question about one of its subjects matches it weakly**. The fix is to cut
the document into **chunks**, embed each chunk, search the chunks, and return the document the best
chunk belongs to.

## Measuring it

`chunking.py` rebuilds the English help centre the way it might once have been: 13 pages, each
up to three neighbouring articles of one category run together. Then it searches the pages three ways and
asks, for each of the 24 questions, whether the page holding the answer came first.

```schooling-example
{
  "language": "python",
  "file": "chunking.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed, pieces\n\nhelp = [h for h in map(json.loads, open(\"data/help.jsonl\")) if h[\"lang\"] == \"en\"]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]",
      "note": "Only the English articles, and the 24 questions."
    },
    {
      "code": "pages = []\nfor category in (\"orders\", \"shipping\", \"returns\", \"payments\", \"account\", \"ebooks\"):\n    articles = [h for h in help if h[\"category\"] == category]\n    for i in range(0, len(articles), 3):\n        group = articles[i:i + 3]\n        pages.append(([h[\"id\"] for h in group],\n                      \" \".join(h[\"title\"] + \". \" + h[\"body\"] for h in group)))\nprint(f\"{len(pages)} pages, the longest {max(len(pieces(t)) for _, t in pages)} word pieces\")",
      "note": "Build the old help centre: for each category, run up to three neighbouring articles together into one page, and remember which articles each page holds. `pieces` counts what the model would read."
    },
    {
      "code": "def windows(text, size=40, overlap=10):\n    w = text.split()\n    return [\" \".join(w[i:i + size]) for i in range(0, max(len(w) - overlap, 1), size - overlap)]\n\nchunkings = {\n    \"whole page\": [(p, text) for p, (_, text) in enumerate(pages)],\n    \"one article\": [(p, h[\"title\"] + \". \" + h[\"body\"])\n                    for p, (members, _) in enumerate(pages) for h in help if h[\"id\"] in members],\n    \"40-word window\": [(p, w) for p, (_, text) in enumerate(pages) for w in windows(text)],\n}",
      "note": "Three ways to cut the pages into vectors: the whole page, one chunk per article, and windows of 40 words that share 10 with the next. Every chunk keeps the number of the page it came from."
    },
    {
      "code": "Q = embed([q[\"text\"] for q in queries])\nfor name, chunks in chunkings.items():\n    V = embed([text for _, text in chunks])\n    owner = np.array([p for p, _ in chunks])\n    right, best = 0, []\n    for q, v in zip(queries, Q):\n        scores = V @ v\n        right += bool(set(pages[owner[scores.argmax()]][0]) & set(q[\"relevant\"]))\n        best.append(scores.max())\n        if q[\"id\"] == \"q15\":\n            example = f\"{' '.join(pages[owner[scores.argmax()]][0])} at {scores.max():.3f}\"\n    print(f\"{name:15} {len(chunks):3} vectors  right page first {right:2}/24\"\n          f\"  mean best {np.mean(best):.3f}  q15: {example}\")",
      "note": "For each chunking, embed the chunks, find the best chunk for each question, and check whether its page holds the answer. Also keep the best score, and the result for question q15."
    }
  ]
}
```

```
ana@lab:~/emb$ python chunking.py
13 pages, the longest 175 word pieces
whole page       13 vectors  right page first 18/24  mean best 0.411  q15: h35 h36 h37 at 0.199
one article      37 vectors  right page first 21/24  mean best 0.511  q15: h35 h36 h37 at 0.431
40-word window   59 vectors  right page first 19/24  mean best 0.510  q15: h35 h36 h37 at 0.409
```

**Embedded whole, the pages put the right one first for 18 questions out of 24. Cut at the
article boundaries, 21.** The best score per question also rose, from 0.411 on average to 0.511.
Question q15, *make the letters bigger when reading*, shows it in one line. All three methods found the right page, the one holding h35, h36 and h37, but the whole page matched at 0.199 and the
article about fonts inside it at 0.431. The answer was always there; a page-sized vector had
watered it down.

None of this was the model running out of room. The longest page is 175 word pieces and
all-MiniLM-L6-v2 reads 256, so every word of every page went in. A text longer than that loses its
end without any warning, which is a second and separate reason to chunk; lesson 9 shows it.

## Size, overlap and boundaries

Two numbers define a simple chunker, and both are choices rather than facts:

- **Size.** Small chunks are about one thing and match sharply, but a sentence torn from its
  context can stop making sense. Large chunks keep the context and drift back towards the
  whole-page problem.
- **Overlap.** Windows that share a few words at each edge keep a sentence that crosses a
  boundary whole in at least one of them. `windows()` uses 40 words with 10 shared, which made 59
  chunks from 13 pages.

The fixed windows scored 19 out of 24, below the 21 of the article boundaries. **A boundary the
author drew, such as a heading, a paragraph or an article, is usually a better place to cut than a
word count**, because it already separates subjects. Windows are for text that has no such marks.

Whatever the cut, keep the link from each chunk back to its document, as `owner` does here: the
search ranks chunks, and the customer wants the page. The `rag` course takes chunking further,
because there the chunks themselves are handed to a language model.
