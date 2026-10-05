---
title: A suffix that chooses the provider
version: 1
---

Lesson 12 read the Hub as a place where models are kept. Hugging Face also **routes requests** to
providers that serve them, through one token and one client, `InferenceClient` in the
`huggingface_hub` library lesson 12 already used. Its documentation says how a provider is chosen:

```
ana@desk:~/desk$ sources lines hf-providers 135 139
# huggingface/hub-docs@08175d0f docs/inference-providers/index.md
 135| By default, our system automatically selects the fastest available provider for the specified model (equivalent to the `:fastest` policy — highest throughput in tokens per second).
 136|
 137| You can change the provider selection policy by appending a policy suffix to the model id: `:cheapest` for the most cost-efficient provider (lowest price per output token), or `:preferred` to follow your preference order in [Inference Provider settings](https://hf.co/settings/inference-providers). For example, `openai/gpt-oss-120b:cheapest`.
 138|
 139| You can also select the provider of your choice by appending the provider name to the model id (e.g. `"openai/gpt-oss-120b:groq"`).
```

huggingface.co could not be reached from the machine this course was recorded on. The stand-in plays
the router, with the two providers of lesson 15 and a speed and a price for each: `standin-east`
at 40 tokens a second and $15 per million output tokens, `standin-west` at 80 a second and $18.
`lab/hf_route.py` sends the same request three times, changing only the model's name:

```python
import json
import os

from huggingface_hub import InferenceClient

client = InferenceClient(base_url=os.environ["HF_BASE_URL"])   # the token comes from HF_TOKEN
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

for model in ("standin/large", "standin/large:cheapest", "standin/large:standin-east"):
    r = client.chat_completion(model=model, max_tokens=16, temperature=0, messages=[
        {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
    print(f"{model:28} -> {r.model:14} {r.choices[0].message.content}")
```

```
ana@desk:~/desk$ python lab/hf_route.py
standin/large                -> standin/large  other
standin/large:cheapest       -> standin/large  other
standin/large:standin-east   -> standin/large  other
```

Three identical answers, and nothing in them says who served each. The lab's log does:

```
ana@desk:~/desk$ wire --count 3
POST /hf/v1/chat/completions -> 200 hf standin-large routed={'model': 'standin/large', 'provider': 'standin-west', 'policy': 'fastest'}
POST /hf/v1/chat/completions -> 200 hf standin-large routed={'model': 'standin/large', 'provider': 'standin-east', 'policy': 'cheapest'}
POST /hf/v1/chat/completions -> 200 hf standin-large routed={'model': 'standin/large', 'provider': 'standin-east', 'policy': 'standin-east'}
```

- **No suffix** means `:fastest`, and the faster provider is the dearer one: `standin-west`, at
  $18 instead of $15, **20% more per output token**, chosen by a default nobody wrote down.
- **`:cheapest`** chose `standin-east`.
- **`:standin-east`** named the provider, and is the only one of the three whose provider ana knows
  from her own code.

Compare lesson 15: OpenRouter's default leans to the cheapest provider and this one to the fastest.
The same model through two routers, both with their defaults, can cost different amounts and arrive
at different speeds, and neither difference is visible in the answer. **Name the policy, or the
provider, in the model string**, so that the choice is in the code where it can be read and
evaluated, which is lesson 15 section 03's rule in another syntax.

The request itself is OpenAI's shape, and the token travels as a Bearer:

```
ana@desk:~/desk$ wire --headers authorization,user-agent | head -4
POST /hf/v1/chat/completions
user-agent: unknown/None; hf_hub/2.1.1; python/3.11.15
authorization: Bearer hf_la…
```
