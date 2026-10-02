---
title: Choosing the examples
version: 1
---

Three examples fixed the format of forty replies and broke one category. That broken message is
the best place to start, because **an example teaches more than you put in it on purpose**:

```
ana@lab:~/triage$ grep t37 cases/dev.jsonl
{"id": "t37", "message": "The book I ordered says 'in stock' but my order still says 'awaiting dispatch' after a week.", "expect": {"category": "delivery", "urgency": "normal"}}
ana@lab:~/triage$ pl show runs/v3.jsonl t37
│ {"category": "billing", "urgency": "normal", "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week."}
stop: end, tokens in 246, out 46
```

`t37` is a late order, and the prompt without examples sorted it as delivery. With examples it
says billing. The first example is about delivery too, *"I paid for express delivery but the
order came by normal post"*, and it is labelled billing because the customer wants money back.
The two messages share `order`, and in the stand-in **an example pulls the messages that look like
it towards its own label**. Real models are pulled the same way, by surface likeness as well as by
meaning, and nobody can tell you beforehand which surface they will notice.

So choosing examples is choosing what the model will generalise from. Four rules carry most of it.

## Cover the boundaries, not the centre

An example of an obvious case teaches the format and little else; the model would have sorted
*"I can't log in"* correctly anyway. **The examples worth their tokens sit where two labels
meet**: a refund for a returned book (returns, not billing), a parcel that arrived soaked (returns,
not delivery), a charge for a delivery upgrade that never happened (billing, not delivery). The
first example is one of those, and `t37` shows that a boundary example needs a neighbour on the
other side — a late order labelled delivery — or it moves the line too far.

## Take them from real traffic

An invented example is cleaner than anything a customer writes: one sentence, one problem, no
greeting. A model shown only clean examples has learnt nothing about the message that opens with
three lines of apology and asks two questions. Pick examples out of the messages you have, after
removing names and order numbers, and **keep them out of the test set**. An example that is also a
test case is answered by copying, and lesson 11 shows how far that inflates a score.

## Balance the labels

Every example adds some pull towards its own label, whatever it says. Five examples of billing
and one of delivery tilt every close call towards billing. Lesson 18 measures how far that
moves the answers.

## Count what they cost

Examples are paid for on every call, because they are part of every prompt:

```
ana@lab:~/triage$ pl tokens prompts/v2-json.txt
69 tokens, 46 words, 295 characters
ana@lab:~/triage$ pl tokens prompts/v3-examples.txt
229 tokens, 122 words, 850 characters
```

The three examples took the prompt from 69 tokens to 229, more than three times the input of each
call. That was worth it here; the format problem was worth thirteen replies in forty. **A fourth
example has to earn its place the same way**, with a count of what it fixed. Lesson 16 does the
arithmetic of what each token costs, and lesson 17 shows how a cache makes the fixed part of a
prompt cheaper.
