---
title: Paying less for the part that never changes
version: 2
---

Most requests to a model start the same way: the same system prompt, the same instructions, the
same documents, and only the last few lines differ. A provider has to read that prefix every time.
**Prompt caching** lets it keep the work of reading it for a few minutes, and charges less for a
request that reuses it.

The way it is priced is the part to understand. In the sheet of lesson 2 section 04, Claude Sonnet
5.5 costs `$2` per million input tokens, `$2.50` to **write** a prefix into the cache and `$0.20`
to **read** it back. Writing costs more than not caching at all; reading costs a tenth. So a cache
pays off only when the same prefix is read again before it expires, which on Anthropic's API is
five minutes by default, renewed every time it is read.

## Marking the prefix

With Anthropic's API you mark the end of the part to cache with `cache_control`. Everything up to
and including that block becomes the cached prefix. `~/shop/scratch/cache.py` puts the whole
project, every file in git, into the system prompt, marks it, and asks two questions in a row. It
prints what `usage` says about each request, how long it took, and what its input would have
cost at Sonnet's prices with and without the cache:

```python
import subprocess
import time
from decimal import Decimal

import anthropic

# Claude Sonnet 5.5, dollars per million tokens, read on 2026-10-02.
BASE, READ = Decimal("2"), Decimal("0.20")
client = anthropic.Anthropic()
project = subprocess.run("git ls-files | xargs tail -n +1", shell=True,
                         capture_output=True, text=True).stdout
system = [{"type": "text", "text": "You review changes to this project.\n\n" + project,
           "cache_control": {"type": "ephemeral"}}]
for question in ["Explain the shop's shipping rule.", "Explain the shipping rule again, shorter."]:
    start = time.monotonic()
    r = client.messages.create(model="llama3.2:3b", max_tokens=300, system=system,
                               messages=[{"role": "user", "content": question}])
    u = r.usage
    read = u.cache_read_input_tokens or 0
    print(f"input {u.input_tokens:4}  cache read {read:4}  output {u.output_tokens:3}  "
          f"{time.monotonic() - start:4.1f} s")
    paid = (u.input_tokens * BASE + read * READ) / 1_000_000
    plain = (u.input_tokens + read) * BASE / 1_000_000
    print(f"    at Sonnet's prices: input ${paid:.6f}, against ${plain:.6f} with no cache")
```

```
ana@dev:~/shop$ python scratch/cache.py
input 1417  cache read    0  output 107  47.9 s
    at Sonnet's prices: input $0.002834, against $0.002834 with no cache
input   11  cache read 1407  output  59   8.9 s
    at Sonnet's prices: input $0.000303, against $0.002836 with no cache
```

`ollama stop` unloads the model first, which empties Ollama's cache, so the run starts the way it
would on your machine the first time. The first request read all 1,417 tokens of the project and
took 47.9 seconds, loading the model included. The second **read 1,407 of them from the cache**,
read only its own 11 new tokens, and took 8.9, most of it spent writing the 59 tokens of its
answer. Nothing was charged, since the model runs on your machine, so the saving you can see is
the wait. The price
line shows what the same `usage` would have cost at Anthropic: the cached tokens at a tenth.

**Ollama's cache is not Anthropic's, and the differences are worth knowing.** Ollama ignores
`cache_control`: it keeps the last request's prefix in memory whether you marked it or not, and
reuses whatever part of the next request starts the same way. It reports that part as
`cache_read_input_tokens`, which is why every program since lesson 1 adds it to `input_tokens`
to get the size of a request. And it never charges for writing, so `cache_creation_input_tokens`
comes back empty. Anthropic charges the write premium on the first request: 1,417 tokens at
`$2.50` rather than `$2`, about a quarter more than not caching at all, which only pays off if the
same prefix is read again before it expires. Real minimums depend on the model too: Anthropic does
not cache a prefix below a minimum size, 1,024 tokens on many of its models, and the provider's
documentation for the model you use is the source. OpenAI and Google discount a repeated prefix as well, and their
recent models do it without being asked; the `cache read` column of the price sheet is that
discount.

## Getting a cache to hit

- **Put what never changes first and what always changes last.** The cache matches from the start
  of the request, so a timestamp or a user's name at the top of the system prompt makes every
  request a new prefix and every request a cache write.
- **Order the stable parts by how stable they are**: instructions, then tool definitions, then
  documents, then the conversation, then the new question.
- **Check `cache_read_input_tokens` in the `usage` you log.** A cache that never reads is costing
  you the write premium on every request, and only that field will tell you.
