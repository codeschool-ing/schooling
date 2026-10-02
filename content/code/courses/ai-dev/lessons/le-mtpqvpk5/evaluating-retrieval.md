---
title: Measuring retrieval
version: 1
---

An answer can only be as good as the passages it was given. So the first thing to measure in a RAG
system is not the answers but the search: **for each question, is the passage that answers it among
the ones retrieved?** That share is **recall at k**, where k is how many passages the prompt carries.

## A labelled set of twelve

ana writes twelve questions in the words customers use, each with the id of the passage that answers
it, and runs all three searches over them:

```python
"""Recall at 3: for each question, is the passage that answers it among the three retrieved?"""
from rag import hybrid_search, keyword_search, vector_search

CASES = [
    ("Can I send back a mug I bought last week?", "returns.md#1"),
    ("How long does delivery take to Recife?", "shipping.md#1"),
    ("checkout says E1042", "payment-errors.md#3"),
    ("card declined with E1001", "payment-errors.md#2"),
    ("my parcel never arrived", "shipping.md#4"),
    ("Do you deliver to Portugal?", "shipping.md#3"),
    ("Is shipping free if my order is 210 with a coupon?", "shipping.md#2"),
    ("Is the WELCOME10 coupon still valid in December?", "coupons.md#1"),
    ("Can I use two coupons on one order?", "coupons.md#2"),
    ("how do I change my password", "account.md#2"),
    ("is the hand-painted mug ok in the dishwasher", "products.md#1"),
    ("when is support open", "contact.md#1"),
]
for name, search in [("vector", vector_search), ("keyword", keyword_search), ("hybrid", hybrid_search)]:
    missed = [q for q, want in CASES if want not in [c["id"] for c, _ in search(q)]]
    print(f"{name:8} recall@3 = {len(CASES) - len(missed)}/{len(CASES)}")
    for q in missed:
        print(f"           missed: {q}")
```

```
ana@dev:~/shop$ python lab/eval_retrieval.py
vector   recall@3 = 11/12
           missed: checkout says E1042
keyword  recall@3 = 10/12
           missed: Can I send back a mug I bought last week?
           missed: How long does delivery take to Recife?
hybrid   recall@3 = 11/12
           missed: Can I send back a mug I bought last week?
```

Three results, and each one teaches something:

- **Vector search, 11 of 12**, missing only the error code, as lesson 6 section 06 found.
- **Keyword search, 10 of 12**, missing the two questions written in words the handbook does not use.
- **Hybrid search, 11 of 12**, and the one it misses is a question **vector search got right**. The
  fusion found E1042, and in exchange pushed *send back a mug* out of the top three, because keyword
  search ranked that passage low and the votes added up to less than three others.

**Hybrid search did not beat vector search here; it traded one miss for another.** On a different
handbook, with more codes and product references, the trade would go the other way. That is the
point of measuring: the decision is made on your questions, not on the reputation of a technique.

## Keeping the set useful

- **Questions from real users**, in their words, including typos and pasted error messages. A set
  written by the person who wrote the handbook uses the handbook's words, and every search does well
  on it.
- **Add every miss reported in production.** A customer who got the wrong answer is a labelled case.
- **Run it on every change** to the chunking, the embedding model, k or the search, the way lesson 5
  section 09 runs the prompt evaluation. Twelve cases run in seconds; a few hundred still do.
- **Measure the answers separately.** Recall says the passage was available. Whether the answer used
  it correctly is the citation check of lesson 6 section 08 plus a person reading a sample.
