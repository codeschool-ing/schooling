---
title: Lexical search
version: 2
---

Before embeddings, search engines matched words. A **lexical** search scores a document by the words
it shares with the query, weighted so that rare words count more than common ones and a word repeated
many times counts less with each repetition. The standard formula is **BM25**, used by Elasticsearch,
OpenSearch, the search extensions for PostgreSQL and most search libraries, and it is still the baseline
any retrieval method is measured against.

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "TOKEN = re.compile(r\"[a-z0-9]+(?:[-.%][a-z0-9]+)*%?\")\n\n\ndef words(text):\n    return TOKEN.findall(text.lower())",
      "note": "Words are runs of letters and digits, kept whole across a hyphen, a dot or a percent sign, so that `E-4104`, `9.90` and `12%` are one word each. Lowercase, because `Express` and `express` are the same word to a reader."
    },
    {
      "code": "def lexical(question, k=3, where=\"TRUE\", params=()):\n    \"\"\"The K chunks BM25 scores highest for the question's words.\"\"\"\n    found = rows(where, params)\n    bm25 = BM25Okapi([words(path + \" \" + text) for _, path, text in found])\n    scores = bm25.get_scores(words(question))\n    return [(*found[i], float(scores[i])) for i in np.argsort(-scores, kind=\"stable\")[:k]]",
      "note": "BM25 over the path and text of every chunk. It is rebuilt on each call, which is fine for 137 chunks and is what a search engine's inverted index does once and keeps."
    }
  ]
}
```

## Where it wins

The test set of lesson 4 was written as a customer would ask. A team whose users are developers asks
different questions, so this lesson adds a second, small one: `data/identifiers.jsonl`, six questions
built around an exact identifier, an error code, a severity level, an endpoint, a clause number.

```
ana@vm:~/rag$ python show.py vector "What does error E-4104 mean?"
1    0.367  Affiliate API reference > Errors  | | code | HTTP | meaning | | --- | --- | --- | | 
2    0.355  Affiliate API reference > Errors  | Errors are returned as JSON with a code and a me
3    0.351  Affiliate API reference > Changes in 2.3  | Version 2.3, released on 10 February 2026, added
4    0.309  Affiliate API reference > Rate limits  | A key may make 120 requests per minute. A reques
5    0.264  E-books and audiobooks > Downloading  | An e-book appears in your library as soon as the
ana@vm:~/rag$ python show.py lexical "What does error E-4104 mean?"
1    5.787  Affiliate API reference > Errors  | | code | HTTP | meaning | | --- | --- | --- | | 
2    5.148  Customer support handbook > What you can decide on your own  | A replacement for a book that arrived damaged ne
3    4.268  Warehouse on-call runbook > After an incident  | Every SEV-1 and SEV-2 gets a short review within
4    4.267  Affiliate API reference > Errors  | Errors are returned as JSON with a code and a me
5    3.824  Customer support handbook > Handing over at the end of a shift  | Before you sign off, every open chat is either c
```

Both put the error table first this time. The vector search did it on the strength of the path,
*Affiliate API reference > Errors*, and with a similarity of 0.367, barely above the change log at
0.351. The lexical search did it because `e-4104` is a word in the question and in the table and in
nothing else, and its score of 5.787 is well clear of the rest. Across the six identifier questions
the difference is not small:

| | first | top three |
| --- | --- | --- |
| vector | 3 of 6 | 4 of 6 |
| lexical | 4 of 6 | 6 of 6 |

**Lexical search found every identifier question in its top three; vector search found four.**

## Where it loses

```
ana@vm:~/rag$ python show.py lexical "how do I send a book back"
1   10.636  Customer support handbook > What you can decide on your own  | A replacement for a book that arrived damaged ne
2    9.414  Returns and refunds policy > Damaged, faulty and wrong items  | If a book arrives with a torn cover, bent corner
3    8.771  Returns policy > Damaged books  | If a book arrives damaged, send it back within 1
4    7.663  Customer support handbook > How we write  | Quote the policy in your own words and link the 
5    7.612  Returns and refunds policy > The return window  | A book is in the condition you received it when 
```

The question is the customer's phrasing of *how do I return a book*, and the help centre's article on
returns came first for the vector search in lesson 2. BM25 has no idea that *send back* means *return*.
It found the chunks that share the most words, *book* and *back*, and the best of them is the support
handbook's rule about damaged books. On the 26 customer questions it finds the answer in the top three
for 20, against 26 for the vector search.

The two failures are mirror images. **Vector search understands paraphrase and blurs identifiers;
lexical search respects identifiers and misses paraphrase.** A system whose users ask both kinds of
question needs both, which is the next section.
