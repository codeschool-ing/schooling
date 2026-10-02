---
title: Paying less for the part that never changes
version: 1
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
and including that block becomes the cached prefix. `lab/cache.py` puts the whole project, every
file in git, into the system prompt, and asks two questions in a row:

```python
import subprocess
from decimal import Decimal

import anthropic

# Claude Sonnet 5.5, dollars per million tokens, read on 2026-10-02 (prices.py).
BASE, WRITE, READ = Decimal("2"), Decimal("2.50"), Decimal("0.20")
client = anthropic.Anthropic()
project = subprocess.run("git ls-files | xargs tail -n +1", shell=True,
                         capture_output=True, text=True).stdout
system = [{"type": "text", "text": "You review changes to this project.\n\n" + project,
           "cache_control": {"type": "ephemeral"}}]
for question in ["Explain the shop's shipping rule.", "Explain the shipping rule again, shorter."]:
    r = client.messages.create(model="scripted-1", max_tokens=300, system=system,
                               messages=[{"role": "user", "content": question}])
    u = r.usage
    print(f"input {u.input_tokens:4}  cache write {u.cache_creation_input_tokens:4}  "
          f"cache read {u.cache_read_input_tokens:4}  output {u.output_tokens}")
    paid = (u.input_tokens * BASE + u.cache_creation_input_tokens * WRITE
            + u.cache_read_input_tokens * READ) / 1_000_000
    plain = (u.input_tokens + u.cache_creation_input_tokens + u.cache_read_input_tokens) * BASE / 1_000_000
    print(f"    input cost ${paid:.6f}, against ${plain:.6f} with no cache")
```

```
ana@dev:~/shop$ python lab/cache.py
input    8  cache write 1398  cache read    0  output 147
    input cost $0.003511, against $0.002812 with no cache
input    9  cache write    0  cache read 1398  output 147
    input cost $0.000298, against $0.002814 with no cache
```

The first request **wrote** 1,398 tokens to the cache and paid more for them than it would have
paid without caching: $0.003511 against $0.002812. The second **read** the same 1,398 tokens back
and paid $0.000298 for its input instead of $0.002814, about a tenth. `input_tokens` is now
only the part after the cached prefix, the question itself.

**labllm's rules here are its own**, written to behave like Anthropic's: a prefix shorter than
1,024 tokens is not cached, and an entry lives five minutes from its last use. Real minimums
depend on the model, and the provider's documentation for the model you use is the source.
OpenAI and Google discount a repeated prefix too, and their recent models do it without being
asked; the `cache read` column of the price sheet is that discount.

## Getting a cache to hit

- **Put what never changes first and what always changes last.** The cache matches from the start
  of the request, so a timestamp or a user's name at the top of the system prompt makes every
  request a new prefix and every request a cache write.
- **Order the stable parts by how stable they are**: instructions, then tool definitions, then
  documents, then the conversation, then the new question.
- **Check `cache_read_input_tokens` in the `usage` you log.** A cache that never reads is costing
  you the write premium on every request, and only that field will tell you.
