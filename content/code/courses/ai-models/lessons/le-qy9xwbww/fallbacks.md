---
title: A list of models is a promise about two models
version: 1
---

Routing chooses among providers of one model. The `models` field goes further and chooses among
**models**:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/model-fallbacks.mdx
  21: The `models` parameter lets you automatically try other models if the primary model's
      providers are down, rate-limited, or refuse to reply due to content moderation.
```

ana lists Llama 3.3 70B first and Qwen 2.5 72B second. Sent through the relay, it is the same story
as section 03: the list travels, and Ollama, which has no such field, answers with the one model it
was asked for:

```
ana@desk:~/desk$ export OPENROUTER_BASE_URL=http://127.0.0.1:8500/v1 MODEL=llama3.2:3b
ana@desk:~/desk$ python or_sort.py '{"models": ["meta-llama/llama-3.3-70b-instruct", "qwen/qwen-2.5-72b-instruct"]}'
other. model=llama3.2:3b provider=None
ana@desk:~/desk$ python relay.py show --body | grep -A3 '"models"'
  "models": [
    "meta-llama/llama-3.3-70b-instruct",
    "qwen/qwen-2.5-72b-instruct"
  ]
```

Against OpenRouter, the documentation says which model answered is in the response, and the bill
follows it:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/model-fallbacks.mdx
 116: Requests are priced using the model that was ultimately used, which will be returned in
      the `model` attribute of the response body.
```

That is useful and it is a trap, for the reason lesson 5 is built on. A fallback list is a
statement that **every model on it is good enough** for the task. If only the first was evaluated,
the outage that sends traffic to the second is also the moment the desk starts sorting e-mail with
a model nobody measured, at a different price, and nothing fails. Two rules follow:

- **Evaluate every model you list**, with the same cases and the same harness, before it goes in
  the list.
- **Count which model answered**, from the response's `model`, so that a month in which a third of
  the mail went to the fallback shows up in a report rather than in complaints.
