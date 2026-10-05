---
title: Cohere's four input types
version: 1
---

`input_type` is Cohere's version of Google's task type, with four values for text instead of eight.
The SDK accepts a fifth, `image`, for embedding pictures, which this course does not do. The idea
is the same one the task-type section drew: a model trained asymmetrically embeds a text according
to its role, so the role has to travel with the text.

| `input_type` | the text is | Google's nearest task type |
|---|---|---|
| `search_document` | something stored to be found: an article, a chunk | `RETRIEVAL_DOCUMENT` |
| `search_query` | the question a search is run for | `RETRIEVAL_QUERY` |
| `classification` | an input to a classifier, as the tickets in lesson 4 | `CLASSIFICATION` |
| `clustering` | one of many texts to be grouped without labels | `CLUSTERING` |

**The first two are a pair and the other two are not.** A search indexes with `search_document` and
asks with `search_query`, and the two must never be swapped. `classification` and `clustering` are
symmetric: every ticket is the same kind of text, so all of them get the same type, the training
set and the new ticket alike. Lesson 10 meets Jina's version of the same list, under the parameter
name `task`.

## A search, written the way it should be

Here is the help centre's search through Cohere's SDK: the articles as `search_document`, the 24
customer questions as `search_query`, and the measure lesson 3 builds, which counts a question as
answered when one of its relevant articles is ranked first, or among the first three. The last
two lines send the questions with the wrong type on purpose:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nimport cohere\n\nco = cohere.ClientV2(api_key=os.environ[\"CO_API_KEY\"], base_url=os.environ[\"CO_API_URL\"])\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]",
      "note": "A client, the articles, the questions with their relevant articles, and the ids in file order."
    },
    {
      "code": "def embed(texts, input_type):\n    r = co.embed(model=\"lab-minilm\", texts=texts, input_type=input_type,\n                 embedding_types=[\"float\"])\n    return np.array(r.embeddings.float_, dtype=np.float32)",
      "note": "Embed a list of texts with one input type, as float vectors in a NumPy array."
    },
    {
      "code": "def found(D, Q, k):\n    hits = 0\n    for q, row in zip(queries, Q @ D.T):\n        top = [ids[j] for j in np.argsort(-row)[:k]]\n        hits += any(t in q[\"relevant\"] for t in top)\n    return hits",
      "note": "How many of the 24 questions have a relevant article among the first `k` results."
    },
    {
      "code": "D = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help], \"search_document\")\nfor qtype in [\"search_query\", \"search_document\", \"clustering\"]:\n    Q = embed([q[\"text\"] for q in queries], qtype)\n    print(f\"queries as {qtype:16} top 1: {found(D, Q, 1)}/24  top 3: {found(D, Q, 3)}/24\")",
      "note": "The articles once, as documents. The questions three times: with the right type, then as documents, then as texts to cluster."
    }
  ],
  "output": "ana@lab:~/emb$ python search.py\nqueries as search_query     top 1: 19/24  top 3: 22/24\nqueries as search_document  top 1: 19/24  top 3: 22/24\nqueries as clustering       top 1: 19/24  top 3: 22/24"
}
```

**All three lines are the same, 19 at rank 1 and 22 in the top 3.** labembed embeds every question the same
way whatever type it arrives with, so the three runs compared the same vectors. That is the expected result in this lab and the one to distrust everywhere else. Against an
asymmetric model the first line is the one it was trained for and the other two are not, and a
careless pipeline that indexes and asks with the same type is wrong in a way no error reports.

This is also how you find out whether the type matters for a model you are choosing. Run the same
measurement with the right pair and with a wrong one, on your own questions. If the two lines
differ, the model is asymmetric and the type is doing work; if they agree, as here, it is not.
Either way the code keeps the right pair, because the next model may be the other kind.

## Keep the type with the vector

A vector stored without its type is a vector somebody will one day compare with the wrong kind.
Lesson 11 gives every stored vector a record with metadata beside it, and that is where these go:
**the model, the input type or task type, and the dimension setting** when the provider has one. Three fields are cheap. Re-embedding a collection because nobody can tell how it
was made is not.
