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

`lab/or_sort.py` sorts one of ana's cases through the stand-in and prints who served it. Its one
argument is any extra JSON for the request body:

```python
import json
import os
import sys

from openai import OpenAI, APIStatusError

client = OpenAI(base_url=os.environ["OPENROUTER_BASE_URL"], api_key=os.environ["OPENROUTER_API_KEY"])
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

# the request's extra fields, as JSON on the command line: {"provider": {...}} or {"models": [...]}
extra = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
try:
    r = client.chat.completions.create(
        model="standin/large", extra_body=extra,
        messages=[{"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
except APIStatusError as e:
    sys.exit(f"{e.status_code}: {e.body['message']}")
print(f"{r.choices[0].message.content:6} model={r.model} provider={r.provider} cost=${r.usage.cost:.6f}")
```

The stand-in's `standin/large` is served by two providers, `standin-east` and `standin-west`, at the
same price. It does not load-balance; it tries them in order, which makes the effect of each
setting visible:

```
ana@desk:~/desk$ python lab/or_sort.py
other  model=standin/large provider=standin-east cost=$0.000168
```

```
ana@desk:~/desk$ python lab/or_sort.py '{"provider": {"order": ["standin-west"]}}'
other  model=standin/large provider=standin-west cost=$0.000168
```

`provider.order` names who to try first. Now `standin-east` goes down (the lab is told so; in the
world, a provider simply fails), and the same two requests run again, the second with fallbacks
turned off:

```
ana@desk:~/desk$ python lab/or_sort.py
other  model=standin/large provider=standin-west cost=$0.000168
```

```
ana@desk:~/desk$ python lab/or_sort.py '{"provider": {"order": ["standin-east"], "allow_fallbacks": false}}'
503: No allowed providers are available for the selected model. standin/large at standin-east: 503
```

With fallbacks allowed, the outage cost ana nothing she could see: the request went to the other
provider and the answer came back. With `allow_fallbacks: false` the request **fails rather than
move**. Which one she wants depends on lesson 5 section 10's decision: if the evaluation was run
against one provider's serving of the model, a different provider is a different candidate, and
failing may be the honest result.

**Record the provider with every answer.** The response names it, and an evaluation or an
incident that does not know which provider answered cannot be repeated.
