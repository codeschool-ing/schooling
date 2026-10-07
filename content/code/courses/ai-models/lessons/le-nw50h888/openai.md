---
title: One program, either server
version: 1
---

Both tools also answer in OpenAI's shape, the one lesson 9 section 05 saw Mistral share. So the
OpenAI library, pointed at a different address, talks to either. `two_servers.py` asks each
server which models it has and sorts the same case with one of them:

```python
import json

from openai import OpenAI, APIConnectionError

prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

SERVERS = {"Ollama": ("http://127.0.0.1:11434/v1", "ollama"),
           "LM Studio": ("http://127.0.0.1:1234/v1", "lm-studio")}
for name, (url, key) in SERVERS.items():
    # the library needs a key; neither server reads it here
    client = OpenAI(base_url=url, api_key=key, max_retries=0)
    try:
        models = [m.id for m in client.models.list().data]
    except APIConnectionError:
        print(f"{name:9} nothing is listening at {url}")
        continue
    model = "llama3.2:3b" if "llama3.2:3b" in models else models[0]
    r = client.chat.completions.create(model=model, temperature=0, messages=[
        {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
    print(f"{name:9} {len(models)} models, among them {model}: {r.choices[0].message.content}")
```

```
ana@desk:~/desk$ python two_servers.py
Ollama    3 models, among them llama3.2:3b: other.
LM Studio nothing is listening at http://127.0.0.1:1234/v1
```

**Same path, two ports**, and on the machine this course was recorded on only one of them answered:
there was no LM Studio there, and the program says so instead of stopping, because
`APIConnectionError` is what the library raises when nobody is listening. With LM Studio running
and its server switched on, the second line is a sorted case too.

The keys are placeholders from each project's own examples, there because the library refuses to
start without one. Ollama's documentation calls its placeholder "required but ignored"; LM Studio
checks a key only with its *Require Authentication* setting on, which is for when the server is
shared. **The model name is the one thing that is not portable**: each server lists what it has
under its own names, which is why the program asks for the list rather than assuming one.

The shape also has a cost, and Ollama's documentation states it:

```
# ollama/ollama@42e911bc docs/api/openai-compatibility.mdx
 386: The OpenAI API does not have a way of setting the context size for a model. If you need
      to change the context size, create a `Modelfile` which looks like:
```

OpenAI's API has no `options`, so there is no `num_ctx` to send. Through `/v1`, the window is
whatever the model was created with, and changing it means a Modelfile, Ollama's recipe for a
model, with `PARAMETER num_ctx` in it and a new name. **Portability buys the common part and loses
the rest**: section 04's check needs `prompt_eval_count`, which the native API returns, and lesson
20 is about exactly this trade across every provider that offers the shape.
