---
title: Searching with ORDER BY
version: 1
---

A nearest-neighbour search in SQL is not a special command. It is an ordinary `ORDER BY` on a
distance, with a `LIMIT`: sort every row by how far its vector is from the question's, and keep the
first few. pgvector supplies the distance as an operator between two vectors, and everything else is
the SQL you already write.

## The search

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import sys\nimport psycopg\nfrom pgvector.psycopg import register_vector\nfrom minilm import embed\n\nq = embed(sys.argv[1])[0]",
      "note": "The question arrives as the first argument and is embedded by the same model as the articles."
    },
    {
      "code": "with psycopg.connect() as conn:\n    register_vector(conn)\n    rows = conn.execute(\n        \"SELECT id, title, embedding <=> %(q)s AS distance FROM articles\"\n        \" ORDER BY embedding <=> %(q)s LIMIT 3\", {\"q\": q}).fetchall()",
      "note": "One query does the search: order every row by its cosine distance to the question and keep three. `%(q)s` is a named parameter, so the vector is sent once and used twice."
    },
    {
      "code": "for id, title, distance in rows:\n    print(f\"{distance:.3f}  {1 - distance:.3f}  {id}  {title}\")",
      "note": "The distance, the similarity it stands for (one minus the distance), the id and the title."
    }
  ],
  "output": "ana@lab:~/emb$ python search.py \"how do I get my money back\"\n0.554  0.446  h18  Returning a gift\n0.562  0.438  h15  When your refund arrives\n0.601  0.399  h22  Charged twice for one order"
}
```

These are the scores lesson 1 printed for the same question, `0.446` for the gift article and
`0.438` for the refund article, now found among all 40 articles rather than six hand-picked ones.
Over the whole help centre a third article joins them: **Charged twice for one order**, at
`0.399`, which is about getting money back too. The program sends one vector and receives three
rows. The 40 article vectors never left the database.

## Three operators on the same rows

Lesson 2 met the three operators on two small vectors: `<->` for the L2 distance, `<=>` for the
cosine distance and `<#>` for the inner product with its sign flipped. Here they are on the three
rows the search just found, with the question's vector taken from the `queries` table:

```sql
SELECT a.id,
       a.embedding <-> q.embedding AS l2,
       a.embedding <=> q.embedding AS cosine_distance,
       a.embedding <#> q.embedding AS negative_inner_product
FROM articles a, queries q
WHERE q.id = 'q01'
ORDER BY a.embedding <=> q.embedding
LIMIT 3;
```

```
ana@lab:~/emb$ psql -f ops.sql
 id  |         l2         |  cosine_distance   | negative_inner_product 
-----+--------------------+--------------------+------------------------
 h18 |  1.053030789742982 | 0.5544369486309908 |   -0.44556307792663574
 h15 | 1.0605979050079148 | 0.5624339282512665 |    -0.4375660717487335
 h22 | 1.0960301201990503 | 0.6006410777950922 |    -0.3993588984012604
(3 rows)
```

**All three put the rows in the same order**, and for vectors of length 1 they always will, because
each is a function of the same cosine. The negative inner product is the cosine distance minus one,
so for h18 it is the similarity `search.py` printed, `0.446`, with its sign flipped. The L2 distance
is the square root of twice the cosine distance. Check the first row by hand and the last digits
disagree a little: `0.5544369486309908` minus one is not exactly `-0.44556307792663574`, because
pgvector adds up the products in single precision and the two operators finish the arithmetic
differently. Round for display, never for comparison.

The sign on `<#>` is the one that catches people. **Every operator returns a number where smaller
means closer**, because PostgreSQL's index scans walk an order upwards. So `ORDER BY embedding <#> q`
is right, and a similarity read back from it has to be negated. This course uses `<=>`, which turns
into a similarity with one subtraction.

## A join is a search for every row

Because the vectors sit in tables, a search can be part of a larger query. The `queries` table
holds the 24 test questions with their own vectors and the articles the course judged relevant, and
one statement can search the articles for every question and keep the misses:

```sql
SELECT q.id, q.text, top.id AS first, q.relevant
FROM queries q
CROSS JOIN LATERAL (
    SELECT a.id FROM articles a
    ORDER BY a.embedding <=> q.embedding
    LIMIT 1
) AS top
WHERE NOT top.id = ANY (q.relevant)
ORDER BY q.id;
```

```
ana@lab:~/emb$ psql -f recall.sql
 id  |             text              | first | relevant  
-----+-------------------------------+-------+-----------
 q01 | how do I get my money back    | h18   | {h15,h14}
 q08 | send books to another country | h16   | {h10}
 q17 | where is my parcel right now  | h09   | {h08}
 q19 | my order came in pieces       | h09   | {h13}
 q21 | discount for a classroom set  | h04   | {h05}
(5 rows)
```

`CROSS JOIN LATERAL` is what makes it work. A lateral subquery may refer to the row it is joined
to, so for each question `q` it runs the search with `q.embedding` and returns the nearest
article. The outer `WHERE` keeps the questions whose first article is not one of the relevant ones.

**Five rows came back, so 19 of the 24 questions put a relevant article first.** That is recall at
1, the measure lesson 3 built, computed here without a single vector leaving PostgreSQL. The misses
are worth reading: *my order came in pieces* found h09, the parcel that never arrived, instead of
h13, one order arriving in several parcels.

Nothing about the join is specific to vectors. The same `LATERAL` search can sit beside a join to
an orders table, a `WHERE` on a date or a `GROUP BY` on a category, and the planner handles all of
it in one statement. That is the argument this lesson's last section makes for keeping the vectors
where the rest of the data already is.
