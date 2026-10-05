---
title: What reindexing costs
version: 1
---

Lesson 1 said that vectors from two models cannot be compared, and lesson 10 drew the migration
plan that follows from it. The consequence for the budget is blunt: **changing the model means
embedding every document again and building every index again**, and for a while keeping both.
Teams tend to price that as the token bill alone. It is three bills, and on short texts the token
bill is the smallest.

## The tokens

Prices in this course come from one place, LiteLLM's sheet at commit b9e71e990aed, which
`prices.py` reads; the providers' own pages were out of reach from the machine this was recorded on.

```
ana@lab:~/emb$ python3 prices.py
LiteLLM price sheet at commit b9e71e990aed, USD per million input tokens
model                          provider                      USD/MTok   batch  dims  max in
text-embedding-3-small         openai                           0.020   0.010  1536    8191
text-embedding-3-large         openai                           0.130   0.065  3072    8191
text-embedding-ada-002         openai                           0.100       -  1536    8191
gemini/gemini-embedding-001    gemini                           0.150       -  3072    2048
cohere/embed-v4.0              cohere                           0.120       -  1536  128000
embed-english-v3.0             cohere                           0.100       -     -     512
embed-multilingual-v3.0        cohere                           0.100       -     -     512
voyage/voyage-3.5              voyage                           0.060       -     -   32000
voyage/voyage-3.5-lite         voyage                           0.020       -     -   32000
mistral/mistral-embed          mistral                          0.100       -     -    8192
ana@lab:~/emb$ python3 prices.py --json > prices.json
```

The second command saves the same rows as JSON for a program to read. This one counts the tokens
in every text the lab has that is not a question, times the local model on them, and scales both
to a million:

```schooling-example
{
  "language": "python",
  "file": "reembed.py",
  "parts": [
    {
      "code": "import json\nimport time\nimport tiktoken\nfrom minilm import embed\n\nrows = lambda f: [json.loads(l) for l in open(f\"data/{f}.jsonl\")]\ntexts = ([h[\"title\"] + \". \" + h[\"body\"] for h in rows(\"help\")]\n         + [b[\"title\"] + \". \" + b[\"blurb\"] for b in rows(\"books\")]\n         + [t[\"text\"] for t in rows(\"tickets\")])\nenc = tiktoken.get_encoding(\"cl100k_base\")\ntokens = sum(len(enc.encode(t)) for t in texts)\nprint(f\"{len(texts)} texts, {tokens:,} tokens, {tokens / len(texts):.1f} per text\")",
      "note": "Every text in `data/` that is not a question, counted in cl100k_base tokens, the encoding OpenAI's text-embedding-3 models are billed in."
    },
    {
      "code": "t = time.perf_counter()\nembed(texts)\ntook = time.perf_counter() - t\nrate = len(texts) / took\nprint(f\"all-MiniLM-L6-v2 on one core: {took:.2f} s, {rate:.0f} texts per second\")",
      "note": "Embed them all once with the local model and time it. `minilm.py` runs on one thread, so this is one core's rate."
    },
    {
      "code": "N = 1_000_000\nper = tokens / len(texts)\nprint(f\"{N:,} texts like these = {N * per:,.0f} tokens\")\nprint(f\"  here, one core:  {N / rate / 3600:5.1f} hours\")\nfor p in json.load(open(\"prices.json\")):\n    if p[\"model\"].startswith((\"text-embedding-3\", \"gemini\", \"cohere\", \"voyage\")):\n        print(f\"  {p['model']:28} ${N * per / 1e6 * p['usd_per_mtok']:8.2f}\")",
      "note": "Scale to a million texts of the same average length: hours on this core, and dollars on each priced model in the sheet."
    }
  ]
}
```

```
ana@lab:~/emb$ python reembed.py
250 texts, 5,684 tokens, 22.7 per text
all-MiniLM-L6-v2 on one core: 2.48 s, 101 texts per second
1,000,000 texts like these = 22,736,000 tokens
  here, one core:    2.8 hours
  text-embedding-3-small       $    0.45
  text-embedding-3-large       $    2.96
  gemini/gemini-embedding-001  $    3.41
  cohere/embed-v4.0            $    2.73
  voyage/voyage-3.5            $    1.36
  voyage/voyage-3.5-lite       $    0.45
```

**A million texts like these cost $0.45 on text-embedding-3-small and $3.41 on
gemini-embedding-001.** These texts are short, 22.7 tokens on average, so the bill scales with your
own average length: chunks ten times longer cost ten times as much. Even so, the order of magnitude
is dollars per million, and **it is rarely the token bill that makes a migration expensive.**

The local model has no bill and a clock instead: 101 texts a second on one core, 2.8 hours for the
million. That is one core of this machine; more cores divide it, and longer texts multiply it.

## The index

The vectors then have to go into a new index, and an HNSW index is built one insertion at a time:

```python
import time
import hnswlib
import numpy as np
from synth import unit_vectors

for n in (5_000, 10_000, 20_000, 40_000):
    X = unit_vectors(n, 384, seed=n)
    t = time.perf_counter()
    h = hnswlib.Index(space="ip", dim=384)
    h.init_index(max_elements=n, M=16, ef_construction=64)
    h.add_items(X, np.arange(n))
    took = time.perf_counter() - t
    print(f"{n:>7,} vectors  {took:6.2f} s  {took / n * 1e6:6.1f} µs per vector")
```

```
ana@lab:~/emb$ nproc
4
ana@lab:~/emb$ python rebuild.py
  5,000 vectors    0.54 s   108.2 µs per vector
 10,000 vectors    1.08 s   107.6 µs per vector
 20,000 vectors    1.87 s    93.3 µs per vector
 40,000 vectors    4.76 s   119.0 µs per vector
```

Eight times the vectors took 4.76 s against 0.54 s, so **the build grows at least in proportion
to the count**, because each insertion searches a graph that is bigger than the last one did. The
per-vector column wanders from run to run on a machine doing other work, so read the totals. In
pgvector the same build on 20,000 rows took 7385.761 ms at 384 dimensions and 46553.018 ms at 1536
(section 03 of this lesson); dimension multiplies the cost of every comparison the build makes.

## Both at once

A migration that does not stop the search keeps the old vectors and their index serving while the
new ones are written and built, and only then moves the reads across. For that window **you store
both sets**: the old model's rows and index plus the new model's, at the new model's dimension.
Moving from 384 to 1536 dimensions in pgvector, with HNSW, takes a row from 1676 + 2048 bytes to
8371 + 8192, and during the move you hold the sum. Section 07 of this lesson prices exactly that
for a larger corpus.

So reindexing costs tokens or hours of a CPU, the time to build the new index, and a period of
double storage. Of the three, the last is the one to plan capacity for, because it arrives all at
once and has to fit beside a system that is still serving.
