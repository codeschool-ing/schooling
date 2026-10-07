---
title: A cache you have to check
version: 1
---

Lesson 6 section 05 read what prompt caching costs: writing a cached prefix costs a quarter more
than ordinary input, reading it back a tenth, and below a minimum length nothing is cached. This
is how a request asks for it, and how to tell whether it got it. The documentation is direct about
the second part:

```
# https://platform.claude.com/docs/en/build-with-claude/prompt-caching, read 2026-10-07
 792: Shorter prompts cannot be cached, even if marked with
 794: . Any requests to cache fewer than this number of tokens will be processed without
      caching, and no error is returned. To verify whether a prompt was cached, check the
```

A request marks the end of the prefix it wants cached with `cache_control` on a block. `cache.py`
sends ana's triage prompt marked that way, then the same prompt with thirty-nine worked examples
added, twice. Ollama keeps what the model last read in memory, so the run starts by unloading the
model, which empties it:

```python
import json

import anthropic

client = anthropic.Anthropic()
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]
examples = "".join(f"E-mail: {c['text']}\nLabel: {c['label']}\n\n" for c in cases[:39])


def sort(system, label):
    r = client.messages.create(
        model="llama3.2:3b", max_tokens=16,
        system=[{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": cases[39]["text"]}])
    u = r.usage
    print(f"{label:22} written {u.cache_creation_input_tokens!s:>4}  read {u.cache_read_input_tokens!s:>4}  "
          f"uncached {u.input_tokens:3}  -> {r.content[0].text}")


sort(prompt, "prompt alone")
sort(prompt + "\nExamples:\n\n" + examples, "with 39 examples")
sort(prompt + "\nExamples:\n\n" + examples, "the same, again")
```

```
ana@desk:~/desk$ ollama stop llama3.2:3b
ana@desk:~/desk$ python cache.py
prompt alone           written None  read    0  uncached  82  -> order-status
with 39 examples       written None  read   50  uncached 1117  -> Label: order-status
the same, again        written None  read 1166  uncached   1  -> Label: order-status
```

Leave out the `ollama stop` and the first line changes, because the run starts with the model's
memory already full. Three lines, and next to each, what Anthropic documents for the same requests
to Sonnet 4.5, whose minimum is 1,024 tokens:

- **The prompt alone**, 82 tokens, read nothing from the cache. Anthropic would also cache nothing,
  because 82 is under the minimum, and the request would succeed at the ordinary input price. That
  is the silent case the documentation warns about.
- **With the examples**, Ollama read 50 tokens from the cache: the start of the triage prompt, which
  the first request had left in memory. Ollama has no minimum. Anthropic would read nothing here,
  because the 50 tokens were never a cached prefix, and would **write** the new 1,100-odd tokens at
  the write price. Ollama has no write price either: `written` is `None` on every line.
- **The same again**, and 1,166 of 1,167 tokens came from the cache. Anthropic would also read the
  prefix back, at a tenth of the input price, for five minutes after the last use.

So the same program, with the same mark, gets two different caches. **Ollama reuses whatever
prefix it still holds**, with or without `cache_control`, and only reports reads. **Anthropic
caches what the request marks, above a minimum, and bills the write.** The number to check is the
same in both: `cache_read_input_tokens`. Note also what `input_tokens` means: only the tokens that
were **not** read from the cache, which is why section 02's `in` column moved between runs.
The total the model read is the numbers added up, and a cost report that used `input_tokens` alone
would undercount every cached request.

What it is worth at Sonnet 4.5's prices, for input:

```
ana@desk:~/desk$ python sheet.py show claude-sonnet-4-5 | grep -E "^(input_cost_per_token|cache_creation_input_token_cost|cache_read_input_token_cost|prompt_cache_min_tokens) "
cache_creation_input_token_cost            3.75e-06
cache_read_input_token_cost                3e-07
input_cost_per_token                       3e-06
prompt_cache_min_tokens                    1024
```

```
ana@desk:~/desk$ python -c "print(f\"uncached {1167 * 3e-6 * 1000:.2f}  cached {(1166 * 3e-7 + 1 * 3e-6) * 1000:.2f}  dollars per 1,000 e-mails, input only\")"
uncached 3.50  cached 0.35  dollars per 1,000 e-mails, input only
```

That is Ollama's split priced at Sonnet 4.5's rates; Claude counts tokens with its own tokenizer,
so the numbers would differ and the ratio is what carries over. Ten times cheaper on input, for the
long prompt. Uncached, the examples make every request cost fourteen times what the bare prompt
costs, $3.50 per thousand e-mails against $0.25; cached, about one and a half times, $0.35.

Whether the examples make the *sorting* better is lesson 5's question, not the cache's, and this
run gives a hint: with them, the model copied their format and answered `Label: order-status`,
which lesson 5's scoring would count as a miss. **A cache makes a long prompt cheap; it does not
make it right.** And on Anthropic the five-minute life means a desk that receives an e-mail every
few minutes keeps the cache warm, while a quiet night lets it expire and pays for the write again
in the morning.
