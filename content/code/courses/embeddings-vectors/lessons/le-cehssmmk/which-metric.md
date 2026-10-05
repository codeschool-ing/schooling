---
title: Which measure to use
version: 1
---

Three measures have appeared in this lesson: the dot product, cosine similarity and L2 distance. It
is easy to treat the choice as a matter of taste, or to pick the one that sounds most precise.
**The choice belongs to the model.** It was trained to make some measure high for texts that go
together, and its documentation says which. all-MiniLM-L6-v2 was trained for cosine similarity, and
because it returns normalised vectors, the dot product and L2 give the same ranking as cosine, as
`euclid.py` showed.

So the rule is short. Use the measure the model was trained with. If its vectors are normalised, or
you normalise them yourself, any of the three ranks identically, and the **dot product**, called
*inner product* in most libraries, is the cheapest to compute.

## Similarities and distances

Vector databases and libraries mostly sort from smallest to largest, because they are built around
distances. Each measure therefore arrives in one of two forms, and the name tells you which:

| measure | as a similarity (higher is closer) | as a distance (lower is closer) |
|---|---|---|
| cosine | cosine similarity, −1 to 1 | **cosine distance** = 1 − cosine similarity, 0 to 2 |
| dot product | inner product | negative inner product |
| L2 | — | L2 distance, or its square |

PostgreSQL's `pgvector` extension has one operator for each distance, and the two vectors from the
start of this lesson show all three:

```schooling-example
{
  "language": "sql",
  "file": "metrics.sql",
  "parts": [
    {
      "code": "CREATE EXTENSION vector;",
      "note": "The extension is installed in the database once. Lesson 14 starts from here."
    },
    {
      "code": "SELECT '[2,1,2]'::vector <-> '[1,2,2]' AS l2_distance,\n       '[2,1,2]'::vector <=> '[1,2,2]' AS cosine_distance,\n       '[2,1,2]'::vector <#> '[1,2,2]' AS negative_inner_product;",
      "note": "The same two vectors as on paper, written as `vector` literals, and one column per operator."
    }
  ]
}
```

```
ana@lab:~/emb$ psql -f metrics.sql
CREATE EXTENSION
    l2_distance     |   cosine_distance   | negative_inner_product 
--------------------+---------------------+------------------------
 1.4142135623730951 | 0.11111111111111116 |                     -8
(1 row)
```

`<->` is the L2 distance, 1.414 as on paper. `<=>` is the cosine distance: 1 − 0.8889, printed as
`0.11111111111111116` because of rounding in the last digits. And `<#>` returns **−8**, the inner
product with its sign flipped, so that sorting from smallest to largest puts the best match first.
Forget the sign and a query that sorts the other way returns the worst article in the table.
Lesson 14 writes these operators into real queries.

Other tools use other words for the same three. FAISS calls the dot product `IP` and has separate
index types for `L2`. Chroma and hnswlib name a collection's space `cosine`, `ip` or `l2` and
return a distance in every case, so a smaller number is a better match. Lesson 12 puts Chroma's
distances beside the cosines they came from. Before you sort a result or set a threshold on it, find out which
of the two kinds of number you are holding.
