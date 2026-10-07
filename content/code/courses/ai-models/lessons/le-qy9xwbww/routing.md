---
title: Which provider answered
version: 1
---

Lesson 10 section 05 found Llama 4 Maverick in ten entries of the sheet, more than fourteen times
apart on input price. On
OpenRouter, one model name can stand for several of them, and **OpenRouter picks one per
request**. Its documentation says how, by default:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/provider-selection.mdx
  65: 2. For the stable providers, look at the lowest-cost candidates and select one weighted
      by inverse square of the price (example below).
  73: - Your request is routed to Provider A. Provider A is 9x more likely to be first routed
      to Provider A than Provider C because $(1 / 3^2 = 1/9)$ (inverse square of the price).
```

Weighted by the inverse square of the price, three providers at $1, $2 and $3 share the traffic
like this, in percent:

```
ana@desk:~/desk$ python -c "p = [1, 2, 3]; w = [1 / x**2 for x in p]; print([round(x / sum(w) * 100, 1) for x in w])"
[73.5, 18.4, 8.2]
```

Three requests in four go to the cheapest, but not all of them, so **two identical requests can be
served by two different providers**. Lesson 10 section 05 said the precision a host serves is its
own choice; here the host is chosen per request, by somebody else.

`or_sort.py` sorts one of ana's cases through OpenRouter and prints which model and which provider
answered. Its one argument is any extra JSON for the request body, which is where routing is asked
for. Two settings point it somewhere else: `OPENROUTER_BASE_URL` at the relay, and `MODEL` at a
model Ollama has:

```python
import json
import os
import sys

from openai import OpenAI

# OpenRouter's address and your key; without them, the relay passes the request to Ollama
client = OpenAI(base_url=os.environ.get("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1"),
                api_key=os.environ.get("OPENROUTER_API_KEY", "none"))
model = os.environ.get("MODEL", "meta-llama/llama-3.3-70b-instruct")
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

# the request's extra fields, as JSON on the command line: {"provider": {...}} or {"models": [...]}
extra = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
r = client.chat.completions.create(model=model, extra_body=extra, messages=[
    {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
print(r.choices[0].message.content, f"model={r.model}", f"provider={getattr(r, 'provider', None)}")
```

Here it asks for DeepInfra first, then Together, and **no fallback to anybody else**:

```
ana@desk:~/desk$ export OPENROUTER_BASE_URL=http://127.0.0.1:8500/v1 MODEL=llama3.2:3b
ana@desk:~/desk$ python or_sort.py '{"provider": {"order": ["deepinfra", "together"], "allow_fallbacks": false}}'
other. model=llama3.2:3b provider=None
ana@desk:~/desk$ python relay.py show --body | grep -A6 '"provider"'
  "provider": {
    "order": [
      "deepinfra",
      "together"
    ],
    "allow_fallbacks": false
  }
```

The answer came back, and **`provider=None` is the finding**. Ollama has no `provider` field in its
API, so it ignored the object and answered with the model it was asked for, without a word; the
relay shows the object was sent. OpenRouter reads it, and its documentation says what it does with
it:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/provider-selection.mdx
  30: | `allow_fallbacks` | boolean | `true` | Whether to allow backup providers when the
      primary is unavailable. [Learn more](#disabling-fallbacks) |
 944: Here's an example with `allow_fallbacks` set to `false` that skips over OpenAI (which
      doesn't host Mixtral), tries Together, and then fails if Together fails:
```

So against OpenRouter the same request goes to DeepInfra, or to Together if DeepInfra cannot take
it, and **fails rather than move further** with `allow_fallbacks: false`. Which of those ana wants
depends on lesson 5 section 10's decision: if the evaluation was run against one provider's serving
of the model, a different provider is a different candidate, and failing may be the honest result.

**Record the provider with every answer.** OpenRouter's response names it, and an evaluation or an
incident that does not know which provider answered cannot be repeated. A server that does not know
the field, like Ollama here, answers without it, which is why `or_sort.py` prints `None` rather
than assuming.
