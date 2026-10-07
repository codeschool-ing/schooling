---
title: A suffix that chooses the provider
version: 1
---

Lesson 12 read the Hub as a place where models are kept. Hugging Face also **routes requests** to
providers that serve them, through one token and one client, `InferenceClient` in the
`huggingface_hub` library lesson 12 already used. Its documentation says how a provider is chosen:

```
# huggingface/hub-docs@08175d0f docs/inference-providers/index.md
 135| By default, our system automatically selects the fastest available provider for the specified model (equivalent to the `:fastest` policy — highest throughput in tokens per second).
 136|
 137| You can change the provider selection policy by appending a policy suffix to the model id: `:cheapest` for the most cost-efficient provider (lowest price per output token), or `:preferred` to follow your preference order in [Inference Provider settings](https://hf.co/settings/inference-providers). For example, `openai/gpt-oss-120b:cheapest`.
 138|
 139| You can also select the provider of your choice by appending the provider name to the model id (e.g. `"openai/gpt-oss-120b:groq"`).
```

`router.huggingface.co` was refused by the network of the machine this course was recorded on, so
the router's choices cannot be shown here, and neither can a speed or a price for any provider.
What can be shown is where the choice is written. `hf_route.py` sends the same request three times,
changing only the end of the model's name. Two settings point it somewhere else: `HF_BASE_URL` at
the relay, and `MODEL` at a model Ollama has:

```python
import json
import os

from huggingface_hub import InferenceClient
from huggingface_hub.errors import HfHubHTTPError

# Hugging Face's router, and your token from HF_TOKEN; HF_BASE_URL at the relay sends it to Ollama
client = InferenceClient(base_url=os.environ.get("HF_BASE_URL", "https://router.huggingface.co/v1"))
model = os.environ.get("MODEL", "meta-llama/Llama-3.3-70B-Instruct")
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

for suffix in ("", ":cheapest", ":groq"):
    try:
        r = client.chat_completion(model=model + suffix, max_tokens=16, temperature=0, messages=[
            {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
        print(f"{model + suffix:24} -> {r.model} {r.choices[0].message.content}")
    except HfHubHTTPError as e:
        print(f"{model + suffix:24} -> {e.response.status_code} {e.response.text.strip()}")
```

```
ana@desk:~/desk$ export HF_BASE_URL=http://127.0.0.1:8500/v1 HF_TOKEN=ollama MODEL=llama3.2:3b
ana@desk:~/desk$ python hf_route.py
llama3.2:3b              -> llama3.2:3b order-status
llama3.2:3b:cheapest     -> 400 {"error":{"message":"invalid model name","type":"invalid_request_error","param":null,"code":null}}
llama3.2:3b:groq         -> 400 {"error":{"message":"invalid model name","type":"invalid_request_error","param":null,"code":null}}
ana@desk:~/desk$ python relay.py show --count 3
POST /v1/chat/completions -> 200 llama3.2:3b
POST /v1/chat/completions -> 400 llama3.2:3b:cheapest
POST /v1/chat/completions -> 400 llama3.2:3b:groq
```

**The policy travels inside the model's name**, and nowhere else: the three requests differ only
in that string. Hugging Face's router reads what comes after the last colon as a policy or a
provider. Ollama reads `llama3.2:3b:cheapest` as a model name, finds it malformed, and says so with
a 400. That is the opposite of lesson 15 section 03, where Ollama ignored OpenRouter's `provider`
object and answered: a setting in a field of its own can be dropped in silence by a server that does
not know it, and a setting inside the model's name cannot. The price is the colon itself, which
Ollama already uses for a tag, so the same string means different things to the two servers.

Against the router, with a token of your own and `MODEL` and `HF_BASE_URL` unset, the documentation
above says what the three lines do. **No suffix** means `:fastest`, chosen by throughput, whatever
that provider charges. **`:cheapest`** chooses by price per output token. **`:groq`** names the
provider, and is the only one of the three whose provider ana knows from the code. The model's page
on the Hub lists which providers serve it and at what price; a request does not.

Compare lesson 15: OpenRouter's default leans to the cheapest provider and this one to the fastest.
The same model through two routers, both with their defaults, can cost different amounts and arrive
at different speeds, and neither difference is visible in the answer. **Name the policy, or the
provider, in the model string**, so that the choice is in the code where it can be read and
evaluated, which is lesson 15 section 03's rule in another syntax.

The request itself is OpenAI's shape, and the token travels as a Bearer:

```
ana@desk:~/desk$ python relay.py show --headers authorization,user-agent | head -4
POST /v1/chat/completions
user-agent: unknown/None; hf_hub/2.1.1; python/3.13.16
authorization: Bearer ollam…
```
