---
title: The first search
version: 2
---

Lesson 5 left a table of 137 chunks, each with a vector and the metadata of its document, and then
changed three documents on purpose to show what an update does. Put them back before searching: the
script of lesson 1 writes the documents again, and an index rebuilt from nothing matches them.

```
ana@vm:~/rag$ sh docs.sh
ana@vm:~/rag$ psql -qc "DROP TABLE chunks"
ana@vm:~/rag$ python ingest.py
chunks: 137  embedded: 137  removed: 0  kept: 0
```

That is the table every search in this lesson reads. Searching
it by meaning is one SQL statement, and `search.py` is the module that holds that statement and the
three other ways of searching this lesson adds. Save the whole module now; the sections that follow
take its functions apart one at a time:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import re\n\nimport numpy as np\nimport psycopg\nfrom openai import OpenAI\nfrom pgvector.psycopg import register_vector\nfrom rank_bm25 import BM25Okapi\nfrom vectors import embed\n\nclient = OpenAI()\n\nconn = psycopg.connect(autocommit=True)\nregister_vector(conn)",
      "note": "One connection for the whole module, with pgvector's types registered on it, rank_bm25 for the lexical search, and a client for the model, which the reranker uses."
    },
    {
      "code": "def rows(where=\"TRUE\", params=()):\n    return conn.execute(f\"SELECT id, path, text FROM chunks WHERE {where} ORDER BY id\", params).fetchall()",
      "note": "Every chunk the condition allows, for the methods that score in Python rather than in the database."
    },
    {
      "code": "def vector(question, k=3, where=\"TRUE\", params=()):\n    \"\"\"The K chunks nearest the question, by cosine similarity, among those WHERE allows.\"\"\"\n    q = embed(question)[0]\n    return conn.execute(\n        f\"SELECT id, path, text, 1 - (embedding <=> %s) FROM chunks WHERE {where}\"\n        \" ORDER BY embedding <=> %s LIMIT %s\", (q, *params, q, k)).fetchall()",
      "note": "The question is embedded with the same all-minilm the chunks were embedded with, and PostgreSQL orders the chunks by cosine distance, `<=>`. `1 -` turns the distance back into a similarity. The `WHERE` is the hook for this lesson's filters."
    },
    {
      "code": "TOKEN = re.compile(r\"[a-z0-9]+(?:[-.%][a-z0-9]+)*%?\")\n\n\ndef words(text):\n    return TOKEN.findall(text.lower())",
      "note": "Words are runs of letters and digits, kept whole across a hyphen, a dot or a percent sign, so that `E-4104`, `9.90` and `12%` are one word each. Lowercase, because `Express` and `express` are the same word to a reader."
    },
    {
      "code": "def lexical(question, k=3, where=\"TRUE\", params=()):\n    \"\"\"The K chunks BM25 scores highest for the question's words.\"\"\"\n    found = rows(where, params)\n    bm25 = BM25Okapi([words(path + \" \" + text) for _, path, text in found])\n    scores = bm25.get_scores(words(question))\n    return [(*found[i], float(scores[i])) for i in np.argsort(-scores, kind=\"stable\")[:k]]",
      "note": "BM25 over the path and text of every chunk. It is rebuilt on each call, which is fine for 137 chunks and is what a search engine's inverted index does once and keeps."
    },
    {
      "code": "def hybrid(question, k=3, depth=20, where=\"TRUE\", params=()):\n    \"\"\"Reciprocal rank fusion of the two lists, each DEPTH long.\"\"\"\n    fused = {}\n    for ranking in (vector(question, depth, where, params), lexical(question, depth, where, params)):\n        for rank, row in enumerate(ranking, 1):\n            fused.setdefault(row[0], [row[:3], 0.0])[1] += 1 / (60 + rank)\n    best = sorted(fused.values(), key=lambda item: -item[1])[:k]\n    return [(*row, score) for row, score in best]",
      "note": "Each list contributes 1/(60 + rank) for every chunk it holds, and a chunk in both lists gets both. The scores of the two methods are never compared, only their ranks, which is what lets a cosine and a BM25 score be combined at all."
    },
    {
      "code": "JUDGE = \"\"\"Question: {question}\n\nPassage:\n{passage}\n\nHow well does the passage answer the question? Reply with one whole number from 0 (not at all) to 10 (completely), and nothing else.\"\"\"",
      "note": "The instruction, the same for every candidate. The question comes first, so that the twenty requests for one question share the start of their prompt."
    },
    {
      "code": "def rerank(question, candidates, k=3):\n    \"\"\"The generator reads the question with each candidate and gives it a mark; the marks decide the order.\"\"\"\n    scores = []\n    for _, path, text, _ in candidates:\n        reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, max_tokens=4, messages=[\n            {\"role\": \"user\", \"content\": JUDGE.format(question=question, passage=path + \"\\n\" + text)}])\n        found = re.search(r\"\\d+\", reply.choices[0].message.content)\n        scores.append(int(found.group()) if found else 0)\n    order = np.argsort(-np.array(scores), kind=\"stable\")[:k]\n    return [(*candidates[i][:3], scores[i]) for i in order]",
      "note": "One call per candidate, four tokens at most for the reply, and a reply with no number counts as 0. The sort is stable, so candidates with the same mark keep the order the first search gave them, which with marks from 0 to 10 happens often."
    }
  ]
}
```

`show.py` runs one of the module's methods and prints the five best chunks, their scores, their paths
and the first words of their text:

```schooling-example
{
  "language": "python",
  "file": "show.py",
  "parts": [
    {
      "code": "import sys\n\nimport search\n\nmethod, question = sys.argv[1], sys.argv[2]\nfor rank, (id, path, text, score) in enumerate(getattr(search, method)(question, 5), 1):\n    print(f\"{rank}  {score:7.3f}  {path}  | {' '.join(text.split())[:48]}\")",
      "note": "The method is named on the command line, so the same program shows every search in this lesson."
    }
  ]
}
```

```
ana@vm:~/rag$ python show.py vector "How much is express delivery?"
1    0.658  Shipping and delivery > Delivery options and costs  | The threshold of 40 is the value of the books in
2    0.612  Shipping and delivery > Delivery options and costs  | | option | time | cost | | --- | --- | --- | | s
3    0.504  Shipping and delivery > Delivery options and costs  | Express orders placed after 2 pm, or on a Saturd
4    0.499  Shipping and delivery > Addresses  | Express delivery is not available to post office
5    0.492  Shipping and delivery > Parcels that are late or lost  | A standard parcel whose tracking has not changed
```

**The first three results are all from *Delivery options and costs*,** and the second is the table
with the price in it. In lesson 1 the price sat somewhere inside a whole section cut at its heading;
here the table is a chunk of its own, and its path tells the embedding what it is about.

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
