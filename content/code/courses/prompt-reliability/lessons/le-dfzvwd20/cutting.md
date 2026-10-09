---
title: Cutting a prompt down
version: 2
---

Cutting a prompt feels riskier than adding to it, because every line was put there by somebody
for a reason. **Three rules make the cut safe**, and the third is the one that needs a
measurement.

- One instruction per decision. The summary's length is one decision, and lines 4 and 16 of
  `v2-long.txt` each make it. Decide what the summary is for and say that.
- Say it once. A repeated line adds tokens and adds nothing else, and capitals rank a rule
  above its neighbours whether or not anybody meant them to.
- Delete what the model does anyway, and know it from a count rather than a hunch.

Applied to `v2-long.txt`, the persona goes, since being helpful and friendly decides nothing about a
JSON object. The summary becomes one sentence, because the team scans the queue. The repeated rule
goes, and so does the rule against extra fields: the field list already names three, and in lesson 1
every reply to `v2-json.txt` that parsed had exactly those three. What is left is `v2-json.txt`, the
prompt lesson 1 used when it first asked for JSON.

## Measuring that it lost nothing

A cut is a change, so it is measured like one. Both runs are on disk from *What a longer prompt
buys*:

```
ana@lab:~/triage$ pl check runs/long.jsonl
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     33     7
urgency      21    19
all          21    19
ana@lab:~/triage$ pl check runs/v2.jsonl
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      21    19
all          21    19
ana@lab:~/triage$ pl compare runs/long.jsonl runs/v2.jsonl
runs/long.jsonl          passes 21/40
runs/v2.jsonl            passes 21/40
fixed 0, broken 0
sign test on the 0 that changed: p = 1.000
```

Twenty-one against twenty-one, and **not one message changed its result**: the same twenty-one pass
under both prompts. The long prompt's 97 extra tokens a call bought nothing a check can see. The
checks fail at different places, though. Under the long prompt every reply parsed and seven failed
on category; under the short one, one did not parse and eight failed on category. `--answers`
compares the category each reply gave, read without the wrapping:

```
ana@lab:~/triage$ pl compare runs/long.jsonl runs/v2.jsonl --answers
40 cases, same answer 37, different answer 3
  t36    billing -> account
  t38    delivery -> None
  t39    account -> delivery
```

Three answers moved, and none of them changed a verdict. `t38` is the reply from lesson 1 whose
summary broke on an apostrophe, so it has no answer to compare; `t36` and `t39` were wrong under
one prompt and wrong in another way under the other. **The cut kept every pass and saved 97 tokens a
call.**

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
