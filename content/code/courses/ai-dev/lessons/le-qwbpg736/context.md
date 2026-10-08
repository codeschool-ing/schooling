---
title: The context is all it has
version: 2
---

A chat window gives the impression that the model remembers the conversation. **It does not.**
The model reads only what one request puts in front of it, and when the reply has been written,
nothing of that request is left inside the model for the next one. What looks like memory is the
application sending the whole conversation again, every turn. Some APIs offer to keep the
history on the provider's side and refer to it by an id (OpenAI's Responses API does). That moves
where the list is stored. The model still reads all of it, and you are still billed for it, on
every turn.

That text, everything the model reads before it writes, is the **context**. Generation in section
06 was a loop over the context; this section is about what goes into it.

## What a conversation really sends

`~/shop/scratch/turns.py` holds a three-turn conversation the way every chat application does, by
appending to a list, and sends the whole list each turn. It uses the `anthropic` SDK, the same code
that would talk to Anthropic's API; section 03 pointed it at Ollama.

```python
import anthropic

client = anthropic.Anthropic()
history = []
for question in ["My cart has three mugs.", "Add a lamp to it.", "How many items are in it now?"]:
    history.append({"role": "user", "content": question})
    r = client.messages.create(model="llama3.2:3b", max_tokens=60, system="Answer in one short sentence.",
                               messages=history)
    reply = r.content[0].text
    sent = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
    print(f"turn {len(history) // 2 + 1}: {len(history)} messages, {sent} input tokens")
    print(f"  {reply}")
    history.append({"role": "assistant", "content": reply})

print("what the third request carried:")
for message in history[:-1]:
    print(f"  {message['role']:9} | {message['content']}")
```

The `system` prompt asks for short answers, which keeps the transcript readable; the next part of
this section says what a system prompt is. Ollama reports part of each request's input as
`cache_read_input_tokens`, the part it had already read on the previous turn, and lesson 2 explains
that field, so the program adds the two to get everything the request carried.

```
ana@dev:~/shop$ python scratch/turns.py
turn 1: 1 messages, 38 input tokens
  You currently have a total of three items in your cart.
turn 2: 3 messages, 66 input tokens
  Your cart now has four items: three mugs and a lamp.
turn 3: 5 messages, 98 input tokens
  There are five items in your cart now.
what the third request carried:
  user      | My cart has three mugs.
  assistant | You currently have a total of three items in your cart.
  user      | Add a lamp to it.
  assistant | Your cart now has four items: three mugs and a lamp.
  user      | How many items are in it now?
```

**To answer the third question, the model needs the first two exchanges**, and the only way it
gets them is by being sent them again. Here is the third question sent alone:

```
ana@dev:~/shop$ ollama run llama3.2:3b "How many items are in it now?"
I don't have have any information about an "it" to know how many items are
in it. Could you please provide more context or clarify what you are
referring to? I'll do my best to help.
```

It has never heard of the cart. Each turn re-sends everything before it, so the tokens you pay for
grow with every exchange: 38, 66, 98 here, for questions of a few words each. Lesson 2 measures
how fast.

**And look at the third answer in the conversation.** The model was sent "three items" and
"four items: three mugs and a lamp", and answered *five*. Having the facts in the context makes a
right answer likely; it does not make it certain, and nothing in the reply says which one you
got. Run it yourself and you may well get *four*, or *five*, or something else, since section 08
showed that every reply is drawn at random. Section 11 is about that gap.

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
what an editor gathers) or because it guessed, and section 11 is about guessing.
