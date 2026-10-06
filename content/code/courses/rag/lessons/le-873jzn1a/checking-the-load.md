---
title: Checking what was loaded
version: 1
---

An indexing run that finishes without an error has proved that it finished. It has not proved that the
index is right: a document can be missing, a vector can come from the wrong model, a chunk can be
three times the size the prompt budget assumed. Those failures are silent at indexing time and visible
only later, as answers that are slightly worse, which is the hardest kind of failure to trace back.

So the run ends with a check that **fails loudly**:

```schooling-example
{
  "language": "python",
  "file": "check_index.py",
  "parts": [
    {
      "code": "import sys\n\nimport psycopg\nfrom openai import OpenAI\nfrom pgvector.psycopg import register_vector",
      "note": "The check needs the database, the vector type and the embedding client."
    },
    {
      "code": "failures = []\nwith psycopg.connect() as conn:\n    register_vector(conn)\n    one = lambda sql: conn.execute(sql).fetchone()[0]\n    docs = one(\"SELECT count(DISTINCT doc_id) FROM chunks\")\n    if docs != 13:\n        failures.append(f\"{docs} documents in the index, expected 13\")\n    if one(\"SELECT count(*) FROM chunks WHERE vector_dims(embedding) <> 384\"):\n        failures.append(\"a vector with the wrong number of dimensions\")\n    if one(\"SELECT count(DISTINCT model) FROM chunks\") != 1:\n        failures.append(\"vectors from more than one model\")\n    if one(\"SELECT max(tokens) FROM chunks\") > 400:\n        failures.append(\"a chunk over 400 tokens\")",
      "note": "Four structural checks: every document present, every vector of the right size, one model for all of them, and no chunk bigger than the prompt budget assumes. Each failure is collected rather than raised, so one run reports all of them."
    },
    {
      "code": "    # A question whose answer is known: the chunk holding it must come first.\n    q = OpenAI().embeddings.create(model=\"lab-minilm\", input=[\"How long is a gift card valid?\"]).data[0].embedding\n    top = conn.execute(\"SELECT path FROM chunks ORDER BY embedding <=> %s::vector LIMIT 1\", (q,)).fetchone()[0]\n    if \"Validity\" not in top:\n        failures.append(f\"the gift card question found {top!r}\")",
      "note": "A known answer: the gift card question must find the *Validity* section first. It goes through the provider, the operator and the index, the same path a real question takes."
    },
    {
      "code": "print(\"\\n\".join(failures) or f\"ok: {docs} documents, every check passed\")\nsys.exit(1 if failures else 0)",
      "note": "Every failure printed, and a non-zero exit if there was any, so that whatever runs next can stop."
    }
  ]
}
```

Each test is something that has gone wrong in real pipelines. A document that failed to parse and was
skipped. A configuration that pointed half the run at another model. A chunker change that let one
chunk swallow a whole section. And the last test is the one worth copying everywhere: **a question
whose answer is known, run against the index, with the chunk that must come first named in advance.**
It exercises the whole path, the model, the vectors, the operator and the index, in one assertion.

## When it passes and when it fails

Run after the first load, it passes:

```
ana@lab:~/rag$ python check_index.py; echo "exit $?"
ok: 13 documents, every check passed
exit 0
```

Run at the end of this lesson, after the 2025 policy was deleted, it fails:

```
ana@lab:~/rag$ python check_index.py; echo "exit $?"
12 documents in the index, expected 13
exit 1
```

**That failure is correct.** The corpus now has twelve documents, and a check that expects thirteen
should say so; whether the deletion was intended is a person's decision, and the exit code is what
stops an automated deployment from making it silently. In a real pipeline the expected count comes
from the source of documents, not from a constant, and the check compares the two.

## Where it runs

The check belongs at the end of every indexing run, and a non-zero exit should stop whatever comes
next: the swap to a new index, the deployment, the announcement that the policy change is live. A
check that only prints is a check somebody reads on the day after the incident. Lesson 8 adds the
other half, a test of answers rather than of the index, and the two together are what lets a team
change the chunker or the model on a Tuesday afternoon without fear.
