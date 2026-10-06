---
title: Reranking
version: 1
---

Every method so far scores a chunk without looking at the question and the chunk together. The vector
search compares two vectors that were computed separately, one per text; BM25 counts words. That is
what makes them fast enough to run over millions of chunks, and it is also their limit: the chunk's
vector was fixed before anybody asked anything.

A **reranker** is a second, slower model that reads the question and each candidate together and
scores them again. Because it is slow, it never sees the whole index: the fast search returns twenty
or fifty candidates, and the reranker reorders those. **It cannot find what the first search missed.**
Its job is to put the best of the candidates first.

## The reranker this lab can run

The standard reranker is a **cross-encoder**: a transformer that takes the question and the chunk as
one input and outputs a single relevance score, trained on millions of pairs of questions and
passages marked relevant or not. The common small ones are on Hugging Face, which this lab could not
reach, so none was run.

What the lab can run is a reranker built from the embedding model it already has, by **late
interaction**, the idea behind ColBERT. MiniLM produces a vector for every word piece before it
averages them into one. Late interaction keeps the pieces and compares each piece of the question with
every piece of the chunk:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "def token_vectors(texts):\n    \"\"\"One unit vector per word piece, from the same MiniLM, before it averages them.\"\"\"\n    enc = minilm._tok.encode_batch(list(texts))\n    ids = np.array([e.ids for e in enc], dtype=np.int64)\n    mask = np.array([e.attention_mask for e in enc], dtype=np.int64)\n    hidden = minilm._model.run(None, {\"input_ids\": ids, \"attention_mask\": mask,\n                                      \"token_type_ids\": np.zeros_like(ids)})[0]\n    out = []\n    for h, m in zip(hidden, mask):\n        h = h[m.astype(bool)][1:-1]\n        out.append(h / np.linalg.norm(h, axis=1, keepdims=True))\n    return out",
      "note": "MiniLM produces one vector per word piece before it averages them; `embed` returns the average, and this keeps the pieces. The markers at each end are dropped, and every piece's vector is made unit length."
    },
    {
      "code": "def rerank(question, candidates, k=3):\n    \"\"\"Late interaction: each question piece takes its best match in the chunk, and the matches add up.\"\"\"\n    q = token_vectors([question])[0]\n    chunks = token_vectors([path + \"\\n\" + text for _, path, text, _ in candidates])\n    scores = [float((q @ c.T).max(axis=1).sum()) for c in chunks]\n    order = np.argsort(-np.array(scores), kind=\"stable\")[:k]\n    return [(*candidates[i][:3], scores[i]) for i in order]",
      "note": "For each piece of the question, its best match anywhere in the chunk; the score is the sum of those best matches. A chunk that has a good partner for every part of the question beats one that matches a few parts very well."
    }
  ]
}
```

It is a real reranking computation on a real model, with one caveat stated plainly: **all-MiniLM-L6-v2
was not trained to be used this way.** ColBERT models are trained so that their per-piece vectors are
good at this matching; MiniLM's are a by-product of training the average. Treat what follows as the
behaviour of a reranker, not as the quality of a good one.

## What it reorders

`reorder.py` takes the hybrid search's top twenty for a question, reranks the same twenty, and marks
the chunk that holds the answer:

```
ana@lab:~/rag$ python reorder.py "How much is express delivery?" "9.90"
hybrid
  1  Shipping and delivery > Delivery options and costs
  2  Shipping and delivery > Addresses
  3  Shipping and delivery > Delivery options and costs
  4  Shipping and delivery > Parcels that are late or lost
  5  Shipping and delivery > Delivery options and costs  <- the answer
reranked
  1  Shipping and delivery > Delivery options and costs
  2  Shipping and delivery > Delivery options and costs  <- the answer
  3  Shipping and delivery > Delivery options and costs
  4  Shipping and delivery > Parcels that are late or lost
  5  Shipping and delivery > Addresses
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" aria-label=\"Two columns of five ranked chunks for the question How much is express delivery. In the hybrid search, the chunk holding the price, a Delivery options and costs chunk, is fifth. After reranking the same twenty candidates it is second, and the Addresses chunk falls from second to fifth.\"><defs><marker id=\"rg-017094\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">hybrid search, first five of twenty</text><text x=\"450\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the same twenty, reranked</text><rect x=\"30\" y=\"40\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"62\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"450\" y=\"40\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"482\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"30\" y=\"90\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"62\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Addresses</text><rect x=\"450\" y=\"90\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"482\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs  (the answer)</text><rect x=\"30\" y=\"140\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"62\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"450\" y=\"140\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"482\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"30\" y=\"190\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"62\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Parcels that are late or lost</text><rect x=\"450\" y=\"190\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"482\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Parcels that are late or lost</text><rect x=\"30\" y=\"240\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"62\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs  (the answer)</text><rect x=\"450\" y=\"240\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"482\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Addresses</text><path d=\"M314 58 C382 58 378 58 444 58\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path><path d=\"M314 108 C382 108 378 258 444 258\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path><path d=\"M314 158 C382 158 378 158 444 158\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path><path d=\"M314 208 C382 208 378 208 444 208\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path><path d=\"M314 258 C382 258 378 108 444 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path></svg>", "caption": "Reranking reorders, it does not search. The twenty candidates are the hybrid search's; the reranker scores each against the question again and the chunk with the price of express delivery moves from fifth to second. Headings drawn in mono are the chunks' paths, as reorder.py printed them."}
```

**The price table moved from fifth to second**, and the *Addresses* chunk, which only shares the word
*express*, fell from second to fifth. That is the kind of correction a reranker exists for: reading
the whole question against the whole chunk, it sees that one of them is about cost and the other is
not.

```
ana@lab:~/rag$ python reorder.py "How many days do I have to return a printed book?" "30 days from delivery"
hybrid
  1  Returns and refunds policy > The return window  <- the answer
  2  Returns policy > Returning a book
  3  Returns and refunds policy > Damaged, faulty and wrong items
  4  Returns and refunds policy > Damaged, faulty and wrong items
  5  Returns and refunds policy > The return window
reranked
  1  Returns policy > Returning a book
  2  Returns and refunds policy > The return window  <- the answer
  3  Returns and refunds policy > Damaged, faulty and wrong items
  4  Terms of sale > 6. The right of withdrawal
  5  Returns and refunds policy > Damaged, faulty and wrong items
```

The same reranker made this one worse. The current policy's *return window* was first and the 2025
policy's *Returning a book* was second; reranked, they swapped. Both chunks are about exactly what the
question asks, the old one in slightly more similar words, and **no reranker can know that a document
has been replaced** — it scores relevance, and the old policy is relevant. That one is for a filter,
two sections on.

## Measured

Back to the last line of the table in the previous section:

| | customer questions, first | top three | identifiers, first | top three |
| --- | --- | --- | --- | --- |
| hybrid | 20 of 26 | 24 of 26 | 4 of 6 | 5 of 6 |
| hybrid, reranked | 19 of 26 | 26 of 26 | 4 of 6 | 4 of 6 |

Reranking the hybrid's top twenty recovered the two customer questions the hybrid had pushed out of
the top three, lost one first place, and lost one identifier question. **On this corpus, with a
reranker not trained for the job, it is roughly a wash.** A trained cross-encoder is expected to do
better, and published comparisons show it does on most corpora, which is why production pipelines
use one; but the habit this lesson teaches is the one that would catch it if it did not on yours:
measure the reranked list against the one before it, on your own questions, before paying for it.
