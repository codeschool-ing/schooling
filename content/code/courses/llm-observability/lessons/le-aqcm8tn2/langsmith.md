---
title: LangSmith, and what its SDK sends
version: 2
---

LangSmith is LangChain's platform for the same jobs: traces of model calls, datasets, evaluations,
prompts, and queues where people review runs. It is a hosted service, in the United States or in the
European Union, and installing it on your own machines is offered to enterprise customers. **It is
not run in this course.** What can be run is its Python SDK, which is open source and is the part
that lives in your application. Point it at a program of your own that answers the way LangSmith's
ingest endpoint does and keeps every body it receives, and whatever arrives there is exactly what
would have left your machine.

That program is `recorder.py`. It is a **stand-in**, under ninety lines, and it is not LangSmith:
it answers the one question the SDK asks before sending, and writes down the rest. Save it in
`~/obs`:

```python
"""recorder.py: a stand-in for LangSmith's ingest endpoint, on 127.0.0.1:8700, for lesson 6.

LangSmith is a hosted service, and installing it on your own machines is
something LangChain offers to enterprise customers only, so the course could
not run it. What the lesson CAN show is what the LangSmith SDK sends, which is
the part that leaves your machine. So the SDK is pointed here, and this
program does three things and nothing else:

    GET  /info          answers as an ingest endpoint does, so the SDK sends
    POST /runs/...      every body it receives is kept, as it arrived, one JSON
                        line per request in recorder/requests.jsonl: the path,
                        the content type and the body (decoded if it is JSON
                        or multipart, so a person can read it)
    anything else       202, so the SDK carries on

It stores nothing else, shows nothing, and is not LangSmith. What LangSmith
does with a run after it arrives is not shown here.
"""
import json
import os
from email.parser import BytesParser
from email.policy import HTTP
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DIR = "recorder"


def decode(ctype, raw):
    if ctype.startswith("application/json"):
        return json.loads(raw or b"null")
    if ctype.startswith("multipart/"):
        msg = BytesParser(policy=HTTP).parsebytes(b"Content-Type: " + ctype.encode() + b"\r\n\r\n" + raw)
        parts = []
        for p in msg.iter_parts():
            body = p.get_payload(decode=True) or b""
            try:
                body = json.loads(body)
            except ValueError:
                body = body.decode("utf-8", "replace")
            parts.append({"name": p.get_param("name", header="content-disposition"), "body": body})
        return parts
    return raw.decode("utf-8", "replace")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def reply(self, status, obj):
        data = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.split("?")[0].rstrip("/") == "/info":
            return self.reply(200, {"version": "recorder", "batch_ingest_config": {
                "use_multipart_endpoint": True, "scale_up_qsize_trigger": 1000, "scale_up_nthreads_limit": 16,
                "scale_down_nempty_trigger": 4, "size_limit": 100, "size_limit_bytes": 20971520}})
        self.reply(200, {})

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        if self.headers.get("Content-Encoding") == "zstd":
            raw = b""  # compressed bodies are not decoded; the lesson turns compression off
        ctype = self.headers.get("Content-Type", "")
        os.makedirs(DIR, exist_ok=True)
        with open(os.path.join(DIR, "requests.jsonl"), "a") as f:
            f.write(json.dumps({"path": self.path, "content_type": ctype.split(";")[0],
                                "body": decode(ctype, raw)}, ensure_ascii=False) + "\n")
        self.reply(202, {})

    do_PATCH = do_PUT = do_POST


def main():
    srv = ThreadingHTTPServer(("127.0.0.1", 8700), Handler)
    srv.daemon_threads = True
    print("recorder listening on http://127.0.0.1:8700", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
```

Start it in the background, from `~/obs`, and leave it running while you read this section:

```sh
python recorder.py &
```

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
    reply = openai.chat.completions.create(model="llama3.2:3b", temperature=0, messages=[{"role": "user", "content": question}])
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

for request in map(json.loads, open("recorder/requests.jsonl")):
    for part in request["body"]:
        op, run, *field = part["name"].split(".")
        body = part["body"]
        if not field:
            print(f"{op:5} run {run[:8]} {body['name']} ({body['run_type']})")
        elif body:
            print(f"        {field[0]}: {json.dumps(body, ensure_ascii=False)[:110]}")
```

```
ana@dev:~/obs$ LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=the-recorder-ignores-it LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true python ls_ask.py
Hello Joana!

The validity period of a gift card can vary depending on the issuer and the type of card. Some gift cards may be valid for a specific period, such as 1-2 years, while others may be valid for a longer or shorter period.

Typically, gift cards are valid for:

* 1-2 years from the date of purchase
* 3-5 years from the date of purchase (for premium or high-value cards)
* Until the balance is depleted (in some cases)

It's always best to check the specific terms and conditions of the gift card issuer, as they may have different policies. You can usually find this information on the gift card itself, on the issuer's website, or by contacting their customer service.

If you're unsure about the validity of your gift card, I recommend reaching out to the issuer to confirm the expiration date.

Hope this helps, Joana!
ana@dev:~/obs$ python sent.py
post  run 01a1191a ask (chain)
        inputs: {"question": "Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift card valid?"}
        extra: {"metadata": {"ls_method": "traceable", "LANGSMITH_PROJECT": "marginalia-assistant", "LANGSMITH_TRACING": "tru
post  run 01a1191a ChatOpenAI (llm)
        inputs: {"messages": [{"role": "user", "content": "Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift c
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ll
        serialized: {"name": "ChatOpenAI"}
patch run 01a1191a ask (chain)
        outputs: {"output": "Hello Joana!\n\nThe validity period of a gift card can vary depending on the issuer and the type o
        extra: {"metadata": {"ls_method": "traceable", "LANGSMITH_PROJECT": "marginalia-assistant", "LANGSMITH_TRACING": "tru
patch run 01a1191a ChatOpenAI (llm)
        outputs: {"id": "chatcmpl-339", "choices": [{"finish_reason": "stop", "index": 0, "logprobs": null, "message": {"conten
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ll
```

LangSmith's word for a span is a **run**, and each run is sent twice: a `post` when it starts, with its
inputs, and a `patch` when it ends, with its outputs. The function is a run of type `chain`, the model
call a run of type `llm` inside it.

First, the reply. `ls_ask.py` asks the model directly, with none of Marginalia's documents, so
`llama3.2:3b` answers from what it learnt elsewhere: gift cards in general, one to five years, check
with the issuer. Marginalia's own answer, two years, is in a document it was never shown. That is
not what this section is about, but it is why the assistant searches the documents before it asks.

Then read what went with it. **The customer's message, address included, in full**, on both runs.
The model's whole reply. And under `extra`, metadata the SDK adds on its own: the environment
variables that configured it, by name and value, and runtime details. `sent.py` cuts those off at
the edge of the screen; they are the SDK's version, the Python version, the operating system and the
machine's platform string. None of it is a secret here. All of it leaves the machine, and a team
that has not looked will not know.

## The SDK's own hooks

The LangSmith client takes functions that see the inputs and outputs before they are sent:
`hide_inputs`, `hide_outputs`, and an `anonymizer` for patterns; and `omit_traced_runtime_info` leaves
the runtime details out. The `--redact` run passes lesson 2's `redact()` to the first two:

```
ana@dev:~/obs$ rm recorder/requests.jsonl
ana@dev:~/obs$ LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=the-recorder-ignores-it LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true python ls_ask.py --redact
Hello Joana!

The validity period of a gift card can vary depending on the issuer and the type of card. Some gift cards may be valid for a specific period, such as 1-2 years, while others may be valid for a longer or shorter period.

Typically, gift cards are valid for:

* 1-2 years from the date of purchase
* 3-5 years from the date of purchase (for premium or high-value cards)
* Until the balance is depleted (in some cases)

It's always best to check the specific terms and conditions of the gift card issuer, as they may have different policies. You can usually find this information on the gift card itself, on the issuer's website, or by contacting their customer service.

If you're unsure about the validity of your gift card, I recommend reaching out to the issuer to confirm the expiration date.

Hope this helps, Joana!
ana@dev:~/obs$ python sent.py
post  run 01a1191b ask (chain)
        inputs: {"question": "Hi, I'm Joana Prado ([email]). How long is a gift card valid?"}
        extra: {"metadata": {"ls_method": "traceable"}}
post  run 01a1191b ChatOpenAI (llm)
        inputs: {"messages": "[{'role': 'user', 'content': \"Hi, I'm Joana Prado ([email]). How long is a gift card valid?\"}]
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ll
        serialized: {"name": "ChatOpenAI"}
patch run 01a1191b ask (chain)
        outputs: {"output": "Hello Joana!\n\nThe validity period of a gift card can vary depending on the issuer and the type o
        extra: {"metadata": {"ls_method": "traceable"}}
patch run 01a1191b ChatOpenAI (llm)
        outputs: {"id": "chatcmpl-883", "choices": "[{'finish_reason': 'stop', 'index': 0, 'logprobs': None, 'message': {'conte
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ll
```

The address is gone from the inputs, and the environment variables and runtime details from `extra`.
**Her name is not.** "Joana Prado" is still in the question, because lesson 2's patterns find what
has a shape and a name has none, and the model, given the name, used it: "Hello Joana!" opens the
reply that went out as well. Redacting the input does nothing for what the model writes back with
it.

Two more things are worth noticing. The hooks receive the inputs as a dictionary, and the simple `str(v)` in `ls_ask.py` turned
the list of messages into the text of a list, which a screen will show as a string rather than as
messages; a careful hook redacts inside the structure. And the model's own run kept its
`ls_model_name` and provider metadata, which is fine, and a reminder that **only an inspection of what
arrived** says what a setting covers.

This is the same pattern as lesson 2's exporter, offered by the vendor: redact in the process, before
anything is sent. Whether to trust a vendor's hook or one's own is a judgement; testing either with a
canary is not.
