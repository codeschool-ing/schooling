---
title: The baseline: what everybody buys
version: 1
---

Lesson 2's rule holds here too: before anything clever, score the simplest thing that could work. For
recommendation that is **popularity**: show every customer the three best-selling add-ons they do not
already buy. It needs no model and is often hard to beat, because popular products are popular for a
reason. Save this as `popular.py`:

```python
# popular.py
import pandas as pd

from holdout import hit_rate, split

known, hidden = split()
popularity = known.sum()
print("most bought:", ", ".join(f"{p} {n}" for p, n in popularity.nlargest(5).items()))

scores = pd.DataFrame([popularity] * len(known), index=known.index)
unbought = (known == 0).sum(axis=1)[list(hidden)]
print(f"three guesses at random would find it {(3 / unbought).mean():.1%} of the time")
print(f"the three most popular add-ons not yet bought find it {hit_rate(scores, known, hidden):.1%}")
```

The table of scores gives every customer the same row, the count of buyers for each product, and
`hit_rate` rules out what each one has.

```
ana@lab:~/ml$ python popular.py
most bought: avocado 936, sourdough 936, cheese 924, eggs 922, flour 605
three guesses at random would find it 28.3% of the time
the three most popular add-ons not yet bought find it 41.2%
```

Three random guesses among the add-ons a customer does not buy would find the hidden one 28.3% of the
time; popularity finds it **41.2%**. That is a real gain and it costs nothing, and it is the number
every other recommender in this lesson has to beat.

Four of the top five are the add-ons everybody buys, avocado, sourdough, cheese and eggs, and popularity
shows them to everybody. Its weakness is exactly that: **it recommends the same three products to a
baker and to a coffee drinker**, and once a customer has those three, it has nothing to say about what
they in particular might like. The next sections use what each customer has bought to choose for them.
