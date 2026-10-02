---
title: Searching by meaning
version: 1
---

With every passage a normalised vector, the search is one multiplication: the question's vector
against the matrix gives a cosine for every passage at once, and the top few are the result.

```python
def vector_search(query, k=3):
    cs, vectors = load()
    scores = vectors @ WordLlama.load().embed([query], norm=True)[0]
    return [(cs[i], float(scores[i])) for i in np.argsort(-scores)[:k]]
```

`lab/search.py` prints the top three with their scores and the start of each passage. A customer
asking about a return in their own words:

```
ana@dev:~/shop$ python lab/search.py vector "Can I send back a mug I bought last week?"
vector: Can I send back a mug I bought last week?
    0.318  returns.md#1         Returns and refunds. A customer may return any item within 30 …
    0.276  returns.md#3         Returns and refunds. The refund goes back to the original paym…
    0.266  warranty.md#3        Warranty. Under warranty the shop replaces the item, or refund…
```

**The right passage is first, and the question shares almost no words with it.** The customer wrote
*send back* and *bought last week*; the handbook says *return* and *within 30 days of delivery*.
That is the case embeddings exist for, and the one a keyword search would miss, as lesson 6 section
06 shows.

```
ana@dev:~/shop$ python lab/search.py vector "How long does delivery take to Recife?"
vector: How long does delivery take to Recife?
    0.481  shipping.md#1        Shipping. Orders ship within two working days from the warehou…
    0.327  shipping.md#4        Shipping. A customer can follow the parcel with the tracking c…
    0.299  returns.md#1         Returns and refunds. A customer may return any item within 30 …
```

The handbook never mentions Recife. It mentions *delivery inside Brazil takes three to eight working
days*, and that passage comes first, with the clearest lead of any search in this lesson: 0.481
against 0.327 for the next.

## Reading the scores

- **Only the order is used.** The search takes the top three whatever their scores, which means it
  always returns three passages, relevant or not. Lesson 6 section 07 shows what the prompt does
  about that.
- **A threshold is tempting and fragile.** "Ignore anything below 0.3" looks sensible on these two
  questions and would have thrown away the right answer to the first, at 0.318. Scores move with the
  model, the length of the question and the wording of the passages. If you use one, set it from an
  evaluation (lesson 6 section 09), not from two examples.
- **The second and third results are part of the answer's context.** Here they are other passages
  about returns and delivery, which is harmless. On another question they can be passages that look
  related and say something different, and the model reads them too.
