---
title: Choosing for the task
version: 1
---

Triage has one right answer per message. The same message should get the same category every time,
because a person or a program acts on it. **For a task with one right answer, sampling can only
turn right answers into wrong ones.** Here is the prompt from lesson 7 run five times over all
seventy messages, first at temperature 0:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --out runs/t0.jsonl
350 calls, prompt fbc4c9b1, written to runs/t0.jsonl
ana@lab:~/triage$ pl check runs/t0.jsonl
check      pass  fail
json        340    10
fields      340    10
labels      340    10
category    280    70
urgency     230   120
all         230   120
```

`--samples 5` calls the model five times per message, 350 calls in all. At temperature 0 the five
calls are identical, so every count is five times the single run's: 56 categories right becomes
280. Now the same thing at temperature 1:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=1 --out runs/t1.jsonl
350 calls, prompt fbc4c9b1, written to runs/t1.jsonl
ana@lab:~/triage$ pl check runs/t1.jsonl
check      pass  fail
json        340    10
fields      340    10
labels      340    10
category    194   156
urgency     157   193
all         157   193
ana@lab:~/triage$ pl check runs/t1.jsonl --failures | grep '^t08'
t08    category  other, expected returns
t08#2  category  billing, expected returns
t08#3  category  other, expected returns
ana@lab:~/triage$ grep '"t08"' cases/dev.jsonl
{"id": "t08", "message": "I ordered the hardback and you sent the paperback. I'd like to exchange it.", "expect": {"category": "returns", "urgency": "normal"}}
```

Right categories fell from 280 to 194. `--failures` names each call by message and sample, so `t08`
is sample 0 and `t08#2` is sample 2. `t08` was sorted three different ways in five calls: twice
right, twice `other`, once `billing`. It is a close call in the stand-in, an exchange with few
keywords, and **sampling turns a close call into a coin toss on every call**. The `json` line did
not move, because in the stand-in the formatting habits depend on the prompt and the message, not
on the temperature.

A lower temperature is not the same as zero:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.2 --out runs/t02.jsonl
350 calls, prompt fbc4c9b1, written to runs/t02.jsonl
ana@lab:~/triage$ pl check runs/t02.jsonl
check      pass  fail
json        340    10
fields      340    10
labels      340    10
category    271    79
urgency     224   126
all         224   126
```

At 0.2 the categories still lost 9 of 280. The messages whose top two scores are nearly equal keep
flipping, at almost any temperature above zero.

## When variety is the point

The other kind of task wants a different answer each time: five subject lines to choose from, a
reply to a customer that should not read like the last fifty, a list of ideas. There, temperature 0
gives you the same text five times, and some sampling is what makes a second call worth paying for.
This lab cannot measure that, because the stand-in does not write replies; lesson 12 measures tone
on replies the course wrote. **Decide per task, and keep classification and extraction at 0.**

Lesson 19 samples on purpose, several times per message, and votes. That is a way of using the
randomness rather than suffering it, and it costs a call per sample.

## Zero is not a guarantee

At temperature 0 the stand-in is deterministic, because it is a few hundred lines of Python. **A
hosted model at temperature 0 is not guaranteed to give identical output on identical input.**
Anthropic's documentation for the `temperature` parameter says so in as many words: even at 0.0 the
results will not be fully deterministic. Requests are batched with other people's, and the
floating-point arithmetic on the hardware does not always add things up in the same order, so two
top candidates that are nearly tied can swap. That is one more reason to measure over a test set and
compare message by message, instead of trusting one run of one message.
