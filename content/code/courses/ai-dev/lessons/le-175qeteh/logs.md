---
title: The log is a copy too
version: 2
---

Every request worth making is worth logging: which model, how many tokens, why it stopped, so the
bill and the incidents can be explained later. **A log that keeps the prompt keeps a copy of
everything in it**, for as long as the logs are kept, readable by everyone who can read logs.

```python
"""A log line for every request: enough to answer for it, nothing that repeats the customer."""
import hashlib
import json
import logging

import anthropic

log = logging.getLogger("llm")


def ask(messages, **kw):
    r = anthropic.Anthropic().messages.create(messages=messages, **kw)
    text = json.dumps(messages, sort_keys=True).encode()
    tokens_in = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)  # lesson 2 section 07
    log.info(json.dumps({"id": r.id, "model": r.model, "in": tokens_in,
                         "out": r.usage.output_tokens, "stop": r.stop_reason,
                         "prompt_sha256": hashlib.sha256(text).hexdigest()[:16]}))
    return r
```

`triage_logged.py` is `triage.py` with the redaction always on and the request going through
`ask`:

```python
import logging
import sys
from pathlib import Path

from logged import ask
from redact import redact

logging.basicConfig(level=logging.INFO, format="%(name)s %(message)s")
email = redact(Path(sys.argv[1]).read_text())
r = ask([{"role": "user", "content": email}], model="llama3.2:3b", max_tokens=300, extra_body={"temperature": 0})
print(r.content[0].text)
```

```
ana@dev:~/shop$ python triage_logged.py data/emails/3.txt
httpx2 HTTP Request: POST http://127.0.0.1:11434/v1/messages "HTTP/1.1 200 OK"
llm {"id": "msg_b0044b053018d471d1681446", "model": "llama3.2:3b", "in": 62, "out": 67, "stop": "end_turn", "prompt_sha256": "d879892869f999c0"}
I can't assist with providing a response that includes sensitive information such as your card number, CPF, or email address. If you've encountered a payment failure with code E1042, I can help you understand the general causes of this error and offer guidance on how to resolve it. Would you like to know more about that?
```

The `llm` line says what happened and nothing the customer wrote, not even the labels. **The request id joins it to the
provider's own records**; the tokens explain the bill; the hash says whether two requests had the
same prompt, which is enough to find a repeat or a loop, without keeping the prompt.

## The line nobody asked for

The first line came from the HTTP library inside the SDK. **`basicConfig(level=logging.INFO)`
turned on every library's information messages, not only yours**, and this one logs every URL it
calls. Here that is harmless; a library that logged request bodies at the same level would put the
customer's email back in the log through a door you did not know was open.

- **Set levels per logger**: `logging.getLogger("llm").setLevel(logging.INFO)` for your own,
  warnings only for the rest.
- **Read a day of real logs** after any change to logging, looking for what should not be there.

## When you do need the content

Debugging a bad answer sometimes needs the prompt. **Keep it somewhere else**: a separate store,
with a short retention, read by fewer people, written only for the requests you choose, and
redacted as in lesson 11 section 03 before it is written.
