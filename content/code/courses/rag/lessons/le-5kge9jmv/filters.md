---
title: Filters
version: 1
---

Some questions about which chunks to return are not about meaning at all. *Is this policy still in
force?* *May this person read it?* *Is it in the reader's language?* No similarity score can answer
them, and lesson 5 stored the answers beside every chunk for exactly this moment. A **filter** is a
condition on that metadata, applied as part of the search.

## The replaced policy, one last time

```
ana@lab:~/rag$ python show.py vector "Who pays for the return postage?"
1    0.806  Returns policy > Return postage  | Return postage is paid by the customer. You can 
2    0.537  Returns and refunds policy > How to start a return  | 1. Open the order in your account and choose Ret
3    0.514  Returns and refunds policy > How to start a return  | Returns are free. You do not pay for the label, 
4    0.508  Returns and refunds policy > Gifts  | The person who received a gift can return it wit
5    0.502  Shipping and delivery > Damage in transit  | If a parcel arrives visibly damaged, you may ref
```

The 2025 policy's *Return postage* is first, at 0.806, as it has been since lesson 1. Every method in
this lesson would keep it there: it is the most relevant chunk in the index. Relevance is not the
problem. The problem is that a customer should never be shown a superseded policy as if it were
current, and that is a rule, not a score.

```
ana@lab:~/rag$ python -c "from search import vector; [print(r[1]) for r in vector(\"Who pays for the return postage?\", 3, \"status = %s AND audience = %s\", (\"current\", \"public\"))]"
Returns and refunds policy > How to start a return
Returns and refunds policy > How to start a return
Returns and refunds policy > Gifts
```

**With `status = 'current' AND audience = 'public'` in the query, the 2025 policy cannot be returned,
and *How to start a return* comes first**, the section whose second chunk says *Returns are free*. The
filter goes into the SQL's `WHERE`, beside the ordering by distance, and the values travel as
parameters, never pasted into the string.

## Where the filter belongs

The filter is part of the search, not a step after it. Throwing away the superseded rows *after*
fetching the top three would have left two chunks; fetching more to compensate is guesswork about how
many will be thrown away. Inside the query, PostgreSQL returns three rows that pass.

With an HNSW index there is a catch, met in lesson 5: the index finds near rows first and the filter
removes some afterwards, so a strict filter can return fewer rows than the `LIMIT`. `embeddings-vectors`
lesson 17 measured that and the remedies, partial indexes and exact search over the filtered subset.
The table in this lesson has no HNSW index, since `ingest.py` does not build one, so every search here
is exact over the rows that pass.

## What this lesson does and does not cover

This lesson filters on a constant: every search here is a customer's, so `current` and `public` are
always right. The hard part, deciding the filter from **who is asking**, with a support agent seeing
the staff handbook and a customer not, and the database enforcing it rather than the application, is
lesson 14. The rule for both is the one lesson 2 argued from the finance leak: **a filter is decided by
the system, from what it knows about the reader, and never by the question.** A user who types *include
the finance documents* into a search box has asked for nothing the system should grant.
