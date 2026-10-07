---
title: Three things change, and nothing else
version: 1
---

Lesson 8 section 05 called Chat Completions the shape most of the industry copied, and lessons 9,
14, 15 and 19 kept meeting it: Mistral, Ollama, LM Studio, OpenRouter and Hugging Face's router all
accept a request written for OpenAI's library. Anthropic and Google offer the same, as a separate
endpoint beside their own APIs. `compat.py` sends ten of ana's cases to eight providers through one
client, and changes three things per provider:

```python
import json
import os

import openai
from openai import OpenAI


def key(name):  # your key for each provider, where you have one
    return os.environ.get(name, "none")


# name: (base URL, key, model) -- the only three things that change
PROVIDERS = {
    "OpenAI":       ("https://api.openai.com/v1", key("OPENAI_API_KEY"), "gpt-5.4-mini"),
    "Anthropic":    ("https://api.anthropic.com/v1/", key("ANTHROPIC_API_KEY"), "claude-haiku-4-5"),
    "Google":       ("https://generativelanguage.googleapis.com/v1beta/openai/", key("GOOGLE_API_KEY"),
                     "gemini-3.5-flash"),
    "Mistral":      ("https://api.mistral.ai/v1", key("MISTRAL_API_KEY"), "mistral-small-latest"),
    "OpenRouter":   ("https://openrouter.ai/api/v1", key("OPENROUTER_API_KEY"), "meta-llama/llama-3.3-70b-instruct"),
    "Hugging Face": ("https://router.huggingface.co/v1", key("HF_TOKEN"), "meta-llama/Llama-3.3-70B-Instruct"),
    "Ollama":       ("http://127.0.0.1:11434/v1", "ollama", "llama3.2:3b"),
    "LM Studio":    ("http://127.0.0.1:1234/v1", "lm-studio", "llama-3.2-3b-instruct"),
}
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")][30:]

for name, (url, api_key, model) in PROVIDERS.items():
    client = OpenAI(base_url=url, api_key=api_key, max_retries=0)
    right = 0
    try:
        for c in cases:
            r = client.chat.completions.create(model=model, temperature=0, max_tokens=16, messages=[
                {"role": "system", "content": prompt}, {"role": "user", "content": c["text"]}])
            right += r.choices[0].message.content.strip() == c["label"]
        print(f"{name:12} {right}/{len(cases)}")
    except openai.APIStatusError as e:
        print(f"{name:12} {e.status_code} {type(e).__name__}, its body a {type(e.body).__name__}")
    except openai.APIConnectionError as e:
        print(f"{name:12} no connection: {e.__cause__}")
```

Each key comes from the variable that provider's own library reads, so a key you already have is
used and the rest are sent as `none`. On the machine this course was recorded on, with no key:

```
ana@desk:~/desk$ python compat.py
OpenAI       403 PermissionDeniedError, its body a str
Anthropic    401 AuthenticationError, its body a dict
Google       400 BadRequestError, its body a list
Mistral      403 PermissionDeniedError, its body a str
OpenRouter   403 PermissionDeniedError, its body a str
Hugging Face 403 PermissionDeniedError, its body a str
Ollama       4/10
LM Studio    no connection: [Errno 111] Connection refused
```

Eight providers, one loop, and eight different outcomes, every one of them real:

- **Ollama answered all ten**, and scored what llama3.2:3b scores on these cases at temperature 0.
- **Anthropic and Google read the request and refused the key.** That is the most this machine
  could get from them, and it is enough to show the request was understood.
- **The four 403s are not the providers.** Those hosts were refused by the network the course was
  recorded on, and its proxy answered in their place. At home, each will refuse the placeholder
  key itself, and with a key of your own, answer.
- **LM Studio was not running**, which is the state of the machine lesson 14 section 05 found.

What the run shows is the part of the shape that holds: **one loop reached every provider**, and
lesson 5's harness could run unchanged against each one that has a key. That is the whole value of
the shape, and it is large: comparing candidates from different providers is a dictionary of three
columns rather than eight integrations.

The errors are the first sign of what the shape does not cover. The same mistake, a wrong key, came
back as a 401 `AuthenticationError` from Anthropic and a 400 `BadRequestError` from Google, so a
program that catches the first to say "check your key" says nothing for Google. And the body of the
error is a dictionary from one and **a list** from the other: `e.body["message"]` works on
Anthropic's and raises a `TypeError` on Google's, inside the code that was supposed to handle the
error. A program that reads an error has to know which provider it is talking to after all.
