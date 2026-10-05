---
title: Hybrid search
version: 1
---

The last two sections leave an awkward result. The embedding search is far better on questions in
the customer's own words, and keyword search is perfect on exact strings. A real search box gets
both. **Hybrid search** runs the two side by side and merges their rankings into one.

## Merge ranks, not scores

Adding the two scores does not work. BM25 printed 3.22 and 4.11 earlier in this lesson; the
embedding search prints cosines like 0.446. The numbers live on different scales, and a sum would
be decided by whichever scale happens to be larger.

Ranks are on the same scale in both lists. **Reciprocal rank fusion** (RRF) gives each document,
from each list, `1 / (k + rank)`, and adds them up:

`score(d) = 1 / (k + rank in keyword list) + 1 / (k + rank in embedding list)`

A document missing from a list gets nothing from it. `k` is a constant that softens the difference
between first and second place, and 60, the value from the paper that introduced RRF in 2009, is
the usual default.

```schooling-example
{
  "language": "python",
  "file": "hybrid.py",
  "parts": [
    {
      "code": "import collections\nfrom bm25 import keyword_search, help\nfrom evaluate import embedding_search, recall, natural, exact\nfrom search import ids",
      "note": "The two searches and the measure come from the files before: `keyword_search` from `bm25.py`, and `embedding_search`, `recall` and both sets of judgements from `evaluate.py`."
    },
    {
      "code": "def rrf(rankings, weights=None, k=60):\n    weights = weights or [1] * len(rankings)\n    scores = collections.defaultdict(float)\n    for ranking, weight in zip(rankings, weights):\n        for rank, doc in enumerate(ranking, start=1):\n            scores[doc] += weight / (k + rank)\n    return sorted(scores, key=lambda d: -scores[d]), scores",
      "note": "Reciprocal rank fusion: each document gets `weight / (k + rank)` from every list it appears in, and the totals are sorted. Ranks start at 1."
    },
    {
      "code": "query = \"how fast is shipping\"\nkw, em = keyword_search(query), embedding_search(query)\nfused, scores = rrf([kw, em])\nfor doc in fused[:3]:\n    k_rank = kw.index(doc) + 1 if doc in kw else \"-\"\n    print(f\"{ids[doc]}  keyword {k_rank}  embedding {em.index(doc) + 1}\"\n          f\"  rrf {scores[doc]:.5f}  {help[doc]['title']}\")",
      "note": "The worked example: the fused top three for one question, with each article's rank in both lists. A dash would mean the keyword search did not return it at all."
    },
    {
      "code": "methods = {\n    \"keyword\": keyword_search,\n    \"embedding\": embedding_search,\n    \"hybrid\": lambda t: rrf([keyword_search(t), embedding_search(t)])[0],\n    \"hybrid, keyword x0.5\": lambda t: rrf([keyword_search(t), embedding_search(t)], [0.5, 1])[0],\n}\nprint(\"                       24 questions    8 exact strings\")\nfor name, rank in methods.items():\n    print(f\"{name:22} @1 {recall(rank, natural, 1):2}  @3 {recall(rank, natural, 3):2}\"\n          f\"    @1 {recall(rank, exact, 1)}  @3 {recall(rank, exact, 3)}\")",
      "note": "Four searches measured on both sets: each alone, fused with equal weights, and fused with the keyword list counting half."
    }
  ]
}
```

```
ana@lab:~/emb$ python hybrid.py
h10  keyword 2  embedding 2  rrf 0.03226  Shipping outside the country
h07  keyword 9  embedding 1  rrf 0.03089  Delivery times and costs
h14  keyword 3  embedding 9  rrf 0.03037  How to return a book
                       24 questions    8 exact strings
keyword                @1 10  @3 15    @1 8  @3 8
embedding              @1 19  @3 22    @1 3  @3 7
hybrid                 @1 11  @3 20    @1 7  @3 8
hybrid, keyword x0.5   @1 15  @3 22    @1 7  @3 8
ana@lab:~/emb$ python search.py "4.90"
 0.254  h39  Prazos e custos de entrega
 0.090  h06  Where to find your order number
 0.090  h25  Prices and price changes
```

## A worked example

The first three lines are the fused top three for *how fast is shipping*, whose answer is
**Delivery times and costs**, h07:

| article | keyword rank | embedding rank | RRF score |
|---|---|---|---|
| h10 Shipping outside the country | 2 | 2 | 1/62 + 1/62 = 0.03226 |
| h07 Delivery times and costs | 9 | 1 | 1/69 + 1/61 = 0.03089 |
| h14 How to return a book | 3 | 9 | 1/63 + 1/69 = 0.03037 |

The embedding search had the right answer first. BM25 ranked it ninth, because the article never
says *shipping*. **Fusion rewards agreement**, so the article both lists put second beat the one
that one list put first. That is RRF working as designed, and on this question it made the result
worse.

## What it did across all the questions

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Bar chart of recall at 1 and at 3 for four searches, on the 24 questions and on the 8 exact strings. keyword: 10 and 15 of 24 questions at 1 and 3, 8 and 8 of 8 exact strings; embedding: 19 and 22 of 24 questions at 1 and 3, 3 and 7 of 8 exact strings; hybrid: 11 and 20 of 24 questions at 1 and 3, 7 and 8 of 8 exact strings; hybrid, keyword ×0.5: 15 and 22 of 24 questions at 1 and 3, 7 and 8 of 8 exact strings.\"><text x=\"190\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">24 ordinary questions</text><path d=\"M190 52 L190 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M490 52 L490 262\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"490\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><text x=\"190\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"190\" y=\"64\" width=\"125\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"321\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><rect x=\"190\" y=\"82\" width=\"187.5\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"383.5\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">15</text><rect x=\"190\" y=\"114\" width=\"237.5\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"433.5\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">19</text><rect x=\"190\" y=\"132\" width=\"275\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"471\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">22</text><rect x=\"190\" y=\"164\" width=\"137.5\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"333.5\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11</text><rect x=\"190\" y=\"182\" width=\"250\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"446\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">20</text><rect x=\"190\" y=\"214\" width=\"187.5\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"383.5\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15</text><rect x=\"190\" y=\"232\" width=\"275\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"471\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">22</text><text x=\"530\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">8 exact strings</text><path d=\"M530 52 L530 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M690 52 L690 262\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"690\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"530\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"530\" y=\"64\" width=\"160\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"696\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><rect x=\"530\" y=\"82\" width=\"160\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"696\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">8</text><rect x=\"530\" y=\"114\" width=\"60\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"596\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"530\" y=\"132\" width=\"140\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"676\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">7</text><rect x=\"530\" y=\"164\" width=\"140\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><rect x=\"530\" y=\"182\" width=\"160\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"696\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">8</text><rect x=\"530\" y=\"214\" width=\"140\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><rect x=\"530\" y=\"232\" width=\"160\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"696\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">8</text><text x=\"176\" y=\"81\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">keyword</text><text x=\"176\" y=\"131\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">embedding</text><text x=\"176\" y=\"181\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">hybrid</text><text x=\"176\" y=\"231\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">hybrid, keyword ×0.5</text><rect x=\"20\" y=\"14\" width=\"12\" height=\"12\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"38\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">right article first</text><rect x=\"220\" y=\"14\" width=\"12\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"238\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">in the top three</text></svg>", "caption": "Recall at 1 and at 3 for the four searches hybrid.py measured. Fusing the two lists rescues the exact strings and, with equal weights, costs the ordinary questions much of what the embedding search had won."}
```

**With equal weights, hybrid search found 7 of the 8 exact strings first, where the embedding
search alone found 3. On the 24 ordinary questions it put the right article first 11 times, where
the embedding search alone managed 19.** On this help centre, equal fusion buys the exact strings
with the ordinary questions, and the ordinary questions are most of the traffic.

Weights are the dial. Halving the keyword list's weight, so that its votes count half as much,
keeps 7 of 8 exact strings and recovers the top-three figure of 22, with 15 first instead of 11.
Other weights would land elsewhere, and choosing one is exactly the job of the relevance judgements
from *Measuring a search*: measure on your own questions, including the pasted order numbers and
prices, and keep the weight that serves them.

The last command shows why the exact strings need help at all. Asked for `4.90`, the embedding
search returns the Portuguese delivery article at 0.254, which writes the same price as `4,90`,
and the next two at 0.090. BM25 found the English article holding the exact
string. Some systems route a query that looks like a code or a number straight to keyword search
instead of fusing; Weaviate's hybrid queries expose the balance as a single `alpha`, which lesson
12 shows.
