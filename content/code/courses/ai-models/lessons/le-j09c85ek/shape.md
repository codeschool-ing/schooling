---
title: Instructions in, items out
version: 1
---

The Responses API lives beside Chat Completions at the same address, with the same key and the same
SDK, and lesson 8 section 05 left the choice between them open. api.openai.com was refused by the
network of the machine this course was recorded on, and Ollama answers in this shape too, so the
answers in this lesson are llama3.2:3b's. What the lesson is about is the shape, and what OpenAI's
own library documents; where Ollama does something else, the lesson says so, and that difference is
worth knowing for its own sake.

Every program in this lesson runs through the relay from lesson 9 section 03, so that what the
library sends can be read back. Start the relay in a second terminal, and in the one you work in,
send both libraries to it:

```
ana@desk:~/desk$ export OPENAI_BASE_URL=http://127.0.0.1:8500/v1 ANTHROPIC_BASE_URL=http://127.0.0.1:8500
```

`resp_sort.py` sorts one of ana's cases with the Responses API:

```python
import json

from openai import OpenAI

client = OpenAI()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = client.responses.create(model="llama3.2:3b", instructions=prompt, input=case["text"])
print(r.output_text)
print([item.type for item in r.output], [part.type for part in r.output[0].content])
print(r.usage.input_tokens, "in,", r.usage.output_tokens, "out, of which reasoning:",
      r.usage.output_tokens_details.reasoning_tokens)
```

```
ana@desk:~/desk$ python resp_sort.py
other.
['message'] ['output_text']
75 in, 3 out, of which reasoning: 0
ana@desk:~/desk$ python relay.py show --body
{
  "model": "llama3.2:3b",
  "input": "Do you have a physical shop I can visit in Curitiba?",
  "instructions": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
}
```

The request is what the real library sent, and the shape is the point:

| | Chat Completions | Responses |
|---|---|---|
| the system prompt | a message with role `system` | `instructions` |
| what to answer | `messages`, a list | `input`, a string or a list of items |
| the answer | `choices[0].message.content` | `output`, a list of typed items; `output_text` joins their text |
| tokens | `prompt_tokens`, `completion_tokens` | `input_tokens`, `output_tokens` |

`output` is a list because a response can hold more than one kind of item: a message, a reasoning
summary, a call to a tool. `output_text` is a convenience of the SDK that joins the text parts, and
it is what most programs need. The usage separates **reasoning tokens** from the visible ones,
lesson 8 section 03's hidden thinking, which is billed as output and here is zero.

None of that changes what ana's harness measures. It changes the code that reads the reply, which is
why a program written against one shape does not run against the other without edits.
