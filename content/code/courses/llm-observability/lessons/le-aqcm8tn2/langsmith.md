---
title: LangSmith, and what its SDK sends
version: 1
---

LangSmith is LangChain's platform for the same jobs: traces of model calls, datasets, evaluations,
prompts, and queues where people review runs. It is a hosted service, in the United States or in the
European Union, and installing it on your own machines is offered to enterprise customers. **It was
not run for this course.** What could be run is its Python SDK, which is open source and is the part
that lives in your application, pointed at `lab/recorder.py`: a small program on port 8700 that
answers like LangSmith's ingest endpoint and keeps every body it receives. Whatever arrives there is
exactly what would have left the machine.

`ls_ask.py` traces one question the two ways the SDK offers: a function decorated with
`@traceable`, and the OpenAI client wrapped with `wrap_openai`, which records each call through it.

```python
"""ls_ask.py: one question, traced with the LangSmith SDK, which sends its runs to LANGSMITH_ENDPOINT."""
import sys

from langsmith import Client, traceable
from langsmith.wrappers import wrap_openai
from openai import OpenAI

import redact

if "--redact" in sys.argv:   # LangSmith's own hooks, applied before anything is sent
    client = Client(hide_inputs=lambda d: {k: redact.redact(str(v)) for k, v in d.items()},
                    hide_outputs=lambda d: {k: redact.redact(str(v)) for k, v in d.items()},
                    omit_traced_runtime_info=True)
else:
    client = Client()
openai = wrap_openai(OpenAI())


@traceable(name="ask", client=client)
def ask(question):
    reply = openai.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": question}])
    return reply.choices[0].message.content


print(ask("Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift card valid?"))
client.flush()
```

The SDK is configured from the environment: `LANGSMITH_TRACING` turns it on, `LANGSMITH_ENDPOINT`
says where to send, `LANGSMITH_PROJECT` names the project. Compression is turned off so that the
recorder can read the bodies. `sent.py` prints what arrived:

```python
"""sent.py: what the recorder received, one line per run, with what each carried."""
import json

for request in map(json.loads, open("/var/lib/recorder/requests.jsonl")):
    for part in request["body"]:
        op, run, *field = part["name"].split(".")
        body = part["body"]
        if not field:
            print(f"{op:5} run {run[:8]} {body['name']} ({body['run_type']})")
        elif body:
            print(f"        {field[0]}: {json.dumps(body, ensure_ascii=False)[:110]}")
```

```
ana@lab:~/obs$ LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=lab-langsmith-key-0001 LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true python ls_ask.py
Marginalia gift cards are valid for one year from purchase.
ana@lab:~/obs$ python sent.py
post  run 01a11042 ask (chain)
        inputs: {"question": "Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift card valid?"}
        extra: {"metadata": {"ls_method": "traceable", "LANGSMITH_PROJECT": "marginalia-assistant", "LANGSMITH_TRACING": "tru
post  run 01a11042 ChatOpenAI (llm)
        inputs: {"messages": [{"role": "user", "content": "Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift c
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ex
        serialized: {"name": "ChatOpenAI"}
patch run 01a11042 ask (chain)
        outputs: {"output": "Marginalia gift cards are valid for one year from purchase."}
        extra: {"metadata": {"ls_method": "traceable", "LANGSMITH_PROJECT": "marginalia-assistant", "LANGSMITH_TRACING": "tru
patch run 01a11042 ChatOpenAI (llm)
        outputs: {"id": "chatcmpl-lab0867", "choices": [{"finish_reason": "stop", "index": 0, "logprobs": null, "message": {"co
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ex
```

LangSmith's word for a span is a **run**, and each run is sent twice: a `post` when it starts, with its
inputs, and a `patch` when it ends, with its outputs. The function is a run of type `chain`, the model
call a run of type `llm` inside it.

Read what went with them. **The customer's message, address included, in full**, on both runs. The
model's whole reply. And under `extra`, metadata the SDK adds on its own: the environment variables
that configured it, by name and value, and runtime details that `sent.py` cuts off at the edge of the
screen: the SDK's version, the Python version, the operating system and the machine's platform string.
None of it is a secret here. All of it leaves the machine, and a team that has not looked will not
know.

## The SDK's own hooks

The LangSmith client takes functions that see the inputs and outputs before they are sent:
`hide_inputs`, `hide_outputs`, and an `anonymizer` for patterns; and `omit_traced_runtime_info` leaves
the runtime details out. The `--redact` run passes lesson 2's `redact()` to the first two:

```
ana@lab:~/obs$ LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=lab-langsmith-key-0001 LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true python ls_ask.py --redact
Marginalia gift cards are valid for one year from purchase.
ana@lab:~/obs$ python sent.py
post  run 01a11042 ask (chain)
        inputs: {"question": "Hi, I'm Joana Prado ([email]). How long is a gift card valid?"}
        extra: {"metadata": {"ls_method": "traceable"}}
post  run 01a11042 ChatOpenAI (llm)
        inputs: {"messages": "[{'role': 'user', 'content': \"Hi, I'm Joana Prado ([email]). How long is a gift card valid?\"}]
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ex
        serialized: {"name": "ChatOpenAI"}
patch run 01a11042 ask (chain)
        outputs: {"output": "Marginalia gift cards are valid for one year from purchase."}
        extra: {"metadata": {"ls_method": "traceable"}}
patch run 01a11042 ChatOpenAI (llm)
        outputs: {"id": "chatcmpl-lab0868", "choices": "[{'finish_reason': 'stop', 'index': 0, 'logprobs': None, 'message': {'c
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ex
```

The address is gone from the inputs, and the environment variables and runtime details from `extra`. Two things are worth
noticing. The hooks receive the inputs as a dictionary, and the simple `str(v)` in `ls_ask.py` turned
the list of messages into the text of a list, which a screen will show as a string rather than as
messages; a careful hook redacts inside the structure. And the model's own run kept its
`ls_model_name` and provider metadata, which is fine, and a reminder that **only an inspection of what
arrived** says what a setting covers.

This is the same pattern as lesson 2's exporter, offered by the vendor: redact in the process, before
anything is sent. Whether to trust a vendor's hook or one's own is a judgement; testing either with a
canary is not.
