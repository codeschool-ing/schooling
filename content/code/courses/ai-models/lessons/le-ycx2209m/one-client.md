---
title: Three things change, and nothing else
version: 1
---

Lesson 8 section 05 called Chat Completions the shape most of the industry copied, and lessons 9,
14, 15 and 19 kept meeting it: Mistral, Ollama, LM Studio, OpenRouter and Hugging Face's router all
accept a request written for OpenAI's library. Anthropic offers the same, as a separate endpoint
beside its own API. `lab/compat.py` sends lesson 13's ten held-out cases to seven providers through
one client, and changes three things per provider:

```python
import json
import os

from openai import OpenAI

env = os.environ
# name: (base URL, key, model) -- the only three things that change
PROVIDERS = {
    "OpenAI":       (env["OPENAI_BASE_URL"], env["OPENAI_API_KEY"], "standin-small"),
    "Anthropic":    (env["ANTHROPIC_BASE_URL"] + "/v1/", env["ANTHROPIC_API_KEY"], "standin-large"),
    "Mistral":      (env["MISTRAL_SERVER_URL"] + "/v1", env["MISTRAL_API_KEY"], "standin-small"),
    "OpenRouter":   (env["OPENROUTER_BASE_URL"], env["OPENROUTER_API_KEY"], "standin/small"),
    "Hugging Face": (env["HF_BASE_URL"] + "/v1", env["HF_TOKEN"], "standin/small:cheapest"),
    "Ollama":       ("http://127.0.0.1:11434/v1", "ollama", "standin-local"),
    "LM Studio":    ("http://127.0.0.1:1234/v1", "lm-studio", "standin-local"),
}
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")][30:]

for name, (url, key, model) in PROVIDERS.items():
    client = OpenAI(base_url=url, api_key=key)
    right, limits = 0, set()
    for c in cases:
        raw = client.chat.completions.with_raw_response.create(
            model=model, temperature=0, max_tokens=16,
            messages=[{"role": "system", "content": prompt}, {"role": "user", "content": c["text"]}])
        right += raw.parse().choices[0].message.content.strip() == c["label"]
        limits |= {h for h in raw.headers if "ratelimit" in h and "requests" in h and "remaining" in h}
    print(f"{name:12} {model:22} {right}/{len(cases)}  {', '.join(sorted(limits)) or '(no rate-limit header)'}")
```

```
ana@desk:~/desk$ python lab/compat.py
OpenAI       standin-small          7/10  x-ratelimit-remaining-requests
Anthropic    standin-large          9/10  anthropic-ratelimit-requests-remaining
Mistral      standin-small          7/10  x-ratelimit-remaining-requests
OpenRouter   standin/small          7/10  x-ratelimit-remaining-requests
Hugging Face standin/small:cheapest 7/10  x-ratelimit-remaining-requests
Ollama       standin-local          7/10  (no rate-limit header)
LM Studio    standin-local          7/10  (no rate-limit header)
```

```
ana@desk:~/desk$ wire --count 70 | cut -d" " -f1,2,5 | sort | uniq -c
     10 POST /hf/v1/chat/completions hf
     10 POST /openrouter/api/v1/chat/completions openrouter
     10 POST /v1/chat/completions anthropic
     10 POST /v1/chat/completions lmstudio
     10 POST /v1/chat/completions mistral
     10 POST /v1/chat/completions ollama
     10 POST /v1/chat/completions openai
```

Seventy requests, one library, and the stand-in behind all of them, so the scores are its tables
and not seven models. What the run shows is the part that is real: **one loop reached seven
providers**, five of them at the very same path, and the evaluation harness of lesson 5 could run
unchanged against each. That is the whole value of the shape, and it is large: comparing candidates
from different providers is a dictionary of three columns rather than seven integrations.

The last column is the first sign of what the shape does not cover. The request was the same; the
**headers that came back were not**. Two naming schemes for the same fact, and none at all from the
two servers on ana's own machine. Lesson 21 reads those headers, and a program that reads them has
to know which provider it is talking to after all.
