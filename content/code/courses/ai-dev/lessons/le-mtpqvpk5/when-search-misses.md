---
title: When search by meaning misses
version: 1
---

Embeddings are good at paraphrase and bad at exact strings. Lesson 1 section 09 predicted it, and
the handbook has the case that proves it: an error code. A customer pastes what the checkout said:

```
ana@dev:~/shop$ python scratch/search.py vector "checkout says E1042"
vector: checkout says E1042
    0.542  payment-errors.md#4  Payment errors at checkout. E2003: the billing address does no…
    0.498  payment-errors.md#1  Payment errors at checkout. The checkout shows a code when a p…
    0.492  payment-errors.md#2  Payment errors at checkout. E1001: the card was declined by th…
```

**The passage about E1042 is not in the top three.** All three results are about payment errors at
checkout, which is the subject, and the one that explains this code is missing. To an embedding,
`E1042` is a short, rare string that carries almost no meaning, and the passages about E2003 and
E1001 are as close in meaning as the right one.

## Searching by words

The older technique ranks passages by the words they share with the question, weighting a word more
when it is rare in the collection. The standard formula is **BM25**, and it fits in a function:

```python
def keyword_search(query, k=3):
    """BM25: a word counts more when it is rare in the handbook and frequent in the chunk."""
    cs, _ = load()
    docs = [words(c["text"]) for c in cs]
    avg = sum(map(len, docs)) / len(docs)
    df = Counter(w for d in docs for w in set(d))
    scores = []
    for d in docs:
        tf = Counter(d)
        s = 0.0
        for w in set(words(query)):
            if w in tf:
                idf = math.log(1 + (len(docs) - df[w] + 0.5) / (df[w] + 0.5))
                s += idf * tf[w] * 2.2 / (tf[w] + 1.2 * (0.25 + 0.75 * len(d) / avg))
        scores.append(s)
    order = sorted(range(len(cs)), key=lambda i: -scores[i])[:k]
    return [(cs[i], scores[i]) for i in order]
```

```
ana@dev:~/shop$ python scratch/search.py keyword "checkout says E1042"
keyword: checkout says E1042
    3.943  payment-errors.md#3  Payment errors at checkout. E1042: the payment timed out betwe…
    2.272  payment-errors.md#1  Payment errors at checkout. The checkout shows a code when a p…
    1.777  payment-errors.md#4  Payment errors at checkout. E2003: the billing address does no…
```

**First, by a wide margin.** `e1042` appears in one passage only, so it carries the most weight of any
word in the question. Keyword search has the opposite weakness, though:

```
ana@dev:~/shop$ python scratch/search.py keyword "my parcel never arrived"
keyword: my parcel never arrived
    3.367  shipping.md#4        Shipping. A customer can follow the parcel with the tracking c…
    2.662  contact.md#1         Contacting support. Support answers by email and chat from 9:0…
    2.417  contact.md#2         Contacting support. The target for a first reply is four worki…
ana@dev:~/shop$ python scratch/search.py vector "my parcel never arrived"
vector: my parcel never arrived
    0.568  shipping.md#4        Shipping. A customer can follow the parcel with the tracking c…
    0.297  contact.md#2         Contacting support. The target for a first reply is four worki…
    0.254  shipping.md#3        Shipping. The shop ships only to addresses in Brazil. It does …
```

*Never arrived* shares no rare words with *no tracking update for ten working days*, so keyword search
puts the right passage first only because *parcel* is in it, and fills the rest with passages about
support hours that happen to contain common words. Vector search ranks the same passage first with a
clear lead, 0.568, because it reads the meaning.

## Both at once

**Hybrid search** runs both and merges the two rankings. The merge used here is **reciprocal rank
fusion**: each list gives a passage a vote of 1/(60 + its rank), and the votes are added. It needs no
tuning, because it uses only the positions, never the two incomparable kinds of score:

```python
def hybrid_search(query, k=3):
    """Reciprocal rank fusion: each list votes 1/(60 + rank) for each chunk it found."""
    votes = Counter()
    by_id = {}
    for found in (vector_search(query, 10), keyword_search(query, 10)):
        for rank, (c, _) in enumerate(found):
            votes[c["id"]] += 1 / (60 + rank)
            by_id[c["id"]] = c
    return [(by_id[i], v) for i, v in votes.most_common(k)]
```

```
ana@dev:~/shop$ python scratch/search.py hybrid "checkout says E1042"
hybrid: checkout says E1042
    0.033  payment-errors.md#4  Payment errors at checkout. E2003: the billing address does no…
    0.033  payment-errors.md#1  Payment errors at checkout. The checkout shows a code when a p…
    0.033  payment-errors.md#3  Payment errors at checkout. E1042: the payment timed out betwe…
ana@dev:~/shop$ python scratch/search.py hybrid "my parcel never arrived"
hybrid: my parcel never arrived
    0.033  shipping.md#4        Shipping. A customer can follow the parcel with the tracking c…
    0.033  contact.md#2         Contacting support. The target for a first reply is four worki…
    0.032  contact.md#1         Contacting support. Support answers by email and chat from 9:0…
```

E1042's passage is back in the top three, in third place, and the parcel question still finds the
tracking passage first. **Hybrid search is not free**, though, and lesson 6 section 09 measures where
it does worse than either of its parts.
