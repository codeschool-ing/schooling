---
title: The floor decides how many
version: 2
---

Look again at the last column of the sweep:

```
ana@vm:~/rag$ python sweep.py
  k  found  tokens  alike  above floor
  1  20/26      60      0          1.0
  2  26/26     116      3          1.8
  3  26/26     171      3          2.6
  5  26/26     279      7          3.4
  8  26/26     441     12          4.1
 12  26/26     660     16          4.7
```

Asked for twelve sources, **an average of 4.7 pass lesson 6's floor**; asked for three, 2.6. The
floor, chosen in lesson 6 to decide when to refuse, has been deciding the size of the context all
along: a question with one good match gets one source, and a question whose answer is spread over
four sections gets four.

That is a better rule than a fixed `k`, for the reason the sweep shows. A fixed `k` sends the same
number of sources to a question that needs one and to a question that needs five, so it is too many
for the first and too few for the second. A floor sends what is similar enough to be worth reading,
and a cap on `k` only protects the budget from the rare question that matches a dozen chunks.

So this lesson's pipeline asks the search for ten and lets the floor choose, as `candidates` in
`context.py` does. Ten is a ceiling, never a target; one question in the next section, about refunds for audiobooks,
reaches it, with all ten above the floor. The
floor still has the weakness lesson 6 measured, that some right answers score below it and some
wrong ones above, and the remaining sections keep it rather than replacing it.
