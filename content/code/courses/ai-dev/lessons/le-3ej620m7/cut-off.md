---
title: When the reply is cut off
version: 2
---

A reply ends for one of a few reasons, and the response says which in **`stop_reason`**. The two
you meet in every application are `end_turn`, where the model decided it had finished, and
`max_tokens`, where it had not and ran out of the room the request gave it. **A reply that stopped
at `max_tokens` is unfinished**, and the most common bug in code around a model is treating it as
if it were not.

## The same question with too little room

`~/shop/scratch/cutoff.py` sends the cart's code as the system prompt, asks the model to explain the
shipping rule, and prints why it stopped:

```python
import sys

import anthropic

client = anthropic.Anthropic()
r = client.messages.create(model="llama3.2:3b", max_tokens=int(sys.argv[1]),
                           system=open("shop/cart.py").read(),
                           messages=[{"role": "user", "content": "Explain the shop's shipping rule."}])
print(f"stop_reason={r.stop_reason} output_tokens={r.usage.output_tokens}")
print(r.content[0].text)
if r.stop_reason == "max_tokens":
    print("!! the reply was cut off; do not use it as if it were complete")
```

```
ana@dev:~/shop$ python scratch/cutoff.py 40
ana@dev:~/shop$ python scratch/cutoff.py 400
```

Forty tokens ends in the middle of a sentence: *If the order's subtotal*. Here the cut is obvious because a person
can read it. It stops being obvious when the reply is meant for a program. **JSON cut off at
`max_tokens` is not JSON**, a list cut off is a shorter list that looks complete, and code cut off
can still be valid code that is missing its last branch. Only `stop_reason` tells them apart.

**And read the complete answer before you trust it.** It ended on its own, `end_turn`, and it is
wrong twice: 20,000 cents is 200.00 and not "$20", and shipping is a flat 15.00, not "$1.50 per
unit". The whole of `cart.py` was in the request. A reply that is complete is not a reply that is
right, and lesson 4 is about checking.

## What to do with `max_tokens`

Decide per call site, and write the decision down:

- **Give the reply room.** `max_tokens` is a ceiling, not a target: you pay for the tokens the
  model writes, not for the room you allowed. A ceiling a little above the longest reply you
  expect costs nothing extra on the replies that are shorter.
- **Treat `max_tokens` as an error where completeness matters.** A structured reply (lesson 8)
  that stopped there is a failed call: retry with more room or report the failure, never parse it.
- **Continue, where the text is prose.** Send the partial reply back as the start of the
  assistant's turn and ask for the rest. It works because the model will continue from whatever
  text it is given, which lesson 1 section 06 made the definition of a model.

## Stopping on purpose

`stop_sequences` ends the reply early, at a string you choose. Here the model is asked for a list
of five and stopped at the third item's number:

```
ana@dev:~/shop$ python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=80, stop_sequences=["3."], messages=[{"role": "user", "content": "Write a numbered list of five fruits."}]); print(r.stop_reason, repr(r.stop_sequence)); print(repr(r.content[0].text))'
```

The text stopped where it should, and the sequence itself is not in it. **But `stop_reason` says
`end_turn` and `stop_sequence` is `None`.** Anthropic's API would report `stop_sequence` and name
the string that matched; Ollama's copy of the format stops at the string and reports the stop as if
the model had finished on its own. A compatible API is compatible until a detail like this one,
and it is why code that branches on `stop_reason` deserves a test against the provider it will
really run on. A stop sequence is useful when the output has a natural end marker, such as a
closing tag you asked for, and is cheaper than letting the model write past it and trimming the
rest.

The other values of `stop_reason` belong to later lessons: `tool_use`, where the model stopped to
ask for a tool (lesson 8), and `refusal`, which some providers use when a safety system ended the
reply. **Handle every value you know and fail loudly on any you do not**, because the list grows
with every new API version.
