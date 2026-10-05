---
title: The path of a query
version: 1
---

When a search feels slow, the vector database is the first suspect, because it is the part with
"search" in its job description. At the sizes most applications start with, it is usually the
wrong suspect. A query passes through several steps between the question and the answer, and the
way to know where the time goes is to time each one. `path.py` asks the small store one question
and times the steps apart:

```schooling-example
{
  "language": "python",
  "file": "path.py",
  "parts": [
    {
      "code": "import time\nfrom minilm import embed\nfrom tinystore import Store\n\nstore = Store.load(\"store\")\nquestion = \"my parcel says delivered but it never came\"\nfor run in range(2):                       # print the second, warm run",
      "note": "One question, asked twice: the first run pays for loading things into memory, so the second is the one printed."
    },
    {
      "code": "    t0 = time.perf_counter()\n    q = embed(question)[0]\n    t1 = time.perf_counter()\n    hits = store.search(q, k=3, model=\"all-MiniLM-L6-v2\", lang=\"en\")\n    t2 = time.perf_counter()\n    texts = [store.docs[store.where[id]] for id, _ in hits]\n    t3 = time.perf_counter()",
      "note": "The three steps of a query, timed apart: embed the question, search the collection for the best three in English, and fetch the texts of those three by id."
    },
    {
      "code": "print(f\"embed the question  {(t1 - t0) * 1000:7.3f} ms\")\nprint(f\"search {len(store.ids)} vectors   {(t2 - t1) * 1000:7.3f} ms\")\nprint(f\"fetch the texts     {(t3 - t2) * 1000:7.3f} ms\")\nprint(hits[0][0], texts[0][:50])",
      "note": "Print each step's time in milliseconds, and the best result."
    }
  ]
}
```

```
ana@lab:~/emb$ python path.py
embed the question    9.043 ms
search 39 vectors     0.155 ms
fetch the texts       0.005 ms
h09 A parcel marked as delivered that never arrived. C
```

**Embedding the question took 9.043 ms; searching 39 vectors took 0.155 ms; fetching the texts by
id took 0.005 ms.** The answer is the right one, `h09`, the article about a parcel marked as
delivered that never arrived, found with the filter `lang="en"` applied in the same call. At this
size the model is the whole cost, and the search is a rounding error beside it. Through a hosted API
the first step would also include a round trip over the internet, which no amount of database
tuning touches.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The path of one query, left to right: the question is embedded (9.043 ms), the collection is searched for the best ids (0.155 ms over 39 vectors), and the texts are fetched by id (0.005 ms). Under the search step, what a real vector database puts there: an approximate index instead of reading every vector, filters on metadata, and optionally a reranker.\"><defs><marker id=\"qpen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"90\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">question</text><path d=\"M102 65 L126 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qpen-ah0)\"></path><rect x=\"130\" y=\"40\" width=\"130\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">embed</text><text x=\"195\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">9.043 ms</text><path d=\"M262 65 L296 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qpen-ah0)\"></path><rect x=\"300\" y=\"40\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">search</text><text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0.155 ms</text><path d=\"M422 65 L456 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qpen-ah0)\"></path><rect x=\"460\" y=\"40\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">fetch text</text><text x=\"520\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0.005 ms</text><path d=\"M582 65 L616 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qpen-ah0)\"></path><rect x=\"620\" y=\"40\" width=\"90\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"665\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">answer</text><text x=\"440\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ids</text><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">measured with 39 vectors</text><path d=\"M360 150 L360 168\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"170\" y=\"170\" width=\"380\" height=\"110\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"190\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what a vector database puts in this step:</text><text x=\"200\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">· an index, not every vector (lesson 15)</text><text x=\"200\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">· metadata filters (lesson 17)</text><text x=\"200\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">· a reranker, optionally (lesson 16)</text></svg>", "caption": "One query through the small store, timed by path.py. Embedding the question is the slow step at this size; the search step is the one that grows with the collection, and the one a vector database replaces."}
```

## The steps, and what each one becomes

**1. Embed the question, with the collection's model.** The same model that embedded the
documents, as the previous sections insisted, and on every query: a question cannot be embedded in
advance. That makes it a cost per query, which the speeds lesson 10 measured put in the right
order of magnitude: one text through MiniLM on this machine takes milliseconds.

**2. Find candidates.** The small store reads every vector, which is lesson 3's exact search and
this lesson's first section. A vector database replaces this step with an **approximate index**
that reads a small part of the collection and returns nearly the same top results. That is the
step whose cost grows with the collection, and the 129.16 ms `brute.py` measured for a million
vectors is what the index exists to avoid. Lesson 15 shows how one works and what "nearly"
costs.

**3. Filter.** `lang="en"` kept the Portuguese articles out. The small store checks it on every
record and gives the ones that fail a score of minus infinity, which is correct and simple. Inside an approximate index it is harder,
because the index finds the nearest vectors first and some of them may fail the filter; lesson 17
measures what that does to the results.

**4. Rerank, optionally.** Some systems take more candidates than they need and rescore them with
a slower, better model before keeping the best few. Lesson 16 describes it. The small
store has no such step.

**5. Return ids, then fetch what they point to.** The search's own answer is ids and scores.
The text a person reads is a lookup by id, here in a Python list and in a real system in the
database or in the shop's own tables. It is the cheapest step and the one where a stale copy shows
up, if the text and its vector were not written together.

The vector databases of lessons 12 to 14 all have this shape. What separates them is how step 2 is
built, where the data lives, and who runs the machine it lives on.
