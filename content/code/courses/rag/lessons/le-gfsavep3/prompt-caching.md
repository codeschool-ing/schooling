---
title: Prompt caching
version: 2
---

The caches so far skip the model. **Prompt caching** keeps the model and makes part of the prompt
cheaper: the provider stores the processed form of a long prefix that repeats across requests, and a
request that starts with the same prefix is billed less for it and starts faster. OpenAI's API does it
automatically for long prompts; Anthropic's lets the request mark where the cacheable prefix ends,
with `cache_control`. Ollama does something simpler: it keeps the processed start of the last prompt in
memory, reuses it when the next prompt begins the same way, and reports the reused part as
`cache_read_input_tokens` through its Anthropic-compatible endpoint, which is how lesson 9 saw it.

The instructions of lesson 7 are 71 tokens, far below any minimum, so this pipeline gets nothing from
it. The case where it helps is a **long, fixed prefix**, and a common one is a set of documents the
assistant always has, the core policies, sent ahead of every question:

```schooling-example
{
  "language": "python",
  "file": "cached_prompt.py",
  "parts": [
    {
      "code": "import anthropic\nfrom chunking import load\n\ndocs = load()\nstanding = \"\\n\".join(f'<source id=\"{key}\">{body}</source>' for key, (meta, body) in docs.items()\n                     if key in (\"returns-policy\", \"shipping-and-delivery\", \"terms-of-sale\"))\nclient = anthropic.Anthropic()\nfor question in (\"How much is express delivery?\", \"How many days do I have to return a printed book?\"):\n    message = client.messages.create(\n        model=\"llama3.2:3b\", max_tokens=200,\n        system=[{\"type\": \"text\", \"text\": \"Answer Marginalia's customers from these documents.\\n\\n\" + standing,\n                 \"cache_control\": {\"type\": \"ephemeral\"}}],\n        messages=[{\"role\": \"user\", \"content\": question}])\n    u = message.usage\n    print(f\"{question}\\n  input {u.input_tokens}, written to cache {u.cache_creation_input_tokens}, \"\n          f\"read from cache {u.cache_read_input_tokens}, output {u.output_tokens}\")",
      "note": "Three documents sent ahead of every question as one fixed system prompt, marked as cacheable the way Anthropic's API asks, and what the usage says was read from the cache."
    }
  ]
}
```

```
ana@vm:~/rag$ python cached_prompt.py
How much is express delivery?
  input 2711, written to cache None, read from cache 15, output 20
How many days do I have to return a printed book?
  input 16, written to cache None, read from cache 2716, output 62
```

**2,716 tokens read from the cache on the second call**, and only 16 counted as fresh input: the
three documents came from the cache and the new question did not. The first call read 15, the start of
the system message, left by an earlier request. Nothing was written to the cache as far as the reply
says, `None`, because Ollama keeps its cache without being asked and charges nothing for it; the
`cache_control` mark was accepted and changed nothing. With a provider that bills, a cache read costs
a fraction of the normal input price and a cache write a premium, so the saving starts with the second
request inside the cache's lifetime; check the provider's current price list and its minimum prefix
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
