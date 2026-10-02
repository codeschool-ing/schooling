---
title: Cutting a prompt down
version: 1
---

Cutting a prompt feels riskier than adding to it, because every line was put there by somebody
for a reason. **Three rules make the cut safe**, and the third is the one that needs a
measurement.

- **One instruction per decision.** The summary's length is one decision, and lines 4 and 16 of
  `v2-long.txt` each make it. Decide what the summary is for and say that.
- **Say it once.** A repeated line adds tokens and adds nothing else, and capitals rank a rule
  above its neighbours whether or not anybody meant them to.
- **Delete what the model does anyway**, and know it from a count rather than a hunch.

Applied to `v2-long.txt`, the persona goes, since being helpful and friendly decides nothing about
a JSON object. The summary becomes one sentence, because the team scans the queue. The repeated
rule goes, and so does the rule against extra fields: the field list already names three, and in
lesson 1 every reply to `v2-json.txt` that parsed had exactly those three. What is left is the
prompt lesson 1 started from:

```
ana@lab:~/triage$ cat prompts/v2-json.txt
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

Message: {{message}}
```

## Measuring that it lost nothing

A cut is a change, so it is measured like one. Both runs are on disk from the first section:

```
ana@lab:~/triage$ pl check runs/long.jsonl
check      pass  fail
json         21    19
fields       21    19
labels       21    19
category     21    19
urgency      19    21
all          19    21
ana@lab:~/triage$ pl check runs/v2.jsonl
check      pass  fail
json         27    13
fields       27    13
labels       27    13
category     27    13
urgency      24    16
all          24    16
ana@lab:~/triage$ pl compare runs/long.jsonl runs/v2.jsonl
runs/long.jsonl          passes 19/40
runs/v2.jsonl            passes 24/40
fixed 12, broken 7, still passing 12, still failing 9
broken: t08 t09 t15 t16 t20 t27 t39
sign test on the 19 that changed: p = 0.359
ana@lab:~/triage$ pl compare runs/long.jsonl runs/v2.jsonl --answers
40 cases, same answer 40, different answer 0
```

The short prompt passes 24 of 40 against 19. **That is not a win, and the sign test says so**:
nineteen messages changed, twelve one way and seven the other, and a fair coin splits nineteen
tosses at least that unevenly about one time in three (p = 0.359). What `--answers` adds is the
content. It compares the category each reply gave, read without the wrapping, and all forty are
the same. The cut kept every answer and saved 98 tokens a call.

The changes that did happen are the formatting habits from lesson 1, landing on different
messages:

```
ana@lab:~/triage$ pl show runs/v2.jsonl t08
│ Here is the JSON you asked for:
│
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "They ordered the hardback and you sent the paperback."
│ }
stop: end, tokens in 82, out 42
ana@lab:~/triage$ pl show runs/long.jsonl t08
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "They ordered the hardback and you sent the paperback. They'd like to exchange it."
│ }
stop: end, tokens in 180, out 42
```

The short prompt put a sentence in front of `t08` and the long one did not. In the stand-in,
which replies pick up a habit depends on the exact text of the prompt, so any edit reshuffles
them while the rate stays about the same. **That reshuffling is what noise looks like in this
lab**, and it is why the count went up without the prompt getting better. Lesson 3 deals with the
wrapping itself.

## What the test set cannot tell you

`v2-json.txt` also dropped line 13, the rule against putting the customer's name in the summary.
Nothing above says whether that was safe, because **no message in `cases/dev.jsonl` contains a
name**. A rule that guards against something the test set never shows cannot be judged by that
test set, in either direction: the count would have been the same with the rule or without it.
The same goes for the rule against making things up, which no check measures.

So the third rule of cutting has a condition attached. Delete what the model does anyway **when a
case in the test set would have caught it not doing so**. Where there is no such case, either keep
the line or write the case first. Lesson 11 is about building test sets that cover what the
prompt's rules are there to prevent.
