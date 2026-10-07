---
title: Reranking
version: 1
---

The choice so far has looked like one dial: a small k is precise and misses things, a large k
finds them and hands on noise. **Reranking** splits it into two stages. A fast first pass fetches a
generous number of candidates, say 20, and a slower, better scorer reorders just those and keeps
the best few, say 5. The first stage is tuned for recall, the second for precision, and the slow
scorer only ever sees 20 documents however big the collection is.

## The usual second stage is a cross-encoder

Everything in this course so far is a **bi-encoder**: the question and the document are embedded
separately and compared afterwards, which is what lets the documents be embedded once and stored.
A **cross-encoder** reads the question and one document together, as one input, through a
transformer, and outputs a single relevance score. Seeing both at once lets it notice things a dot
product cannot, such as a negation that reverses what the document says about the question. The
price is that nothing can be computed in advance: every candidate costs one run of the model for
every question, which is why it is used on 20 candidates rather than on a whole collection.

In sentence-transformers it looks like this. It was **not run** here: the model is downloaded from
huggingface.co, which was out of reach from the machine this course was recorded on, and the library needs PyTorch, whose index
was out of reach too.

```python
from sentence_transformers import CrossEncoder

reranker = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")
scores = reranker.predict([(question, text) for text in candidates])
```

Hosted rerankers exist with the same shape, a question and a list of texts in and a score per text
out. The lab's stand-in provider has no rerank endpoint, so none was called here either.

## The same pattern, measured

You can see the pattern work without a cross-encoder, and both stages of the experiment below ran
on this machine. In the first, the fast pass compares **one bit per coordinate** instead
of 384 floats; in the second, the fast pass is WordLlama and the better scorer is both models
together.

```schooling-example
{
  "language": "python",
  "file": "rerank.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nqtexts = [q[\"text\"] for q in queries]\n\ndef found(ranked, k):\n    return sum(any(ids[j] in q[\"relevant\"] for j in r[:k])\n               for r, q in zip(ranked, queries))"
    },
    {
      "code": "D, Q = embed(texts), embed(qtexts)\ncodes = np.packbits(D > 0, axis=1)\nqcodes = np.packbits(Q > 0, axis=1)\nprint(\"bytes per article:\", D[0].nbytes, \"as floats,\", codes[0].nbytes, \"as bits\")",
      "note": "Keep each article twice: the 384 floats, and one bit per coordinate saying whether it is positive. 384 bits are 48 bytes."
    },
    {
      "code": "def first_pass(qc, n):\n    differing = np.unpackbits(codes ^ qc, axis=1).sum(axis=1)\n    return np.argsort(differing, kind=\"stable\")[:n]\n\ndef rerank(candidates, score):\n    return candidates[np.argsort(-score[candidates])]",
      "note": "The first pass compares bits: the fewer bits two codes disagree on, the closer they count. The rerank takes the candidates and sorts them again by a better score."
    },
    {
      "code": "print(\"                        @1  @3\")\nexact = [np.argsort(-(D @ q)) for q in Q]\nprint(\"float, every article   \", found(exact, 1), found(exact, 3))\nprint(\"bits only              \", *(found([first_pass(c, 40) for c in qcodes], k) for k in (1, 3)))\nfor n in (5, 10, 20):\n    ranked = [rerank(first_pass(c, n), D @ q) for c, q in zip(qcodes, Q)]\n    print(f\"bits {n:2}, rerank floats \", found(ranked, 1), found(ranked, 3))",
      "note": "Bits alone over all 40, then the first 5, 10 or 20 by bits reordered by the full float vectors."
    },
    {
      "code": "wl = WordLlama.load()\nW, WQ = wl.embed(texts, norm=True), wl.embed(qtexts, norm=True)\nwordllama = [np.argsort(-(W @ q)) for q in WQ]\nprint(\"wordllama only         \", found(wordllama, 1), found(wordllama, 3))\nboth = [rerank(r[:10], D @ q + W @ wq) for r, q, wq in zip(wordllama, Q, WQ)]\nprint(\"wordllama 10, rerank   \", found(both, 1), found(both, 3))",
      "note": "A second experiment: WordLlama picks 10 candidates, and they are reordered by the two models' scores added together."
    }
  ],
  "output": "ana@lab:~/emb$ python rerank.py\nbytes per article: 1536 as floats, 48 as bits\n                        @1  @3\nfloat, every article    19 22\nbits only               16 23\nbits  5, rerank floats  19 22\nbits 10, rerank floats  19 22\nbits 20, rerank floats  19 22\nwordllama only          20 24\nwordllama 10, rerank    23 24"
}
```

**The bits alone lose 3 questions at rank 1, and reranking only the first 5 candidates by the full
vectors wins all of them back.** Bits-only finds 16 at @1 against 19 for the full floats; from 5,
10 or 20 bit-candidates, reranking finds 19 again. The bits-only row also shows 23 at @3 against
22 for the floats, one question that happened to land better by chance, and a reminder that with
24 questions a difference of one is not a finding. The bits are 48 bytes per article against
1,536, so the first pass reads a thirty-second of the data; lesson 18 prices that saving at scale.

**The second experiment gains 3 questions at rank 1.** WordLlama alone finds 20 at @1 and
all-MiniLM-L6-v2 alone found 19. Taking WordLlama's 10 candidates and reordering them by the sum of
both models' scores finds 23, and 24 at @3. The two models make different mistakes, and a document
both rate highly is more often the right one. On a collection this small that is a hint and not a
law; measure it on your own questions before you build on it.

## Where reranking fits

Reranking moves the question *how many* to the first stage, where k can be generous because the
candidates are cheap, and leaves the second stage to decide the order of the few that are handed
on. The two numbers are chosen separately: the first k from the recall curve of the fast pass, the
second from what the reader downstream can use. A score threshold, if you use one, belongs to the
second stage, measured on the second stage's scores.

Lesson 5 met another kind of reordering, Maximal Marginal Relevance, which reorders for variety
rather than relevance. It slots into the same place in the pipeline.
