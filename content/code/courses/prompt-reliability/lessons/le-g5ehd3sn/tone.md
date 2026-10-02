---
title: Tone, by rules
version: 1
---

Correctness and format have answers somebody wrote down. Tone does not, and the usual first move is
to give up on measuring it. The other move is to write down the parts of it that **can** be said as
rules. `runs/drafts.jsonl` holds twelve replies to customers, written by the course rather than by a
model, which is why `pl show` reports no tokens for them. `checks/tone.json` holds the rules:

```
ana@lab:~/triage$ cat checks/tone.json
{
  "max_exclamations": 1,
  "max_words": 80,
  "banned": ["\\bdear (sir|madam)\\b", "\\bvalued customer\\b", "\\bas per\\b"],
  "promises": ["\\btoday\\b", "\\bimmediately\\b", "\\bguarantee", "\\bwithin 24 hours\\b"],
  "acknowledge": ["\\bsorry\\b", "\\bthank", "\\bapologi"]
}
ana@lab:~/triage$ pl tone runs/drafts.jsonl
t01  ok   
t02  FAIL exclamations
t03  FAIL promise
t04  FAIL banned, acknowledge
t05  ok   
t06  ok   
t07  ok   
t08  ok   
t09  FAIL promise
t10  FAIL exclamations
t11  FAIL length
t12  FAIL banned, promise

exclamations  2 of 12 fail
length        1 of 12 fail
banned        2 of 12 fail
promise       3 of 12 fail
acknowledge   1 of 12 fail
```

Five rules, each a unit test in the sense of lesson 11: at most one exclamation mark, at most eighty
words, none of the phrases the shop never uses, no promise from a short list, and some
acknowledgement of the customer. Five of the twelve drafts pass every rule.

## What a rule sees

**A rule catches exactly what it names**, and that cuts both ways:

```
ana@lab:~/triage$ pl show runs/drafts.jsonl t02
│ Thank you for your patience! The tracking stopped at the courier's depot. I've asked them to trace it and I'll write again by Thursday!
stop: end, tokens in 0, out 0
ana@lab:~/triage$ pl show runs/drafts.jsonl t03
│ Sorry the cover arrived torn. A replacement goes out today and there's no need to send the damaged copy back.
stop: end, tokens in 0, out 0
```

`t02` fails on exclamation marks, two where the rule allows one, which is fair. It also promises to
write again *by Thursday*, a date, and the `promise` rule did not notice, because its list names
*today*, *immediately*, *guarantee* and *within 24 hours*, and Thursday is none of those. `t03` fails
`promise` for *a replacement goes out today*. If the shop does post replacements the same day, that
is the most useful sentence in the reply.

So the drafts show both errors of a rule in two lines: a promise it missed and a fine sentence it
flagged. **A rule is a proxy for a judgement**, and its errors are where the judgement and the
proxy part ways. That is not a reason to drop the rules. They are free, they give the same verdict
every time, and they catch *Dear Sir/Madam* and *valued customer* without fail.

## What no rule here sees

None of the five asks whether the reply is true, whether it answers the question, or whether it
sounds like someone who cares. `t01` passes everything; so would a polite reply about the wrong
order. Tone beyond the rules needs somebody to read a sample, or a model asked to judge, and lesson
13 measures how far a model judge can be trusted with that.
