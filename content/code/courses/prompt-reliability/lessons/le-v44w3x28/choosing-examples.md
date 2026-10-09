---
title: Choosing the examples
version: 2
---

Three examples fixed seven replies and broke one. That broken message is the best place to start,
because **an example teaches more than you put in it on purpose**:

```
ana@lab:~/triage$ pl show runs/v2.jsonl t01
│ {"category": "billing", "urgency": "high", "summary": "Refund duplicate payment for order 4471"}
stop: stop, tokens in 108, out 28, 3.8 s
ana@lab:~/triage$ pl show runs/v3.jsonl t01
│ {"category": "billing", "urgency": "normal", "summary": "Wants a refund for the second payment of order 4471."}
stop: stop, tokens in 250, out 33, 4.9 s
```

`t01` is a customer charged twice, and the person who labelled it called that `high`: somebody's
money is gone. Without examples the model agreed. With them it says `normal`. Look at the first
example: *"I paid for express delivery but the order came by normal post"*, a billing message,
about a refund, labelled `normal`. `t01` is also a billing message about a refund, and the model
gave it the urgency of the example it most resembles. **An example pulls the messages that look like
it towards its own labels**, and nobody can tell you beforehand which resemblance the model will
notice: here it was the topic, and it could as easily have been a word.

So choosing examples is choosing what the model will generalise from. Four rules carry most of it.

## Cover the boundaries, not the centre

An example of an obvious case teaches the format and little else; the model would have sorted
*"I can't log in"* correctly anyway. **The examples worth their tokens sit where two labels
meet**: a refund for a returned book (returns, not billing), a parcel that arrived soaked (returns,
not delivery), a charge for a delivery upgrade that never happened (billing, not delivery). The
first example is one of those, and `t01` shows that a boundary example needs a neighbour on the
other side: a billing message that IS urgent, labelled `high`, or the line moves too far.

## Take them from real traffic

An invented example is cleaner than anything a customer writes: one sentence, one problem, no
greeting. A model shown only clean examples has learnt nothing about the message that opens with
three lines of apology and asks two questions. Pick examples out of the messages you have, after
removing names and order numbers, and **keep them out of the test set**. An example that is also a
test case is answered by copying, and lesson 11 shows how far that inflates a score.

## Balance the labels

Every example adds some pull towards its own labels, whatever it says. These three are two
`normal` and one `low`, and not one `high`; five examples of billing and one of delivery would tilt
every close call towards billing the same way. Lesson 18 measures how far that moves the answers.

## Count what they cost

Examples are paid for on every call, because they are part of every prompt. `pl show` prints the
tokens that went in, and `t01` went in twice above: 108 tokens without the examples and 250 with
them. **The three examples more than doubled the input of every call**, and a model reads every
token it is given before it writes the first word of its reply, which on a processor is time you
wait. That was worth it here: seven replies fixed and one broken, six in forty. A fourth example has
to earn its place the same way, with a count of what it fixed. Lesson 16 does the arithmetic of what
each token costs, and lesson 17 shows how a cache makes the fixed part of a prompt cheaper.