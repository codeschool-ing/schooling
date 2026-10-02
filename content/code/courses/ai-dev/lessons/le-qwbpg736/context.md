---
title: The context is all it has
version: 1
---

A chat window gives the impression that the model remembers the conversation. **It does not.**
The model reads only what one request puts in front of it, and when the reply has been written,
nothing of that request is left inside the model for the next one. What looks like memory is the
application sending the whole conversation again, every turn. Some APIs offer to keep the
history on the provider's side and refer to it by an id (OpenAI's Responses API does); that moves
where the list is stored, and the model still reads all of it, and you are still billed for it,
on every turn.

That text, everything the model reads before it writes, is the **context**. Generation in lesson
1 section 02 was a loop over the context; this section is about what goes into it.

## What a conversation really sends

`lab/turns.py` builds a three-turn conversation the way every chat application does, by appending
to a list, and asks labllm how many input tokens each request would carry. It uses the
`anthropic` SDK, the same code that would talk to Anthropic's API; in the lab the SDK is pointed
at labllm, lesson 1 section 08 shows how.

```python
import anthropic

client = anthropic.Anthropic()
history = []
for question in ["My cart has three mugs.", "Add a lamp to it.", "How many items are in it now?"]:
    history.append({"role": "user", "content": question})
    n = client.messages.count_tokens(model="tiny-1", messages=history).input_tokens
    print(f"turn {len(history) // 2 + 1}: {len(history)} messages, {n} input tokens")
    history.append({"role": "assistant", "content": "(the reply would go here)"})
```

```
ana@dev:~/shop$ python lab/turns.py
turn 1: 1 messages, 9 input tokens
turn 2: 3 messages, 27 input tokens
turn 3: 5 messages, 47 input tokens
```

And this is what the third request carried, read from labllm's own log of what it received:

```
ana@dev:~/shop$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(m["role"], "|", m["content"]) for m in json.load(sys.stdin)["request"]["messages"]]'
user | My cart has three mugs.
assistant | (the reply would go here)
user | Add a lamp to it.
assistant | (the reply would go here)
user | How many items are in it now?
```

**To answer "how many items", the model needs the first message**, and the only way it gets it is
by being sent it again. Drop the history and the third question arrives alone, about a cart the
model has never heard of. Each turn re-sends everything before it, so the tokens you pay for grow
with every exchange. Lesson 2 measures how fast.

## What else lives in the context

A request usually carries more than the conversation:

- a **system prompt**, the standing instructions: who the model is acting as, what it may and
  may not do, what format to answer in;
- **documents** the application chose to include, such as a file from your editor (lesson 3) or
  passages found by search (lesson 6);
- **tool definitions** and the results of the tools the model asked for (lessons 7 and 8).

All of it is text, all of it is counted in tokens, and all of it shares one limit, the **context
window**, with the reply the model is about to write. Lesson 2 is about that limit.

## The working rule

**If it is not in the request, the model does not know it.** It does not see the rest of your
repository, the ticket you are working on, the version of the library you installed, or what you
told it yesterday in another tab. When an assistant answers as though it knew those things, it
is either because a tool put them in the context without you noticing (lesson 3 shows
what an editor gathers) or because it guessed, and lesson 1 section 07 is about guessing.
