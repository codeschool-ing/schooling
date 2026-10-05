---
title: Calling Mistral
version: 1
---

Mistral has its own Python SDK, `mistralai`, at version 3.0.0 in the lab. `lab/mistral_sort.py`
sends ana's sorting prompt and one e-mail through it:

```python
import os

from mistralai.client import Mistral

client = Mistral(api_key=os.environ["MISTRAL_API_KEY"], server_url=os.environ["MISTRAL_SERVER_URL"])
r = client.chat.complete(model="standin-small", messages=[
    {"role": "system", "content": open("prompts/triage.txt").read()},
    {"role": "user", "content": "Hello, where is my parcel? LB-20488"}])
print(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens)
```

```
ana@desk:~/desk$ python lab/mistral_sort.py
order-status 50 2
```

The answer, `order-status`, is the stand-in's table, as everywhere in this course; the 50 and 2 are
its token counts. The interesting part is what the SDK put on the wire, which `wire` prints from
the stand-in's log:

```
ana@desk:~/desk$ wire --headers user-agent,authorization
POST /v1/chat/completions
user-agent: mistral-client-python/3.0.0
authorization: Bearer lab-m…

{
  "model": "standin-small",
  "messages": [
    {
      "content": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n",
      "role": "system"
    },
    {
      "content": "Hello, where is my parcel? LB-20488",
      "role": "user"
    }
  ],
  "stream": false
}
```

**`POST /v1/chat/completions`**, with the key as a `Bearer` token and a body of `model` and
`messages` in roles: the same path and the same shape as OpenAI's Chat Completions, which lesson 20
teaches as the industry's common format. Only two things say this is Mistral: the `user-agent`,
naming the SDK and its version, and **the key**, which is what an actual provider uses to decide
whose account is paying. The stand-in decides the same way, which is the only reason it can answer
OpenAI and Mistral on one path.

## What that means in practice

A program written for OpenAI's Chat Completions reaches Mistral by changing the address and the
key, and lesson 20 does exactly that. The SDK is worth using anyway for what it adds on top, typed
replies and retries, and the request it sends is no harder to read than the one OpenAI's SDK would
have sent. **When two providers share a shape, switching between them is a configuration change**,
which is the property lesson 5's harness relied on to evaluate several candidates with one loop.
