---
title: Prompt caching
version: 1
---

The caches so far skip the model. **Prompt caching** keeps the model and makes part of the prompt
cheaper: the provider stores the processed form of a long prefix that repeats across requests, and a
request that starts with the same prefix is billed less for it and starts faster. OpenAI's API does it
automatically for long prompts; Anthropic's lets the request mark where the cacheable prefix ends,
with `cache_control`. labgen imitates the second, with a minimum prefix of 1,024 tokens and a lifetime
of five minutes.

The instructions of lesson 7 are 71 tokens, far below any minimum, so this pipeline gets nothing from
it. The case where it helps is a **long, fixed prefix**, and a common one is a set of documents the
assistant always has, the core policies, sent ahead of every question:

```
ana@lab:~/rag$ python cached_prompt.py
How much is express delivery?
  input 7, written to cache 2697, read from cache 0, output 40
How many days do I have to return a printed book?
  input 13, written to cache 0, read from cache 2697, output 86
```

**2,697 tokens written to the cache on the first call and read from it on the second**, with only the
7 and 13 tokens of each question billed as ordinary input. At the time of writing, providers bill a
cache read at a fraction of the normal input price and a cache write at a premium, so the saving
starts with the second request inside the cache's lifetime; check the provider's current price list
before relying on the ratio.

Three conditions decide whether it applies:

- **The prefix must be identical**, byte for byte, from the start. Lesson 12's sources change with
  every question, so they cannot be part of it; only what comes before them can.
- **It must be long enough**, past the provider's minimum.
- **It must be reused within its lifetime**, which a busy assistant does and a quiet one does not.

Prompt caching also changes the design argument of lesson 1. Sending the whole of a small, fixed corpus
on every call becomes cheaper when the corpus is cached, and for a handful of documents that never
change it can be simpler than retrieval. It is still bounded by the window, still pays the distraction
lesson 12 described, and still needs lesson 14's permissions, which a prefix shared by everyone cannot
express.
