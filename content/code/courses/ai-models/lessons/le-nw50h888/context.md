---
title: The window you did not set
version: 1
---

Lesson 4 section 07 compared models by the context window their makers publish. A local server
adds a second number, the window **it** gives the model, and that one is a setting:

```
# ollama/ollama@42e911bc docs/faq.mdx
  25: By default, Ollama uses a context window size of 4096 tokens.
```

Four thousand tokens, whatever the model was trained for. A conversation longer than that does not
fail. `context.py` sends the triage prompt, thirty-nine of ana's cases as worked examples (each
e-mail and the label a person gave it), and the fortieth as the question, three times, with three
values of `num_ctx`:

```python
import json

import ollama

prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

# every other case as a worked example, then the last one as the question
messages = [{"role": "system", "content": prompt}]
for c in cases[:39]:
    messages += [{"role": "user", "content": c["text"]}, {"role": "assistant", "content": c["label"]}]
messages.append({"role": "user", "content": cases[39]["text"]})

for num_ctx in (None, 1024, 512):
    options = {"temperature": 0} | ({"num_ctx": num_ctx} if num_ctx else {})
    r = ollama.chat(model="llama3.2:3b", messages=messages, options=options)
    print(f"num_ctx {num_ctx or 'unset':>5}: sent {len(messages)} messages, "
          f"the model read {r.prompt_eval_count:>4} tokens -> {r.message.content}")
```

```
ana@desk:~/desk$ python context.py
num_ctx unset: sent 80 messages, the model read 1319 tokens -> order-status
num_ctx  1024: sent 80 messages, the model read 1014 tokens -> order-status
num_ctx   512: sent 80 messages, the model read  505 tokens -> order-status
```

Unset, the 1,319 tokens fit in the default and the model read all of them. At 1,024 and 512 it
read less, and **the answer came back as if nothing had happened**: a label, a 200, no warning.
Ollama dropped some of the messages to make it fit, and the reply does not say which: the examples
that were supposed to teach the model the labels were partly not there.

The defence is the number the response already carries. **`prompt_eval_count` is what the model
read**, counted by the server with the model's own tokenizer. Compare it with the same request at
a window known to be large enough, as the first line does: if it falls short, something was cut.

And remember the price: lesson 3 section 03 showed that the cache grows with every token of
context, so a bigger `num_ctx` is more memory, and Ollama's documentation adds that parallel
requests multiply it.
