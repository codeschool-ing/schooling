---
title: Testing the boundary
version: 2
---

A permission that is not tested is a permission that worked on the day it was written. The test for
this one is simple to state: **for every role, for every question we have, no returned row may come
from an audience the role cannot read**. `audit.py` runs it over the 36 questions of `eval.jsonl` and
`identifiers.jsonl`, five rows per question, for each of the five roles:

```schooling-example
{
  "language": "python",
  "file": "audit.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nimport access\nfrom vectors import embed\nfrom search import conn as loader\n\n\ndef careless(conn, role, question, k):\n    \"\"\"A search written without the role, through a connection the policy does not limit.\"\"\"\n    q = embed(question)[0]\n    return loader.execute(\"SELECT id, path, text, audience, 1 - (embedding <=> %s) FROM chunks\"\n                          \" ORDER BY embedding <=> %s LIMIT %s\", (q, q, k)).fetchall()\n\n\nsearch = careless if \"--careless\" in sys.argv else access.search\nassistant = access.connect()\nquestions = [q[\"question\"] for q in map(json.loads, open(\"data/eval.jsonl\"))]\nquestions += [q[\"question\"] for q in map(json.loads, open(\"data/identifiers.jsonl\"))]\nleaks, seen = 0, 0\nfor role in access.ROLES:\n    for question in questions:\n        for row in search(assistant, role, question, 5):\n            seen += 1\n            leaks += row[3] not in access.audiences(role)\nprint(f\"{len(access.ROLES)} roles x {len(questions)} questions, {seen} rows returned, {leaks} outside the role\")",
      "note": "Every role asks every question of both test sets, and every row returned is checked against what the role may read; `--careless` runs the same audit against a search written without the role, through the loader's connection."
    }
  ]
}
```

```
ana@vm:~/rag$ python audit.py
5 roles x 36 questions, 900 rows returned, 0 outside the role
ana@vm:~/rag$ python audit.py --careless
5 roles x 36 questions, 900 rows returned, 210 outside the role
```

**900 rows, none outside its role.** The second line is the same test run against a search written
without the role, through a connection the policy does not limit, and it finds **210** rows a reader
should not have seen. That run is not decoration: a test that has never been seen to fail could be
passing because it checks nothing. Running it once against a broken search proves it can tell the
difference.

What this test covers and what it does not:

- **It covers the code path.** A role added to `ROLES` with the wrong audiences, a new feature that
  calls a search other than `access.search`, a change to the `WHERE`: each makes it fail.
- **It covers the questions it has.** Thirty-six questions reach the documents they reach. A probe
  set written for permissions adds questions aimed at each restricted document, like the refund flag
  and the fraud threshold, so that every restricted chunk is the best match for at least one probe.
- **It does not test the policy**, because `access.search` filters in the `WHERE` before the policy
  is ever needed. The policy has its own test, the assistant counting rows with nothing set and with
  each audience set, as in the section on the database. Each layer is tested alone, or a break in one
  is hidden by the other.

Run in CI on every change to the code, the roles or the corpus. A new document with the wrong
`audience:` line is a leak that ships with the next index rebuild, and only a test over the indexed
data sees it.
