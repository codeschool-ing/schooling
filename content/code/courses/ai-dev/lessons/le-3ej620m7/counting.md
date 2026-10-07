---
title: Counting before you send
version: 2
---

To know whether a request fits, and what it will cost, you need its token count **before** it
goes. Lesson 1 section 07 showed that a count belongs to a tokenizer, and that of the three
providers only OpenAI publishes its tokenizers. So there are two ways to count, and they answer slightly different
questions:

- **locally, with a tokenizer library**: fast, free, offline, and exact only for the models that
  tokenizer belongs to;
- **by asking whoever runs the model**: Anthropic's `count_tokens` endpoint takes the same body as
  a request and returns the number the bill will use, without generating anything, and Google's
  API has a counting call too. They cost a network round trip, and counting calls have rate limits
  of their own. **Ollama has no such endpoint.** The way to ask it is to send the request with
  `max_tokens=1` and read `usage`, which costs one generated token: nothing on your own machine,
  and the price of a token on a provider that has a counting call you should use instead.

## The difference is not only the tokenizer

`~/shop/scratch/count.py` counts one question with `tiktoken`, then asks Ollama about the same
question three ways: alone, with the project's `CONVENTIONS.md` as the system prompt, and with one
tool definition.

```python
import anthropic
import tiktoken

client = anthropic.Anthropic()
enc = tiktoken.get_encoding("o200k_base")
question = "Why does a 210.00 cart with WELCOME10 pay shipping?"
system = open("CONVENTIONS.md").read()
tool = {"name": "get_cart", "description": "Read a customer's cart by its id.",
        "input_schema": {"type": "object", "properties": {"cart_id": {"type": "string"}},
                         "required": ["cart_id"]}}
cases = [("question only", {}),
         ("with the conventions as system prompt", {"system": system}),
         ("with one tool definition", {"tools": [tool]})]
print(f"tiktoken on the question alone: {len(enc.encode(question))}")
for label, extra in cases:
    r = client.messages.create(model="llama3.2:3b", max_tokens=1,
                               messages=[{"role": "user", "content": question}], **extra)
    print(f"{r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0):5}  {label}")
```

```
ana@dev:~/shop$ python scratch/count.py
tiktoken on the question alone: 15
   40  question only
  418  with the conventions as system prompt
  168  with one tool definition
```

`tiktoken` says 15 and the model read 40 for the same question. Part of the gap is the
tokenizer, since `o200k_base` is OpenAI's and this model's is Meta's. Most of it is **the wrapping
around the message**, which the model reads and the bill counts. Ollama will show it: every model
carries a **chat template**, the text that turns a list of messages into the one string the model
continues.

```
ana@dev:~/shop$ ollama show llama3.2:3b --template | head -n 12
<|start_header_id|>system<|end_header_id|>

Cutting Knowledge Date: December 2023

{{ if .System }}{{ .System }}
{{- end }}
{{- if .Tools }}When you receive a tool call response, use the output to format an answer to the orginal user question.

You are a helpful assistant with tool calling capabilities.
{{- end }}<|eot_id|>
{{- range $i, $_ := .Messages }}
{{- $last := eq (len (slice $.Messages $i)) 1 }}
```

The headers that mark who is speaking are tokens. So is a line nobody asked for, `Cutting
Knowledge Date: December 2023`, which this template writes into every request: the model's
training cutoff, from lesson 1 section 11, stated to the model on every turn. Real providers wrap
messages the same way, they do not publish exactly how, and that is why **the count from whoever
runs the model is the one to trust**. Counting the text yourself gives a good estimate of the
text and misses the wrapping.

The other two lines are the ones that surprise people:

- **The system prompt is paid for on every request.** 378 more tokens for `CONVENTIONS.md`,
  which is a page of text, on every question anybody asks. Lesson 2 section 07 shows how to pay
  less for a system prompt that never changes.
- **Tools are text too.** One tool with one parameter added 128 tokens: its name, its
  description and its JSON schema are written into the prompt, and the template above adds a
  paragraph of instructions about how to call it. An agent with thirty tools (lesson 7) can spend
  thousands of tokens describing them before the conversation starts.

## Where counting goes in code

Count once, in the function that sends the request, and keep the number:

- **before sending**, to refuse a request that will not fit or is over a budget (lesson 2 section
  09);
- **after the reply**, read `usage` from the response rather than counting again. It is the
  provider's own figure for what was billed, including the output, which nothing could count in
  advance.

```python
r = client.messages.create(model=model, max_tokens=300, messages=messages)
log.info("tokens", extra={"in": r.usage.input_tokens, "out": r.usage.output_tokens})
```

**Log `usage` on every call from the first day.** When the bill arrives, the question is which
feature spent it, and the only data that answers it is the usage you recorded per request.
