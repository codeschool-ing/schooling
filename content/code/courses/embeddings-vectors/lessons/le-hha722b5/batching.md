---
title: Batching
version: 1
---

Embedding a help centre one article per request would be forty round trips, each paying the
network's delay and each counting against a rate limit. The endpoint takes a **list** as `input`,
and one request can carry many texts. The question is how many.

## The limits, as documented

OpenAI documents two limits for its embeddings endpoint: at most **2,048 inputs** in one request,
and at most **8,191 tokens** in any one input for the text-embedding-3 models. The price sheet this
course quotes lists the same 8,191 as the models' maximum input. labembed enforces the first and
not the second, so only the first is shown running below; the token limit is stated as documented,
not tried.

A token limit needs a token count, and OpenAI's models count with the `cl100k_base` encoding,
which the `tiktoken` library ships. Counting before sending tells you which texts are too long
for one input, and how much the request will cost:

```schooling-example
{
  "language": "python",
  "file": "batch.py",
  "parts": [
    {
      "code": "import json\nimport tiktoken\nfrom openai import OpenAI\n\nclient = OpenAI()\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]",
      "note": "The 40 help-centre articles, each as title and body, the same text lesson 3 searched."
    },
    {
      "code": "enc = tiktoken.get_encoding(\"cl100k_base\")\ncounts = [len(enc.encode(t)) for t in texts]\nprint(\"cl100k_base tokens:\", sum(counts), \" longest article:\", max(counts))",
      "note": "Count the tokens the way OpenAI's text-embedding-3 models do, with tiktoken's `cl100k_base` encoding."
    },
    {
      "code": "def embed_all(texts, size=16):\n    vectors = []\n    for start in range(0, len(texts), size):\n        r = client.embeddings.create(model=\"lab-minilm\", input=texts[start:start + size])\n        vectors += [d.embedding for d in sorted(r.data, key=lambda d: d.index)]\n    return vectors",
      "note": "Send the texts in slices of 16, and put each slice's vectors back in the order of its `index` before adding them to the list."
    },
    {
      "code": "vectors = embed_all(texts)\nprint(len(vectors), \"vectors from\", len(texts), \"articles\")",
      "note": "Forty texts in slices of 16 is three requests."
    }
  ]
}
```

```
ana@lab:~/emb$ python batch.py
cl100k_base tokens: 2205  longest article: 75
40 vectors from 40 articles
ana@lab:~/emb$ jq -c '{inputs, tokens, encoding_format}' /var/log/labembed/requests.jsonl | tail -n 3
{"inputs":16,"tokens":884,"encoding_format":"base64"}
{"inputs":16,"tokens":858,"encoding_format":"base64"}
{"inputs":8,"tokens":554,"encoding_format":"base64"}
```

The longest article is far below 8,191 tokens, so every article fits whole in one input. Lesson 3
cut a long text into chunks for search quality; a text over the token limit has to be cut for a
simpler reason, because the API refuses it.

The log shows the three requests: 16 texts, 16, then the last 8. Its `tokens` column is
labembed's count, made with **the lab model's own tokeniser**, so it does not add up to the
`cl100k_base` total above. That difference is real and worth keeping: the number a provider bills
is counted with the provider's tokeniser, so estimate a bill with the provider's counter, and
check it afterwards against `usage`.

## Two refusals worth knowing

```python
import openai
from openai import OpenAI

client = OpenAI()
tries = [
    ("an empty string", ["Tracking a parcel", ""]),
    ("2,049 inputs", ["Tracking a parcel"] * 2049),
]
for name, batch in tries:
    try:
        client.embeddings.create(model="lab-minilm", input=batch)
    except openai.BadRequestError as e:
        print(f"{name}: {e.status_code} {e.body['message']}")
```

```
ana@lab:~/emb$ python limits.py
an empty string: 400 'input' cannot contain an empty string.
2,049 inputs: 400 'input' must have at most 2048 items, got 2049.
```

**An empty string fails the whole batch**, not just its own slot. In a pipeline that embeds
whatever a database returns, one blank row is enough to lose the other 2,047 texts in the request,
so filter empty texts out before sending. And a list longer than the limit is refused outright
rather than cut down; the slicing in `embed_all` is the fix.

## Choosing the slice size

This lesson uses sixteen so that the help centre needs more than one request. In practice three
things bound the slice: the 2,048-input limit, the tokens in the request, and how much work you are
willing to repeat when one request fails. The tokens count because rate limits are measured in
tokens per minute as well as in requests. Whatever the size, keep the sort by `index` inside the
loop, where each slice's own positions still mean something.
