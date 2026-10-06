---
title: Calling the embedding provider
version: 1
---

`ingest.py` is the program that turns the corpus into an index, and every later lesson searches what
it builds. Its first job is to get vectors from the embedding provider, and that is a network call
with everything a network call brings: limits on how much one request may carry, limits on how many
requests may be made, and refusals.

```schooling-example
{
  "language": "python",
  "file": "ingest.py",
  "parts": [
    {
      "code": "import hashlib\n\nimport psycopg\nimport tiktoken\nfrom chunking import load, structured\nfrom openai import OpenAI\nfrom pgvector.psycopg import register_vector\n\nMODEL = \"lab-minilm\"\nSIZE = 60\nenc = tiktoken.get_encoding(\"cl100k_base\")\nclient = OpenAI(max_retries=5)",
      "note": "The OpenAI SDK, pointed at labgen by `OPENAI_BASE_URL`, which passes embedding requests to labembed. `max_retries=5` lets the SDK retry a refused request up to five times before giving up. `SIZE` is the 60 words the previous section chose."
    },
    {
      "code": "def embed(texts, batch=32):\n    vectors = []\n    for i in range(0, len(texts), batch):\n        reply = client.embeddings.create(model=MODEL, input=texts[i:i + batch])\n        vectors += [d.embedding for d in reply.data]\n    return vectors",
      "note": "Thirty-two texts per request. Fewer requests means fewer round trips and fewer chances to hit a rate limit; every provider caps how many inputs one request may carry, and labembed's cap is 2,048."
    }
  ]
}
```

The SDK is the one `embeddings-vectors` lesson 7 used, `client.embeddings.create`, and the model is
the lab's `lab-minilm`. With a real provider, only the base URL, the key and the model name change.

## Batches

```
ana@lab:~/rag$ python ingest.py
chunks: 137  embedded: 137  removed: 0  kept: 0
ana@lab:~/rag$ wc -l < /var/log/labembed/requests.jsonl
5
```

**137 chunks, five requests**: four of 32 and one of 9. Sending one chunk per request would have been
137 round trips, each paying the network's latency and each counting against the provider's limit on
requests per minute. Every provider caps how many inputs one request may carry, and some cap the
total tokens too, so the batch size is the largest that stays under both; 32 is comfortably under
every cap this course has met.

## Refusals

A provider refuses requests when they arrive faster than the account's limit allows, with HTTP 429.
Indexing a large corpus is exactly the burst that triggers it. labembed can be told to refuse the
next requests on purpose, and `ingest.py` run again from an empty table shows what happens:

```
ana@lab:~/rag$ psql -qc "DROP TABLE chunks"
ana@lab:~/rag$ curl -s -X POST localhost:8500/lab/config -d "{\"fail\": 2, \"status\": 429}"; echo
{"fail": 2, "status": 429}
ana@lab:~/rag$ python ingest.py
chunks: 137  embedded: 137  removed: 0  kept: 0
ana@lab:~/rag$ python requests.py | tail -n 7
429  Rate limit reached for requests. Please try again in 1s.
429  Rate limit reached for requests. Please try again in 1s.
200 32 
200 32 
200 32 
200 32 
200 9 
```

**The first request was refused twice and succeeded on the third attempt, and the program never
knew.** The OpenAI SDK retries a 429 by itself, waiting a little longer each time, and `max_retries=5`
gave it room for five attempts. `requests.py` reads labembed's request log, one line per request
received, which is the only place the two refusals are visible.

Two things follow. **Set the retry budget deliberately**: the default of most SDKs is two retries,
which a long indexing run against a busy account can exhaust, and then the run dies halfway. And
**make the run safe to repeat**, because sooner or later one will die halfway anyway. The section on
ids shows that `ingest.py` is: a second run embeds only what the first did not finish.

## Cost

Embedding is billed per token of input. This corpus is 8,914 tokens by lesson 1's count, plus the
heading paths, and at the prices providers charge for embedding models it costs a fraction of a cent
to embed in full. That is why lesson 3 called re-indexing cheap. What is not cheap is re-embedding a
corpus of millions of chunks every night because nobody tracked which ones changed, and that is what
the ids in the next sections prevent.
