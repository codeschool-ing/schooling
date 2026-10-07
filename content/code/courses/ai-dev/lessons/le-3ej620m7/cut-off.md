---
title: When the reply is cut off
version: 1
---

A reply ends for one of a few reasons, and the response says which in **`stop_reason`**. The two
you meet in every application are `end_turn`, where the model decided it had finished, and
`max_tokens`, where it had not and ran out of the room the request gave it. **A reply that stopped
at `max_tokens` is unfinished**, and the most common bug in code around a model is treating it as
if it were not.

## The same question with too little room

`lab/cutoff.py` asks `scripted-1` to explain the shop's shipping rule and prints why it stopped.
The explanation is text written by the course; the cut is labllm's, made at exactly the number of
tokens the request allowed:

```python
import sys

import anthropic

client = anthropic.Anthropic()
r = client.messages.create(model="scripted-1", max_tokens=int(sys.argv[1]),
                           messages=[{"role": "user", "content": "Explain the shop's shipping rule."}])
print(f"stop_reason={r.stop_reason} output_tokens={r.usage.output_tokens}")
print(r.content[0].text)
if r.stop_reason == "max_tokens":
    print("!! the reply was cut off; do not use it as if it were complete")
```

```
ana@dev:~/shop$ python lab/cutoff.py 40
stop_reason=max_tokens output_tokens=40
The cart charges a flat 15.00 for shipping, and nothing at all once the order reaches 200.00. The threshold is checked after the discount, not before it: a cart of
!! the reply was cut off; do not use it as if it were complete
ana@dev:~/shop$ python lab/cutoff.py 300
stop_reason=end_turn output_tokens=147
The cart charges a flat 15.00 for shipping, and nothing at all once the order reaches 200.00. The threshold is checked after the discount, not before it: a cart of 210.00 with a 10% coupon comes to 189.00 and pays shipping again. Every amount is held in integer cents, so 15.00 is the constant SHIPPING = 1500 and 200.00 is FREE_SHIPPING_FROM = 20000, both in shop/cart.py. The rule lives in Cart.shipping(), which Cart.total() calls after subtracting the discount. If you change the threshold, test_free_shipping_from_200 in tests/test_cart.py is the test that should change with it.
```

Forty tokens ends in the middle of a sentence: *a cart of*. Here the cut is obvious because a
person can read it. It stops being obvious when the reply is meant for a program. **JSON cut off at
`max_tokens` is not JSON**, a list cut off is a shorter list that looks complete, and code cut off
can still be valid code that is missing its last branch. Only `stop_reason` tells them apart.

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

`stop_sequences` ends the reply early, at a string you choose, and reports it:

```
ana@dev:~/shop$ python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model="tiny-1", max_tokens=60, stop_sequences=["\n\n"], messages=[{"role": "user", "content": "Return the"}]); print(r.stop_reason, repr(r.stop_sequence)); print(repr(r.content[0].text))'
stop_sequence '\n\n'
' number of data.\nmode                Mode (most common values of data.\nstdev               Sample standard deviation.'
```

`stop_reason` is `stop_sequence`, `stop_sequence` names which one matched, and the sequence itself
is not in the text. A stop sequence is useful when the output has a natural end marker, such as a
closing tag you asked for, and is cheaper than letting the model write past it and trimming the
rest.

The other values of `stop_reason` belong to later lessons: `tool_use`, where the model stopped to
ask for a tool (lesson 8), and `refusal`, which some providers use when a safety system ended the
reply. **Handle every value you know and fail loudly on any you do not**, because the list grows
with every new API version.
