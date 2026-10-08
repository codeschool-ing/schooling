---
title: Calling the embedding provider
version: 2
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
      "code": "import hashlib\n\nimport psycopg\nimport tiktoken\nfrom chunking import load, structured\nfrom openai import OpenAI\nfrom pgvector.psycopg import register_vector\n\nMODEL = \"all-minilm\"\nSIZE = 60\nenc = tiktoken.get_encoding(\"cl100k_base\")\nclient = OpenAI(max_retries=5)",
      "note": "The OpenAI SDK, pointed at Ollama by `OPENAI_BASE_URL`. `max_retries=5` lets the SDK retry a refused request up to five times before giving up. `SIZE` is the 60 words the previous section chose."
    },
    {
      "code": "def embed(texts, batch=32):\n    vectors = []\n    for i in range(0, len(texts), batch):\n        reply = client.embeddings.create(model=MODEL, input=texts[i:i + batch])\n        vectors += [d.embedding for d in reply.data]\n    return vectors",
      "note": "Thirty-two texts per request. Fewer requests means fewer round trips and fewer chances to hit a rate limit; every hosted provider caps how many inputs one request may carry."
    }
  ]
}
```

The SDK is the one `embeddings-vectors` lesson 7 used, `client.embeddings.create`, and the model is
`all-minilm` on Ollama. With a hosted provider, only the base URL, the key and the model name change.

The SDK can say what it sends. With `OPENAI_LOG=info` in the environment it writes one line for every
HTTP request, and counting those lines counts the requests.

## Batches

```
ana@vm:~/rag$ OPENAI_LOG=info python ingest.py 2>&1 | grep -c "HTTP Request"
5
ana@vm:~/rag$ psql -tc "SELECT count(*) FROM chunks"
   137
```

**137 chunks, five requests**: four of 32 and one of 9. Sending one chunk per request would have been
137 round trips, each paying the network's latency and each counting against the provider's limit on
requests per minute. Every provider caps how many inputs one request may carry, and some cap the
total tokens too, so the batch size is the largest that stays under both; 32 is comfortably under
every cap this course has met.

## Refusals

A hosted provider refuses requests when they arrive faster than the account's limit allows, with
HTTP 429, and indexing a large corpus is exactly the burst that triggers it. Ollama on your own
machine has no account and never answers 429. A server that does not answer at all exercises the
same code in the SDK, though, and that can be had on purpose: point the program at a port where
nothing listens.

```
ana@vm:~/rag$ psql -qc "DROP TABLE chunks"
ana@vm:~/rag$ OPENAI_BASE_URL=http://localhost:11435/v1 OPENAI_LOG=info python ingest.py 2>&1 | grep -E "Retrying|Error:"
[2026-10-07 21:07:06 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 0.395908 seconds
[2026-10-07 21:07:06 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 0.755487 seconds
[2026-10-07 21:07:07 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 1.818797 seconds
[2026-10-07 21:07:09 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 3.450217 seconds
[2026-10-07 21:07:12 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 7.545589 seconds
httpcore.ConnectError: [Errno 111] Connection refused
httpx.ConnectError: [Errno 111] Connection refused
openai.APIConnectionError: Connection error.
ana@vm:~/rag$ psql -tc "SELECT count(*) FROM chunks"
ERROR:  relation "chunks" does not exist
LINE 1: SELECT count(*) FROM chunks
                             ^
ana@vm:~/rag$ python ingest.py
chunks: 137  embedded: 137  removed: 0  kept: 0
```

**The SDK tried six times, waiting longer each time, and then gave up.** `max_retries=5` is five
retries after the first attempt, and the waits roughly double, from under half a second to about
seven, with some randomness so that many clients refused together do not all come back at the same
instant. A 429 from a provider is retried by exactly this loop, and a 429 that lasts longer than the
budget kills the run exactly like this. Nothing was written, because `ingest.py` writes inside one
transaction and the transaction never committed; the next run, pointed back at Ollama, starts from
nothing and finishes.

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
