---
title: Products bought by the same people
version: 1
---

**Collaborative filtering** recommends from the behaviour of other customers rather than from anything
known about the products. Its oldest form says: two products are similar if the same customers buy them.
Nobody tells it that flour and yeast are for baking; it notices that the people who buy one buy the
other.

The similarity is measured between the **columns** of the table. Each product is a column of 1,491 zeros
and ones, one per customer, and the **cosine similarity** of two columns is close to 1 when they have
their ones in the same rows. Save this as `similar.py`:

```python
# similar.py
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity

from holdout import split

known, _ = split()
similarity = cosine_similarity(known.T)
np.fill_diagonal(similarity, 0)
similarity = pd.DataFrame(similarity, index=known.columns, columns=known.columns)
for product in ["flour", "coffee", "garlic", "sourdough"]:
    nearest = similarity[product].nlargest(4)
    print(f"{product:10} " + ", ".join(f"{p} {s:.2f}" for p, s in nearest.items()))
```

`known.T` turns products into rows, which is what `cosine_similarity` compares. The diagonal, each
product's similarity with itself, is set to 0 so that a product is never its own nearest neighbour.

```
ana@lab:~/ml$ python similar.py
flour      cocoa 0.66, butter 0.65, yeast 0.65, oats 0.64
coffee     papaya 0.67, yoghurt 0.66, honey 0.65, granola 0.64
garlic     olive oil 0.65, chilli 0.65, lime 0.64, coriander 0.64
sourdough  eggs 0.71, cheese 0.70, avocado 0.70, vanilla 0.58
```

**Three cuisines appear without anybody naming them.** Flour sits next to cocoa, butter, yeast and oats:
baking. Coffee next to papaya, yoghurt, honey and granola: breakfast. Garlic next to olive oil, chilli,
lime and coriander: cooking. The similarity came only from who bought what, and it found the way the
products go together in a kitchen.

Sourdough is different, and worth a second look. Its neighbours are eggs, cheese and avocado, the other
add-ons everybody buys, and then vanilla at a much lower 0.58. Products that nearly everyone buys are
similar to each other mostly because they are similar to everything, and that is a known weakness of
plain cosine similarity: **popular items crowd into every list**. Production systems usually discount
them, and this lesson leaves them as they are, because the hit rate is what decides.
