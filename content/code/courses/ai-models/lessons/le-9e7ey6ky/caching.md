---
title: A cache you have to check
version: 1
---

Lesson 6 section 05 read what prompt caching costs: writing a cached prefix costs a quarter more
than ordinary input, reading it back a tenth, and below a minimum length nothing is cached. This
is how a request asks for it, and how to tell whether it got it. The documentation is direct about
the second part:

```
ana@desk:~/desk$ sources quote claude-caching "Shorter prompts cannot be cached|processed without caching|To verify whether"
# https://platform.claude.com/docs/en/build-with-claude/prompt-caching, read 2026-10-05
 786: Shorter prompts cannot be cached, even if marked with
 788: . Any requests to cache fewer than this number of tokens will be processed without
      caching, and no error is returned. To verify whether a prompt was cached, check the
```

A request marks the end of the prefix it wants cached with `cache_control` on a block. `lab/cache.py`
sends ana's triage prompt marked that way, then the same prompt with thirty-nine worked examples
added, twice. The stand-in's minimum for `standin-large` is 1,024 tokens, the same as Sonnet 4.5's:

```python
import json

import anthropic

client = anthropic.Anthropic()
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]
examples = "".join(f"E-mail: {c['text']}\nLabel: {c['label']}\n\n" for c in cases[:39])


def sort(system, label):
    r = client.messages.create(
        model="standin-large", max_tokens=16,
        system=[{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": cases[39]["text"]}])
    u = r.usage
    print(f"{label:22} written {u.cache_creation_input_tokens:4}  read {u.cache_read_input_tokens:4}  "
          f"uncached {u.input_tokens:3}  -> {r.content[0].text}")


sort(prompt, "prompt alone")
sort(prompt + "\nExamples:\n\n" + examples, "with 39 examples")
sort(prompt + "\nExamples:\n\n" + examples, "the same, again")
```

```
ana@desk:~/desk$ python lab/cache.py
prompt alone           written    0  read    0  uncached  60  -> order-status
with 39 examples       written 1104  read    0  uncached  24  -> order-status
the same, again        written    0  read 1104  uncached  24  -> order-status
```

Three lines, three outcomes:

- **The prompt alone** was marked for caching and is 60 tokens long. Nothing was written and
  nothing read, the request succeeded, and the bill was ordinary input. This is the silent case.
- **With the examples** the prefix is 1,104 tokens, over the minimum, and it was **written**:
  1,104 tokens at the write price, plus 24 that come after the mark.
- **The same again**, within five minutes, and the 1,104 were **read** at a tenth of the price.

Note what `input_tokens` means here: only the tokens **after** the cached prefix. The total read
by the model is the three numbers added up, and a cost report that used `input_tokens` alone would
undercount every cached request.

What it is worth at Sonnet 4.5's prices, for input:

```
ana@desk:~/desk$ sheet show claude-sonnet-4-5 | grep -E "^(input_cost_per_token|cache_creation_input_token_cost|cache_read_input_token_cost|prompt_cache_min_tokens) "
cache_creation_input_token_cost            3.75e-06
cache_read_input_token_cost                3e-07
input_cost_per_token                       3e-06
prompt_cache_min_tokens                    1024
```

```
ana@desk:~/desk$ python -c "print(f\"uncached {1128 * 3e-6 * 1000:.2f}  cached {(1104 * 3e-7 + 24 * 3e-6) * 1000:.2f}  dollars per 1,000 e-mails, input only\")"
uncached 3.38  cached 0.40  dollars per 1,000 e-mails, input only
```

Eight times cheaper on input, for the long prompt. Uncached, the examples would make every request
cost nineteen times what the bare prompt costs, $3.38 per thousand e-mails against $0.18; cached,
about twice, $0.40. Whether the examples make the *sorting* better is lesson 5's question, not the
cache's: **a cache makes a long prompt cheap; it does not make it right.** And the five-minute life
means a desk that receives an e-mail every few minutes keeps the cache warm, while a quiet night
lets it expire and pays for the write again in the morning.
