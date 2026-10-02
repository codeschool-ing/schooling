---
title: What fine-tuning costs, and the order to try things in
version: 1
---

The argument usually made for fine-tuning is the bill: a prompt carrying instructions and examples
is long, it is sent on every request, and a fine-tuned model would not need it. That part is true,
and it is worth measuring before it is believed. **The saving per request is real and small; the
cost of getting there is large and paid up front.**

## The saving, measured

`few-shot.txt` is a prompt for the café's message sorting. It carries the instruction, eight
examples, and the message to sort at the end:

```
Sort each message from a Café Aurora customer into one category:
hours, allergens, refunds, loyalty, wifi, deliveries or other.
Reply with the category only.

Message: Are you open on Sunday afternoon?
Category: hours

Message: Does the carrot cake have nuts in it?
Category: allergens

Message: My latte was cold and I want my money back.
Category: refunds

Message: I lost my stamp card, can I get a new one?
Category: loyalty

Message: The guest network keeps logging me out.
Category: wifi

Message: Nobody signed for the milk this morning.
Category: deliveries

Message: Do you sell gift vouchers?
Category: other

Message: Is the kitchen still serving at half past five?
Category: hours

Message: Is there oat milk for the flat white?
Category:
```

`short.txt` is what a model fine-tuned on those categories would need: the last two lines and
nothing else. `tok` counts both, and `tok cost` prices them. **The prices on the command line are
illustrative**, 2.50 per million input tokens and 10.00 per million output tokens, and are not any
provider's. The answer is one category, counted as 2 output tokens:

```
ana@lab:~/pe$ tok count few-shot.txt short.txt
tokens  words  chars  file
   165    121    751  few-shot.txt
    13     10     57  short.txt
ana@lab:~/pe$ tok cost few-shot.txt -o 2 -i 2.50 -p 10.00
input  165 tokens x 2.5 per million = 0.000412
output 2 tokens x 10 per million = 0.000020
one request: 0.000432
10,000 requests: 4.33
ana@lab:~/pe$ tok cost short.txt -o 2 -i 2.50 -p 10.00
input  13 tokens x 2.5 per million = 0.000032
output 2 tokens x 10 per million = 0.000020
one request: 0.000053
10,000 requests: 0.53
ana@lab:~/pe$ awk 'BEGIN { print (4.33 - 0.53) * 1000 }'
3800
```

The short prompt is 13 tokens against 165, and 10,000 requests cost 0.53 against 4.33. Over ten
million requests the difference is 3800 in the same units. **Whether that pays for fine-tuning
depends on what the fine-tuning costs**. The saving is also smaller than this if the provider bills
a fine-tuned model at a higher rate than the base model, which is common enough to check before
you plan around it.

## The costs that are not on the bill

The per-token price is the visible part. The rest:

- collecting and labelling data: hundreds or thousands of examples, each one checked by a
  person who knows the right answer. This is usually the largest cost, and it is people's time;
- training runs: each run is billed, and the first run is rarely the last, because you adjust the data
  and train again;
- evaluation: a held-back set of examples the model never trained on, to show it improved and
  did not get worse at something else. Without it, you cannot tell a good run from a bad one;
- hosting: a fine-tuned model is either an endpoint at a provider, priced per token and
  sometimes per hour, or weights you run yourself, with the memory arithmetic of lesson 8;
- doing it again: a fine-tuned model is tied to the base model it started from. When the
  provider retires that base, or a better one appears, the data, the training and the evaluation
  are repeated on the new one.

A prompt has none of these. It is a text file, it changes in a minute, and it moves to a new model
by being sent to it.

## The ladder

So the order to try things in runs from cheapest to dearest, and you climb a rung only when the one
below has been tried and measured:

| rung | what it changes | lesson |
|---|---|---|
| 1. write a clearer prompt | the instruction: what, for whom, in what format | 2, 20 |
| 2. add examples | a few worked cases in the prompt | 21 |
| 3. add retrieval | the facts the answer needs, fetched for each question | 11 |
| 4. fine-tune | the weights, from hundreds of labelled examples | this one |

Most problems stop at the first or second rung. Retrieval is the answer when the problem is
knowledge: the model does not know your handbook, and no amount of wording fixes that. **Fine-tuning
is for a behaviour that already works with a long prompt and needs to be cheaper, faster or more
consistent at large volume.**

## Deciding

| the problem | try first |
|---|---|
| the answers are in the wrong format or tone | a clearer prompt, then examples |
| it does not know your products, prices or policies | retrieval |
| your prices or hours change every month | retrieval, never fine-tuning |
| the prompt works and costs too much at millions of requests a day | fine-tuning, with an evaluation set |
| nobody agrees what a good answer is | decide that first; no technique fixes it |

Lesson 30 describes a middle path between writing a prompt and changing the weights, in which the
prompt itself is learnt from examples.
