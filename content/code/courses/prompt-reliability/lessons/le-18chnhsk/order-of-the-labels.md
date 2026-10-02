---
title: The order of the labels
version: 1
---

A list of labels reads like a set: five names, separated by commas, none more important than the
others. **To a model a list is a sequence**, and what it answers can depend on where in the
sequence a label sits. The cleanest way to find out is to change nothing but the order:

```
ana@lab:~/triage$ diff prompts/v6-escaped.txt prompts/v18-order.txt
8c8
< - "category": one of billing, delivery, returns, account, other
---
> - "category": one of other, account, returns, delivery, billing
ana@lab:~/triage$ grep -n "^FIRST_LISTED" promptlab/standin.py
89:FIRST_LISTED = 0.25     # the label a prompt lists first adds this
```

`v18-order` is `v6-escaped` with the categories listed backwards, so `other` comes first instead of
`billing`. In the stand-in the effect is declared: whichever label a prompt lists first gets 0.25
added to its score before it picks, and when two labels tie, the one listed earlier wins. Both
rules are in `promptlab/standin.py`, and neither reads the message.

## Which answers moved

Run both prompts over all seventy cases and compare the answers, not the passes:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6.jsonl
ana@lab:~/triage$ pl run prompts/v18-order.txt cases/all.jsonl --out runs/order.jsonl
70 calls, prompt 573d0e3a, written to runs/order.jsonl
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/order.jsonl --answers
70 cases, same answer 66, different answer 4
  t37  delivery -> other
  h07  billing -> account
  h15  delivery -> other
  h28  delivery -> other
ana@lab:~/triage$ grep -E '"(t37|h07|h15|h28)"' cases/all.jsonl | grep -o '"category": "[a-z]*"'
"category": "delivery"
"category": "billing"
"category": "account"
"category": "billing"
```

Four answers of seventy changed, and three of them went to `other`, the label that now comes first.
The `grep` prints what the person who labelled each case said, in the same order. `t37` was
delivery and `h07` was billing, so **two answers that were right became wrong**. `h15` and `h28`
were wrong before and are wrong now, under a different label.

The fourth move is the tie rule at work. `h07` asks *"How do I update the card saved in my
account?"*, which carries one billing word and one account word of equal weight, and the reversed
list names `account` before `billing`.

None of the four is a clear message. **A list order does not move a message about a double
charge; it moves the ones the model was nearly guessing on**, and those are the ones where a
wrong answer is hardest to notice. Sixty-six answers stayed where they were, which is exactly why
an effect like this survives a demo.

## Why not compare the passes

`pl compare` without `--answers` tells a different and noisier story:

```
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/order.jsonl
runs/v6.jsonl            passes 46/70
runs/order.jsonl         passes 44/70
fixed 2, broken 4, still passing 42, still failing 22
broken: t04 t31 t37 h07
sign test on the 6 that changed: p = 0.688
ana@lab:~/triage$ pl show runs/order.jsonl t04
│ Here is the JSON you asked for:
│
│ {
│   "category": "account",
│   "urgency": "high",
│   "summary": "They can't log in."
│ }
stop: end, tokens in 120, out 39
```

It reports four broken, but `t04` and `t31` gave the same category under both prompts. `t04` broke
because a sentence appeared in front of its JSON. The stand-in's formatting habits are rolled from
the exact text of the prompt, so **any edit to a prompt re-rolls them**, whatever the edit was
about. The pass count mixes the change you made with every other way a reply can fail. For a
question about which label a wording favours, `--answers` is the comparison that isolates it, and
the sign test's `p = 0.688` on the passes is a measurement of the wrong thing.

## Real models

The stand-in's rule is a constant somebody chose. Real models have position effects of their own,
and they are documented. *Calibrate Before Use: Improving Few-Shot Performance of Language Models*
(Zhao and others, 2021) found that GPT-3, classifying with a few examples in the prompt, favoured
the labels of the examples placed nearest the end, which the authors called **recency bias**, and
that the same examples in a different order could move accuracy a long way. *Large Language Models
Are Not Robust Multiple Choice Selectors* (Zheng and others, 2023) found models preferring some
option positions and letters over others, whatever the options said.

What that gives you is a test. Run the prompt with the list in two orders and compare
the answers. If nothing moves, the order is not deciding anything you can see. If answers move,
the ones that moved are your close calls, and **an order you happened to type is choosing between
them**. The remedy then is evidence for those messages, a definition of where one label ends and
the next begins, rather than a better order: lesson 5 measured what explained categories do.
