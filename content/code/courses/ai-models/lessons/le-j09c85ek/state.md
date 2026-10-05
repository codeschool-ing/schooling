---
title: The conversation kept for you
version: 1
---

With Chat Completions a conversation is the client's job: every request carries every earlier
message, and the API remembers nothing. The Responses API can remember instead. The library's own
documentation of its parameters, which `lab/doc.py` prints from the installed package, says how:

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
ana@desk:~/desk$ python lab/doc.py previous_response_id instructions
previous_response_id: The unique ID of the previous response to the model. Use this to create
    multi-turn conversations. Learn more about
    [conversation state](https://developers.openai.com/api/docs/guides/conversation-state).
    Cannot be used in conjunction with `conversation`.
instructions: A system (or developer) message inserted into the model's context.

    When using along with `previous_response_id`, the instructions from a previous
    response will not be carried over to the next response. This makes it simple to
    swap out system (or developer) messages in new responses.
```

`lab/chain.py` sorts one case, then sends a second case as the next turn, once without the
instructions and once with them:

```python
import json

from openai import OpenAI

client = OpenAI()
prompt = open("prompts/triage.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

first = client.responses.create(model="standin-small", instructions=prompt, input=cases["c05"]["text"])
print("first: ", first.id, first.output_text, first.usage.input_tokens, "tokens in")

# the next turn sends only what is new, and the id of what came before
second = client.responses.create(model="standin-small", previous_response_id=first.id,
                                 input=cases["c12"]["text"])
print("second:", second.id, second.usage.input_tokens, "tokens in, instructions:", second.instructions)

third = client.responses.create(model="standin-small", previous_response_id=first.id,
                                instructions=prompt, input=cases["c12"]["text"])
print("third: ", third.id, third.output_text, third.usage.input_tokens, "tokens in")
```

```
ana@desk:~/desk$ python lab/chain.py
first:  resp_lab_0003 other 51 tokens in
second: resp_lab_0004 49 tokens in, instructions: None
third:  resp_lab_0005 refund. 85 tokens in
```

```
ana@desk:~/desk$ wire --body | head -9
{
  "model": "standin-small",
  "input": "The book arrived soaked from the rain and the cover is ruined. I don't want a replacement, just the refund. LB-20415",
  "instructions": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n",
  "previous_response_id": "resp_lab_0003"
}
```

The third request sent one e-mail and an id, and the model read 85 tokens: the first turn, its
answer, the instructions and the new e-mail. **The history travelled from OpenAI's side, not from
ana's.** The second request is the trap the documentation warns about: it read the history but not
the instructions, 49 tokens, because instructions are not carried over. A program that sets the
system prompt only on the first turn has a model with no instructions from the second turn on.

The stand-in's answer to the third is `refund.`, with a full stop, which is what its table has
`standin-small` write for that case; lesson 5 section 04's strict scoring would count it wrong and
the loose one right.

For ana's sorting, where every e-mail is a fresh question, there is no conversation to keep, and
nothing here is needed. It matters for a reply drafted over several turns, and there the saving is
in what the client sends, not in what is billed: the model still reads the whole history, and
`input_tokens` counts it every time.
