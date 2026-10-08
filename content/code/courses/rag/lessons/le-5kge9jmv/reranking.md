---
title: Reranking
version: 2
---

Every method so far scores a chunk without looking at the question and the chunk together. The vector
search compares two vectors that were computed separately, one per text; BM25 counts words. That is
what makes them fast enough to run over millions of chunks, and it is also their limit: the chunk's
vector was fixed before anybody asked anything.

A **reranker** is a second, slower model that reads the question and each candidate together and
scores them again. Because it is slow, it never sees the whole index: the fast search returns twenty
or fifty candidates, and the reranker reorders those. **It cannot find what the first search missed.**
Its job is to put the best of the candidates first.

## The reranker this course can run

The standard reranker is a **cross-encoder**: a transformer that takes the question and the chunk as
one input and outputs a single relevance score, trained on millions of pairs of questions and
passages marked relevant or not. The common small ones are on Hugging Face, and Ollama does not serve
them, so this course does not use one.

What this course can run is the model it already has. **A language model given the question and a
candidate together, and asked how well one answers the other, is a reranker**: it reads both at once,
which is the whole difference from the first search, and it costs one call per candidate. It is a
known technique with a plain name, pointwise LLM reranking, and its cost is the reason it is used on
twenty candidates and never on the index.

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "JUDGE = \"\"\"Question: {question}\n\nPassage:\n{passage}\n\nHow well does the passage answer the question? Reply with one whole number from 0 (not at all) to 10 (completely), and nothing else.\"\"\"",
      "note": "The instruction, the same for every candidate. The question comes first, so that the twenty requests for one question share the start of their prompt."
    },
    {
      "code": "def rerank(question, candidates, k=3):\n    \"\"\"The generator reads the question with each candidate and gives it a mark; the marks decide the order.\"\"\"\n    scores = []\n    for _, path, text, _ in candidates:\n        reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, max_tokens=4, messages=[\n            {\"role\": \"user\", \"content\": JUDGE.format(question=question, passage=path + \"\\n\" + text)}])\n        found = re.search(r\"\\d+\", reply.choices[0].message.content)\n        scores.append(int(found.group()) if found else 0)\n    order = np.argsort(-np.array(scores), kind=\"stable\")[:k]\n    return [(*candidates[i][:3], scores[i]) for i in order]",
      "note": "One call per candidate, four tokens at most for the reply, and a reply with no number counts as 0. The sort is stable, so candidates with the same mark keep the order the first search gave them, which with marks from 0 to 10 happens often."
    }
  ]
}
```

Two caveats, stated plainly. **llama3.2:3b was not trained to score passages**, and a mark from 0 to
10 is a coarse instrument: many candidates get the same one. And **twenty calls per question is
slow** on a machine without a graphics card, several seconds for each question; the measurement at the
end of this section makes more than six hundred of them. Treat what follows as the behaviour of a reranker, not
as the quality of a good one.

## What it reorders

`reorder.py` takes the hybrid search's top twenty for a question, reranks the same twenty, and marks
the chunk that holds the answer:

```schooling-example
{
  "language": "python",
  "file": "reorder.py",
  "parts": [
    {
      "code": "import sys\n\nfrom search import hybrid, rerank\n\nquestion, fact = sys.argv[1], sys.argv[2]\nbefore = hybrid(question, 20)\nafter = rerank(question, before, 20)\nfor label, rows in ((\"hybrid\", before), (\"reranked\", after)):\n    print(label)\n    for rank, (id, path, text, score) in enumerate(rows[:5], 1):\n        mark = \"  <- the answer\" if fact in \" \".join(text.split()) else \"\"\n        print(f\"  {rank}  {path}{mark}\")",
      "note": "The hybrid's top twenty, the same twenty reranked, and the first five of each, with the chunk that holds the answer marked."
    }
  ]
}
```

```
ana@vm:~/rag$ python reorder.py "How much is express delivery?" "9.90"
hybrid
  1  Shipping and delivery > Delivery options and costs
  2  Shipping and delivery > Addresses
  3  Shipping and delivery > Delivery options and costs
  4  Shipping and delivery > Parcels that are late or lost
  5  Shipping and delivery > Delivery options and costs  <- the answer
reranked
  1  Shipping and delivery > Delivery options and costs  <- the answer
  2  Returns and refunds policy > How to start a return
  3  Shipping and delivery > Delivery options and costs
  4  Shipping and delivery > Addresses
  5  Shipping and delivery > Delivery options and costs
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" aria-label=\"Two columns of five ranked chunks for the question How much is express delivery. In the hybrid search, the chunk holding the price, a Delivery options and costs chunk, is fifth. After the model reranked the same twenty candidates it is first, a How to start a return chunk is second, and the Addresses chunk falls from second to fourth.\"><defs><marker id=\"rg-5f1a2c\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">hybrid search, first five of twenty</text><text x=\"450\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the same twenty, reranked</text><rect x=\"30\" y=\"40\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"62\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"30\" y=\"90\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"62\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Addresses</text><rect x=\"30\" y=\"140\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"62\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"30\" y=\"190\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"62\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Parcels that are late or lost</text><rect x=\"30\" y=\"240\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"62\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs  (the answer)</text><rect x=\"450\" y=\"40\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"482\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs  (the answer)</text><rect x=\"450\" y=\"90\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"482\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">How to start a return</text><rect x=\"450\" y=\"140\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"482\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"450\" y=\"190\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"482\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Addresses</text><rect x=\"450\" y=\"240\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"482\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><path d=\"M314 258 C382 258 378 58 444 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#rg-5f1a2c)\"></path><path d=\"M314 108 C382 108 378 208 444 208\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-5f1a2c)\"></path></svg>", "caption": "Reranking reorders, it does not search. The twenty candidates are the hybrid search's; the model marks each against the question and the chunk with the price of express delivery moves from fifth to first. The arrows follow the two chunks that can be told apart by their paths. Headings drawn in mono are the chunks' paths, as reorder.py printed them."}
```

**The price table moved from fifth to first.** The model, reading the question and the passage
together, gave the chunk with `9.90` in it a better mark than any other of the twenty, and *Addresses*,
which only shares the word *express*, fell from second to fourth. That is the kind of correction a
reranker exists for: it sees that one chunk is about cost and the other is not. It also brought in a
chunk the hybrid had not put in its first five, *How to start a return*, at second, which has nothing
to do with express delivery; with marks from 0 to 10 and many ties, the order below the first is
coarse.

```
ana@vm:~/rag$ python reorder.py "How many days do I have to return a printed book?" "30 days from delivery"
hybrid
  1  Returns and refunds policy > The return window  <- the answer
  2  Returns policy > Returning a book
  3  Returns and refunds policy > Damaged, faulty and wrong items
  4  Returns and refunds policy > Damaged, faulty and wrong items
  5  Returns and refunds policy > The return window
reranked
  1  Returns and refunds policy > The return window  <- the answer
  2  Returns policy > Returning a book
  3  Returns and refunds policy > Damaged, faulty and wrong items
  4  Returns and refunds policy > Damaged, faulty and wrong items
  5  Terms of sale > 6. The right of withdrawal
```

For the return window, the reranker changed nothing in the first four: the current policy's *return
window* first, the 2025 policy's *Returning a book* second. Both chunks are about exactly what the
question asks, and **no reranker can know that a document has been replaced**: it scores relevance,
and the old policy is relevant. That one is for a filter, two sections on.

## Measured

Back to the last line of the table in the previous section:

| | customer questions, first | top three | identifiers, first | top three |
| --- | --- | --- | --- | --- |
| hybrid | 20 of 26 | 24 of 26 | 4 of 6 | 5 of 6 |
| hybrid, reranked | 19 of 26 | 26 of 26 | 0 of 6 | 4 of 6 |

Reranking the hybrid's top twenty recovered the two customer questions the hybrid had pushed out of
the top three and lost one first place. On the identifiers it did harm: **the chunk with the answer
came first for none of the six**, where the hybrid had four. A model that reads `E-4102` and
`E-4104` as nearly the same thing marks a passage about the wrong error as highly as one about the
right error, and the exact match that made lexical search good at these questions counts for nothing
in its mark. It took more than six hundred calls to the model to learn that.

**On this corpus, with a model not trained to rerank, it is a gain on customer questions and a loss on
identifiers**, bought at twenty calls per question. A trained cross-encoder is expected to do better,
and published comparisons show it does on most corpora, which is why production pipelines use one.
The habit this lesson teaches is the one that caught the loss here: measure the reranked list against
the one before it, on your own questions, both kinds, before paying for it.
