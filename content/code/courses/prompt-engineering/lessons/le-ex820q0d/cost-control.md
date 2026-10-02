---
title: The limit as a budget
version: 1
---

The output limit is usually met as a safety net for runaway text. **It is also the one number in
a request that bounds what the request can cost**, and that is the reason to set it on purpose
rather than leave it at a default.

## Output tokens cost more

Lesson 3 showed that a model API charges per token, for what goes in and what comes out. **Output
tokens are priced separately from input tokens, and on most price lists they cost several times
more.** Writing a token takes a full step of the model each time, while the prompt can be
processed in one pass. The prices change often and differ by model, so the figures below are
illustrative ones given on the command line, not any provider's: 2 per million input tokens and 8
per million output tokens, in no particular currency.

A request that asks a model to classify one review:

```
ana@lab:~/pe$ cat request.txt
You read customer reviews of Café Aurora. For the review below, reply with
one JSON object with three fields: "sentiment" (positive, neutral or
negative), "topic" (two or three words) and "summary" (one sentence).
Reply with the object and nothing else.

Review:
Waited fifteen minutes for a tea at noon. The staff were kind about it.
ana@lab:~/pe$ tok count request.txt
tokens  words  chars  file
    79     55    335  request.txt
```

If the reply is about the size of the 36-token object in the previous section, call it 40 tokens:

```
ana@lab:~/pe$ tok cost request.txt -o 40 -i 2 -p 8
input  79 tokens x 2 per million = 0.000158
output 40 tokens x 8 per million = 0.000320
one request: 0.000478
10,000 requests: 4.78
```

The 40 output tokens cost twice as much as the 79 input tokens. If the same request lets the
model write 400 tokens, because the limit allowed it and nothing in the prompt discouraged it:

```
ana@lab:~/pe$ tok cost request.txt -o 400 -i 2 -p 8
input  79 tokens x 2 per million = 0.000158
output 400 tokens x 8 per million = 0.003200
one request: 0.003358
10,000 requests: 33.58
```

The input did not change. **The bill for ten thousand requests went from 4.78 to 33.58, all of it
from output.** That is what an unbounded reply costs at scale, and it is also roughly what you pay
when a model falls into a loop like the one in the previous section and runs until the limit.

## A limit is a budget per request

Because generation stops at the limit, **the limit times the output price is the most the output
of one request can cost**. With a limit of 400 at the illustrative price above, no request's
output costs more than 0.0032, whatever the model does. That makes the limit the number to
reason with when you estimate a monthly bill: requests per month, times input tokens, plus
requests times the limit, at the two prices.

Set it from the task, not from a habit:

- for a classification or a small JSON object, a little above the largest valid reply, measured
  with a tokenizer as `tok count` did above;
- for prose, from the length you actually want, with room for the model to finish its sentence;
- for anything open-ended, from what you can afford per request, and then handle `length` as the
  outcome it is.

## Asking for brevity and enforcing it

There are two ways to keep a reply short, and they do different jobs. **Asking for brevity in
the prompt changes what the model writes; the limit only changes where it is cut.** A prompt
that says "one sentence" or "reply with the object and nothing else", as `request.txt` does,
moves the likely continuation towards a short, complete answer. The limit cannot do that. It can
only stop a long answer part-way.

So use both, for different reasons. The instruction is how you get a short answer that is
complete. The limit is the guarantee for the times the instruction is not followed, and the
finish reason is how you find out which of the two happened. A limit set without the instruction
mostly produces cut answers; an instruction without the limit leaves the cost of a bad day
unbounded.

Some APIs have changed how this parameter is named or what it counts, for instance whether
tokens a model spends reasoning before it answers count against it. Read the current reference
for the model you call, and the date on it.
