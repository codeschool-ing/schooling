---
title: The first search
version: 1
---

Lesson 5 left a table of 137 chunks, each with a vector and the metadata of its document. Searching
it by meaning is one SQL statement, and `search.py` is the module that holds that statement and the
three other ways of searching this lesson adds:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import re\n\nimport minilm\nimport numpy as np\nimport psycopg\nfrom minilm import embed\nfrom pgvector.psycopg import register_vector\nfrom rank_bm25 import BM25Okapi\n\nconn = psycopg.connect(autocommit=True)\nregister_vector(conn)",
      "note": "One connection for the whole module, with pgvector's types registered on it, and rank_bm25 for the lexical search."
    },
    {
      "code": "def rows(where=\"TRUE\", params=()):\n    return conn.execute(f\"SELECT id, path, text FROM chunks WHERE {where} ORDER BY id\", params).fetchall()",
      "note": "Every chunk the condition allows, for the methods that score in Python rather than in the database."
    },
    {
      "code": "def vector(question, k=3, where=\"TRUE\", params=()):\n    \"\"\"The K chunks nearest the question, by cosine similarity, among those WHERE allows.\"\"\"\n    q = embed(question)[0]\n    return conn.execute(\n        f\"SELECT id, path, text, 1 - (embedding <=> %s) FROM chunks WHERE {where}\"\n        \" ORDER BY embedding <=> %s LIMIT %s\", (q, *params, q, k)).fetchall()",
      "note": "The question is embedded with the same MiniLM that `lab-minilm` serves, and PostgreSQL orders the chunks by cosine distance, `<=>`. `1 -` turns the distance back into a similarity. The `WHERE` is the hook for this lesson's filters."
    }
  ]
}
```

`show.py` runs one of the module's methods and prints the five best chunks, their scores, their paths
and the first words of their text:

```
ana@lab:~/rag$ python show.py vector "How much is express delivery?"
1    0.658  Shipping and delivery > Delivery options and costs  | The threshold of 40 is the value of the books in
2    0.612  Shipping and delivery > Delivery options and costs  | | option | time | cost | | --- | --- | --- | | s
3    0.504  Shipping and delivery > Delivery options and costs  | Express orders placed after 2 pm, or on a Saturd
4    0.499  Shipping and delivery > Addresses  | Express delivery is not available to post office
5    0.492  Shipping and delivery > Parcels that are late or lost  | A standard parcel whose tracking has not changed
```

**The first three results are all from *Delivery options and costs*,** and the second is the table
with the price in it. Compare lesson 1, where sections cut at headings and embedded without their
paths put the right section first and the reply still missed the number: here the table is its own
chunk, and its path tells the embedding what it is about.

## What the numbers mean

The score is cosine similarity between the question's vector and the chunk's, from 1 for identical
direction downwards. It is a ranking signal and nothing more. 0.658 is not "66% relevant"; it is
larger than 0.612, which is all a search may conclude from it. Scores from different questions are not
comparable either, because a question with common words lands nearer everything than one with rare
ones. The last section of this lesson tries to turn the score into a decision anyway, and shows how
far that goes.

## What this search is good and bad at

`measure.py`, run in the section on hybrid search, scores this search on the 26 answerable questions of
lesson 4's test set: the chunk with the answer is first for 19 of them and in the top three for all
26. That is the path from lesson 5 paying off. On paraphrased questions, the customer's words against
the policy's, a dense vector search is very hard to beat.

It has a known blind spot, which lesson 2 found: **a word that is an identifier rather than a
meaning.** Error codes, clause numbers, product codes and version strings carry almost no meaning an
embedding model learnt, so two of them that differ in one character look alike. The next section
measures that and adds the search that does not have the blind spot.
