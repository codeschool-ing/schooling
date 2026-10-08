---
title: An exact cache
version: 2
---

An exact cache stores each answer under a key and serves it again when the same key comes back. The
whole design is the key, and the easy key, the question's text, is wrong twice over:

```schooling-example
{
  "language": "python",
  "file": "exact.py",
  "parts": [
    {
      "code": "import hashlib\nimport json\nimport re\n\nfrom search import conn\n\ncosts = json.load(open(\"costs.json\"))\nLOG = [json.loads(line) for line in open(\"data/querylog.jsonl\")]",
      "note": "The costs priced above and the log."
    },
    {
      "code": "def version():\n    \"\"\"The index the answers came from: a hash of every chunk id, which changes when any chunk does.\"\"\"\n    ids = [i for (i,) in conn.execute(\"SELECT id FROM chunks ORDER BY id\")]\n    return hashlib.sha256(\"\\n\".join(ids).encode()).hexdigest()[:12]",
      "note": "The index version: a hash of every chunk id. Lesson 5's ids change when a chunk's text changes, so any edit, addition or deletion gives a new version."
    },
    {
      "code": "def key(question, audiences, index):\n    \"\"\"Same words, same reader's permissions, same index: only then is an answer the same answer.\"\"\"\n    words = re.sub(r\"[^a-z0-9 ]\", \"\", question.lower()).split()\n    return (\" \".join(words), \",\".join(sorted(audiences)), index)",
      "note": "The key: the question with case and punctuation removed, the audiences the reader may see, and the index version. Two readers with different permissions never share an answer, and an answer never outlives the documents it came from."
    },
    {
      "code": "if __name__ == \"__main__\":\n    index = version()\n    cache, calls, saved = set(), 0, 0\n    for q in LOG:\n        k = key(q[\"text\"], [\"public\"], index)\n        c = costs[q[\"text\"]]\n        if k in cache:\n            saved += c[\"input\"] + c[\"output\"]\n        else:\n            cache.add(k)\n            calls += bool(c[\"input\"])\n    print(f\"index version {index}\")\n    print(f\"{len(cache)} keys, {len(LOG) - len(cache)} hits of {len(LOG)} ({(len(LOG) - len(cache)) / len(LOG):.0%}), \"\n          f\"{calls} model calls, {saved} tokens not spent\")",
      "note": "The week replayed through the cache: a key seen before is a hit, and the tokens it would have cost are counted as not spent."
    }
  ]
}
```

The key has three parts, and each one closes a hole that an earlier lesson found.

- **The question, normalised.** Lower case, punctuation removed, so "How many days...?" and "how many
  days..." are one entry. Nothing more aggressive: stemming or synonyms turn an exact cache into a fuzzy
  one without measuring it.
- **The reader's audiences.** Lesson 14 gave the support agent documents a customer cannot see. A cache
  keyed on the question alone would hand the agent's answer, built from the handbook, to the next
  customer who typed the same words. Lesson 16 found the same hole from the other side, with a
  contaminated answer.
- **The index version.** An answer is true of the documents it came from. When those change, the
  section after next, every answer built on them has to stop being served.

```
ana@vm:~/rag$ python exact.py
index version 0acfdfa0d064
38 keys, 462 hits of 500 (92%), 35 model calls, 170175 tokens not spent
```

**462 of 500 questions were hits, and the week needed 35 model calls instead of 486**, with 170,175
tokens not spent. On this log the exact cache does almost all the work, for the reason the previous
section gave: the log repeats itself far more than a real one. On a real log the hit rate is lower and
the design is the same.

One more property makes this cache safe to add: **it can only return an answer the pipeline already
gave to the same question, for a reader with the same permissions, from the same documents.** Whatever
lesson 8's test said about that answer is still true of it. That is not so of the next cache.
