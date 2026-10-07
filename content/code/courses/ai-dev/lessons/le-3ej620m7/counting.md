---
title: Counting before you send
version: 1
---

To know whether a request fits, and what it will cost, you need its token count **before** it
goes. Lesson 1 section 07 showed that a count belongs to a tokenizer, and that only OpenAI
publishes its tokenizers. So there are two ways to count, and they answer slightly different
questions:

- **locally, with a tokenizer library**: fast, free, offline, and exact only for the models that
  tokenizer belongs to;
- **by asking the provider**: Anthropic's `count_tokens` endpoint takes the same body as a
  request and returns the number the bill will use, without generating anything. Google's API has
  a counting call too. It costs a network round trip, and counting calls have rate limits of
  their own.

## The difference is not only the tokenizer

`lab/count.py` counts one question with `tiktoken`, then asks labllm's counting endpoint about the
same question three ways: alone, with the project's `CONVENTIONS.md` as the system prompt, and
with one tool definition.

```
ana@dev:~/shop$ python lab/count.py
tiktoken on the question alone: 15
   18  question only
  392  with the conventions as system prompt
   71  with one tool definition
```

labllm uses the same encoding as `tiktoken`, and the answers still differ by 3. That is the
overhead labllm adds per message, its stand-in for the role markers and separators a real API
wraps around each message before the model reads it. Real providers have overheads like that,
they are not documented, and they are why **the provider's count is the one to trust**. Counting
the text yourself gives a good estimate of the text and misses the wrapping.

The other two lines are the ones that surprise people:

- **The system prompt is paid for on every request.** 374 more tokens for `CONVENTIONS.md`,
  which is a page of text, on every question anybody asks. Lesson 2 section 07 shows how to pay
  less for a system prompt that never changes.
- **Tools are text too.** One tool with one parameter added 53 tokens: its name, its description
  and its JSON schema are all serialised into the prompt. An agent with thirty tools (lesson 7)
  can spend thousands of tokens describing them before the conversation starts.

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
