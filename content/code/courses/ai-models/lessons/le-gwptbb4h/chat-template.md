---
title: The string the model actually reads
version: 1
---

A chat API takes a list of messages, each with a role. The network inside takes none of that. It
reads **one sequence of tokens**, and the roles have to be written into that sequence somehow. The
convention for writing them is the **chat template**, and every model family has its own.

Meta publishes Llama 3.1's in the same document. `template.py` follows it to the letter and
renders ana's sorting prompt and the first e-mail in `cases/triage.jsonl`:

```python
import json


def render(messages):
    """A conversation as Llama 3.1 reads it, from Meta's prompt_format.md."""
    out = "<|begin_of_text|>"
    for m in messages:
        out += f"<|start_header_id|>{m['role']}<|end_header_id|>\n\n{m['content']}<|eot_id|>"
    return out + "<|start_header_id|>assistant<|end_header_id|>\n\n"


case = json.loads(open("cases/triage.jsonl").readline())
print(render([{"role": "system", "content": open("prompts/triage.txt").read().strip()},
              {"role": "user", "content": case["text"]}]))
```

```
ana@desk:~/desk$ python template.py
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You sort the e-mail of Lantern Books, an online bookshop.
Answer with exactly one label and nothing else:
order-status, refund, address-change, product-question, other.<|eot_id|><|start_header_id|>user<|end_header_id|>

Hi, I ordered two books on Monday (order LB-20417) and the tracking page still says 'preparing'. When will it ship?<|eot_id|><|start_header_id|>assistant<|end_header_id|>
```

That is the whole trick behind a chat. Each turn is fenced by special tokens naming its role, and
the string **ends with the header of an assistant turn that has no content yet**. The model's only
skill is continuing text, so it continues by writing the assistant's turn, and the tuning from
section 07 makes it close that turn with `<|eot_id|>`.

## Why you should know this when an API hides it

Through an API you never see this string, and that is fine most of the time. It matters in three
places:

- **Running an open model yourself.** The template lives beside the weights, in the tokenizer's
  configuration. Tools such as Ollama (lesson 14) apply it for you; a hand-rolled script that
  skips it sends the model plain text, and a tuned model given no turn markers behaves much like
  a base model.
- **Moving a prompt between families.** Two models may read the same messages through different
  templates. That is one reason a prompt tuned for one model is not automatically right for
  another, and why lesson 5 evaluates each candidate on the same cases rather than trusting a
  prompt to transfer.
- **The system prompt is not magic.** It is text in the same sequence, under a header that says
  `system`. The model was trained to give it weight; nothing enforces that weight.

**The roles are a convention the model learnt**, written in tokens. Different families learnt
different conventions, and an API spares you from writing them, not from their existence.
