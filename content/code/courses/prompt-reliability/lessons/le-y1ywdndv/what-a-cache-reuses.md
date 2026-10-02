---
title: What a cache reuses
version: 1
---

The word suggests the wrong thing. A prompt cache does not store answers, and it does not remember
an earlier conversation. **It stores the work of reading the beginning of a prompt**, so that the
next call starting with exactly the same tokens can skip that part and pay less for it. The answer
is still written fresh every time.

Most of a production prompt is the same on every call. The prompt this lesson uses is a long guide
to the categories followed by one customer's message, and only the message changes. A cache is a
way of not paying full price to read the guide a million times.

## The stand-in's cache

`promptlab/model.py` says in its opening comment what its cache does:

```
ana@lab:~/triage$ grep -n -A6 "It also keeps a prompt cache" promptlab/model.py
12:It also keeps a prompt cache when the prompt file says `cache: on`: the
13-longest run of whole BLOCK-token blocks it has seen before, from the start of
14-the prompt, is read from the cache instead of being processed again. Prompts
15-shorter than MINIMUM are never cached. Real providers do the same thing with
16-their own block size and minimum.
17-"""
18-
ana@lab:~/triage$ grep -n "^BLOCK\|^MINIMUM" promptlab/model.py
24:BLOCK = 32
25:MINIMUM = 64
```

So, in the stand-in:

- **The prompt is cut into whole blocks of 32 tokens**, from the start. A remainder shorter than a
  block is never cached.
- **A call reads from the cache the longest run of blocks, from the first, that an earlier call
  already had.** One block that differs ends the run, even if every block after it matches.
- **A prompt under 64 tokens is never cached** at all.
- The cache is on only when the prompt file says `cache: on` above its `---`, and it lasts for one
  `pl run`.

The minimum is easy to see. The bare prompt of lesson 1 is short, and turning the cache on for it
changes nothing:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --set cache=on --out runs/short.jsonl
40 calls, prompt a4ffc4b1, written to runs/short.jsonl
ana@lab:~/triage$ pl cost runs/short.jsonl | head -n 5
tokens          count   per call
input            1459       36.5
cache_read          0        0.0
cache_write         0        0.0
output            907       22.7
```

At 36.5 tokens a call, no prompt reached 64, so nothing was read or written. The `--set` here is
only to try it; lesson 14 says where a setting belongs once you mean it.

## Real caches

Real providers cache a prefix too, and **every detail that matters is theirs to set**: the size of
a block, the shortest prompt they will cache, how long an unused prefix is kept, and what reading
and writing cost. Some apply the cache automatically to any prompt long enough. OpenAI's prompt
caching documentation describes it that way. Others cache only where you mark the end of the
prefix: Anthropic's documentation has you put a `cache_control` marker in the request. None of the
stand-in's numbers are any provider's, so before relying on a cache, **read your provider's
documentation for the model you call**, and measure what it reports.

What every version shares is the rule this lesson is about: the cache matches from the start of the
prompt, so what comes first decides what can be reused.
