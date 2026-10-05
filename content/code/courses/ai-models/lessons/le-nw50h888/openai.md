---
title: One program, either server
version: 1
---

Both tools also answer in OpenAI's shape, the one lesson 9 section 05 saw Mistral share. So the
OpenAI library, pointed at a different address, talks to either. `lab/two_servers.py` asks each
server which model it has loaded and sorts the same case with it:

```python
import json

from openai import OpenAI

prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

SERVERS = {"Ollama": ("http://127.0.0.1:11434/v1", "ollama"),
           "LM Studio": ("http://127.0.0.1:1234/v1", "lm-studio")}
for name, (url, key) in SERVERS.items():
    client = OpenAI(base_url=url, api_key=key)   # the library needs a key; neither server reads it here
    model = client.models.list().data[0].id
    r = client.chat.completions.create(model=model, temperature=0, messages=[
        {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
    print(f"{name:9} {model:22} {r.choices[0].message.content}")
```

```
ana@desk:~/desk$ python lab/two_servers.py
Ollama    standin-local:latest   other
LM Studio standin-local          other
```

```
ana@desk:~/desk$ wire --count 4
GET /v1/models -> 200 ollama 
POST /v1/chat/completions -> 200 ollama standin-local
GET /v1/models -> 200 lmstudio 
POST /v1/chat/completions -> 200 lmstudio standin-local
```

Same paths, two ports. The keys are placeholders from each project's own examples, there because
the library refuses to start without one. Ollama's documentation calls its placeholder "required
but ignored"; LM Studio checks a key only with its *Require Authentication* setting on, which is
for when the server is shared. **The model name is the one thing
that is not portable**: Ollama says `standin-local:latest` where LM Studio says `standin-local`,
which is why the program asks rather than assuming.

The shape also has a cost, and Ollama's documentation states it:

```
ana@desk:~/desk$ sources quote ollama-openai "does not have a way of setting the context size"
# ollama/ollama@42e911bc docs/api/openai-compatibility.mdx
 386: The OpenAI API does not have a way of setting the context size for a model. If you need
      to change the context size, create a `Modelfile` which looks like:
```

OpenAI's API has no `options`, so there is no `num_ctx` to send. Through `/v1`, the window is
whatever the model was created with, and changing it means a Modelfile, Ollama's recipe for a
model, with `PARAMETER num_ctx` in it and a new name. **Portability buys the common part and loses
the rest**: section 04's check needs `prompt_eval_count`, which the native API returns, and lesson
20 is about exactly this trade across every provider that offers the shape.
