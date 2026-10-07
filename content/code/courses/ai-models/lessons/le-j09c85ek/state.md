---
title: The conversation kept for you
version: 1
---

With Chat Completions a conversation is the client's job: every request carries every earlier
message, and the API remembers nothing. The Responses API can remember instead. The library's own
documentation of its parameters, which `doc.py` prints from the installed package, says how:

```python
import re
import sys

import openai.resources.responses.responses as module

# the docstring of Responses.create, as the installed library carries it
source = open(module.__file__).read()
for name in sys.argv[1:]:
    m = re.search(rf"^ {{10}}{name}: .*?(?=\n\n {{10}}\w+: )", source, re.S | re.M)
    print(re.sub(r"(?m)^ {10}", "", m.group(0)) if m else f"{name}: not documented")
```

```
ana@desk:~/desk$ python doc.py previous_response_id instructions
previous_response_id: The unique ID of the previous response to the model. Use this to create
    multi-turn conversations. Learn more about
    [conversation state](https://developers.openai.com/api/docs/guides/conversation-state).
    Cannot be used in conjunction with `conversation`.
instructions: A system (or developer) message inserted into the model's context.

    When using along with `previous_response_id`, the instructions from a previous
    response will not be carried over to the next response. This makes it simple to
    swap out system (or developer) messages in new responses.
```

`chain.py` sorts one case, then sends a second case as the next turn, once without the
instructions and once with them:

```python
import json

from openai import OpenAI

client = OpenAI()
prompt = open("prompts/triage.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

first = client.responses.create(model="llama3.2:3b", instructions=prompt, input=cases["c05"]["text"])
print("first: ", first.id, first.output_text, first.usage.input_tokens, "tokens in")

# the next turn sends only what is new, and the id of what came before
second = client.responses.create(model="llama3.2:3b", previous_response_id=first.id,
                                 input=cases["c12"]["text"])
print("second:", second.id, second.usage.input_tokens, "tokens in, instructions:", second.instructions)

third = client.responses.create(model="llama3.2:3b", previous_response_id=first.id,
                                instructions=prompt, input=cases["c12"]["text"])
print("third: ", third.id, third.output_text, third.usage.input_tokens, "tokens in")
```

```
ana@desk:~/desk$ python chain.py
first:  resp_884996 order-status, other. 75 tokens in
second: resp_100132 53 tokens in, instructions: None
third:  resp_719864 refund 89 tokens in
```

```
ana@desk:~/desk$ python relay.py show --body | head -6
{
  "model": "llama3.2:3b",
  "input": "The book arrived soaked from the rain and the cover is ruined. I don't want a replacement, just the refund. LB-20415",
  "instructions": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n",
  "previous_response_id": "resp_884996"
}
```

The third request sent one e-mail and an id, and the relay shows the id went with it. The model
read 89 tokens. Against OpenAI, the docstring above says what that id is for: the server finds the
first turn and its answer and puts them in front of the new e-mail, so **the history travels from
the provider's side, not from ana's**. Here it did not travel at all. The first request, with the
instructions and one e-mail, was 75 tokens; the third, with the instructions and a different
e-mail, is 89, which is about the size of that request alone. **Ollama accepted
`previous_response_id` and ignored it**, and the answer gave no sign of it.

The second request is the trap the documentation warns about, and that one shows on any server: it
sent no instructions, and `instructions` came back `None`, because instructions are not carried
over. A program that sets the system prompt only on the first turn has a model with no instructions
from the second turn on.

For ana's sorting, where every e-mail is a fresh question, there is no conversation to keep, and
nothing here is needed. It matters for a reply drafted over several turns, and there the saving is
in what the client sends, not in what is billed: the model still reads the whole history, and
`input_tokens` counts it every time. And it is the clearest case in this course of lesson 20's
subject: **a server that accepts a request is not a server that honours every field in it.**
