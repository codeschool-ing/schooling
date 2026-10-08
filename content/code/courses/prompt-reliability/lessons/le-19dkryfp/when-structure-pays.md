---
title: When structure pays
version: 2
---

`prompt-engineering` introduced structured output in its lesson 18 and schemas in lesson 19. This
lesson takes them again on purpose, with the question this course asks of every technique: **how
often does the structure actually arrive, and what does the program reading it do when it does
not?**

The idea that has to go first is that JSON is the careful, professional way to ask for an
answer, and prose the sloppy one. **Structure is for a reader that is a program.** The same
message, sorted by the bare prompt and by the one that asks for JSON:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, llama3.2:3b, written to runs/v1.jsonl
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl show runs/v1.jsonl t17
│ Here is the sorted customer message:
│
│ **Message:** My order was dispatched ten days ago and still hasn't arrived. I need it for a birthday on Saturday.
│
│ **Category:** Missing Order
│
│ **Urgency:** High
│
│ **Reason:** The customer is concerned about receiving their order in time for a birthday on Saturday, which suggests that the order is time-sensitive and requires prompt attention from the support team.
stop: stop, tokens in 69, out 82, 9.3 s
ana@lab:~/triage$ pl show runs/v2.jsonl t17
│ {"category": "delivery", "urgency": "high", "summary": "Order has not arrived ten days after dispatch and is needed for a birthday on Saturday"}
stop: stop, tokens in 114, out 35, 4.3 s
```

A person on the support team reads the first reply in a few seconds and knows what to do. *Missing
Order* and *High* are not the shop's words, and a person does not care. A program routing the
message to the warehouse queue cares about nothing else: it needs a field it can find by name and a
value it can compare with `delivery`. **If a person reads the answer, the bare prompt was nearly
finished.** Lesson 1 failed it on every check because the reader in this course is a program, and
the checks are that program's needs written down.

## What structure costs, and what it saves

Asking for JSON is more instructions, so the prompt is longer. The reply is a different matter:

```
ana@lab:~/triage$ python3 stats.py runs/v1.jsonl runs/v2.jsonl
runs/v1.jsonl, 40 calls
  tokens in    mean   61.1   total   2446
  tokens out   mean  107.5   total   4298   max 164
  seconds      p50  12.7   p95  17.9   total  495.1
runs/v2.jsonl, 40 calls
  tokens in    mean  106.2   total   4246
  tokens out   mean   30.6   total   1225   max 38
  seconds      p50   3.7   p95   4.6   total  146.8
```

The prompt went from 61.1 tokens a call to 106.2. **The reply went from 107.5 tokens to 30.6**, and
the median call from 12.7 seconds to 3.7. The bare prompt left the shape of the answer open, and
`llama3.2:3b` filled the space with a heading, the message copied back, bold labels and a paragraph
of reasoning nobody asked for. Every one of those tokens is written one at a time, and on a
processor written tokens are the slow ones.

So the usual worry about structure, that braces and key names are tokens too, is real and small.
The larger effect is the one in the other direction: **a format is a limit on what the model may
write**, and a model given no limit spends it. That is worth knowing before blaming JSON for a
slow pipeline, and it is a result about this model, on this task; lesson 6 measures the length of
replies properly.

## What structure constrains

A field holds what the format lets it hold. The summary here is one sentence because the format
says so, and a customer with two problems gets one of them summarised. Prose has room for *"mostly
billing, but they also mention a damaged book"*; a `category` field has room for one word from a
list of five. **Every field you add is a decision taken away from the model.** That is exactly what
you want for a value a program branches on, and exactly what you do not want for something a person
was going to read and judge.

So the rule is about the reader. Ask for structure when a program consumes the answer, and ask for
as much as that program needs, which in this course is two labels and a sentence.
