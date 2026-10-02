---
title: What breaks a cache
version: 1
---

**Any change to the prefix breaks every block from the changed one onwards.** In the stand-in that
is how the blocks are keyed: each block's key is a hash of that block and every block before it, so
a block can only match if the whole prompt up to its end matches. Real caches match a prefix too,
and the consequence is the same.

`v17-message-first` was the extreme case, a different block one on every call. Ordinary edits do
the same thing more quietly:

- **One word changed in the guide** makes every block from that word on new. The next calls write
  them all again, and only then start reading.
- **A new example** inserted near the top moves every token after it, so every block after it
  changes even though their text did not.
- **A date, a customer's name or a ticket number placed early**, *"Today is 14 August. Customer:
  Maria Souza."*, varies per call exactly as the message does, and costs the cache everything
  after it.

So keep what varies at the end, and change the fixed part deliberately and rarely, knowing that
each change is paid for once in writes.

## The cache must not change the answers

A cache is supposed to change cost and time and nothing else. **Check that rather than assume
it**, the same way any change is checked:

```
ana@lab:~/triage$ pl compare runs/plain.jsonl runs/static.jsonl
runs/plain.jsonl         passes 32/40
runs/static.jsonl        passes 32/40
fixed 0, broken 0, still passing 32, still failing 8
sign test on the 0 that changed: p = 1.000
```

Nothing fixed, nothing broken: the same template with the cache on gave the same result on every
message. In the stand-in the reply is computed before the cache is consulted, so this was
guaranteed; with a real provider it is the check that would tell you if it were not.

## Reordering is not a cache setting

Moving the message to the front is different. It changes the text the model reads, so it is a new
prompt, and its answers may differ for reasons that have nothing to do with the cache:

```
ana@lab:~/triage$ pl compare runs/static.jsonl runs/first.jsonl
runs/static.jsonl        passes 32/40
runs/first.jsonl         passes 34/40
fixed 5, broken 3, still passing 29, still failing 3
broken: t18 t26 t40
sign test on the 8 that changed: p = 0.727
ana@lab:~/triage$ pl compare runs/static.jsonl runs/first.jsonl --answers
40 cases, same answer 40, different answer 0
ana@lab:~/triage$ pl check runs/static.jsonl
check      pass  fail
json         35     5
fields       35     5
labels       35     5
category     35     5
urgency      32     8
all          32     8
ana@lab:~/triage$ pl check runs/first.jsonl
check      pass  fail
json         37     3
fields       37     3
labels       37     3
category     37     3
urgency      34     6
all          34     6
```

Thirty-four against thirty-two, five fixed and three broken, and a sign test of 0.727 that cannot
tell the two apart. `--answers` compares the category, and all forty agree. The checks place every
difference in `json`: five replies failed it under the guide-first prompt and three under the
message-first one, and the urgency failures after it are three in each. Here is one of the three
that broke:

```
ana@lab:~/triage$ pl show runs/static.jsonl t18
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "Two pages are missing from chapter 3."
│ }
stop: end, tokens in 250, out 32
ana@lab:~/triage$ pl show runs/first.jsonl t18
│ ```json
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "Two pages are missing from chapter 3."
│ }
│ ```
stop: end, tokens in 250, out 39
```

The same answer, wrapped in a code fence. In the stand-in, the formatting habits of lesson 1 land
on messages chosen by a hash of the whole prompt, so **reordering a prompt moves them onto different
messages** at the same rate. A real model reacts to order for its own reasons, which is why a
reorder made for the cache goes through the gate of lesson 14 like any other change to the text.
