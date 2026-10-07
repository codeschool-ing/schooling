---
title: Calling Mistral
version: 1
---

Mistral has its own Python SDK, `mistralai`, at version 3.0.0 in the desk. `mistral_sort.py` sends
ana's sorting prompt and one e-mail through it. Without a Mistral key it sends them to the relay
from section 03, which passes them to Ollama and the course's model:

```python
from mistralai.client import Mistral

# with a Mistral key: api_key=os.environ["MISTRAL_API_KEY"], and no server_url
client = Mistral(api_key="ollama", server_url="http://127.0.0.1:8500")
r = client.chat.complete(model="llama3.2:3b", messages=[
    {"role": "system", "content": open("prompts/triage.txt").read()},
    {"role": "user", "content": "Hello, where is my parcel? LB-20488"}])
print(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens)
```

```
ana@desk:~/desk$ python mistral_sort.py
product-question 72 3
```

The answer is llama3.2:3b's, and the two numbers are the tokens it read and wrote. **Mistral's own
SDK got an answer from Ollama**, which is the interesting part, and the relay shows why it could:

```
ana@desk:~/desk$ python relay.py show --headers user-agent,authorization
POST /v1/chat/completions
user-agent: mistral-client-python/3.0.0
authorization: Bearer ollam…

{
  "model": "llama3.2:3b",
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
teaches as the industry's common format, and which Ollama answers. Only the `user-agent`, naming
the SDK and its version, says this is Mistral's SDK. The other thing that matters is **the key**: a
placeholder here, and at Mistral what decides whose account is paying.

## What that means in practice

A program written for OpenAI's Chat Completions reaches Mistral by changing the address and the
key, and lesson 20 does exactly that. The SDK is worth using anyway for what it adds on top, typed
replies and retries, and the request it sends is no harder to read than the one OpenAI's SDK would
have sent. **When two providers share a shape, switching between them is a configuration change**,
which is the property lesson 5's harness relied on to evaluate several candidates with one loop.
