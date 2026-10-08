---
title: Reading the scores
version: 1
---

`evalkit report` reads a run back and prints one line per model:

```
ana@desk:~/desk$ python evalkit.py report runs/triage.jsonl
model         strict   loose     loose, 95%  p50 s  out tok
llama3.2:3b    18/40   19/40     33% to  63%   0.92      4.9
qwen2.5:3b     30/40   30/40     60% to  86%   0.84      2.7
llama3.2:1b     4/40    5/40      5% to  26%   0.86      9.2
```

Read it left to right.

**strict and loose.** qwen2.5:3b sorted 30 of 40, every one written cleanly. llama3.2:3b chose the
right label 19 times and wrote 18 of them in the exact form the program wants. llama3.2:1b got 5.
The **out tok** column is a clue to section 07: a label is one or two tokens, and the two Llama
models wrote far more than that on average, so they were writing something other than a label.

**The interval.** 30 of 40 is 75%, and with forty cases the honest statement is that the true rate
is **somewhere between 60% and 86%**. That is the Wilson interval at 95% confidence, the `wilson`
function in section 05, and it is the most important column in the table. llama3.2:3b's 19 sits in
33% to 63%, and llama3.2:1b's 5 in 5% to 26%. **qwen2.5:3b's interval does not overlap
llama3.2:1b's**, so that difference is real; its interval and llama3.2:3b's overlap from 60% to 63%,
so the table alone does not settle that one.

**Speed**: the median time per request, under a second for all three on this machine. Lesson 4
section 06 measured the same models drafting, where the reply is long and the difference shows; a
reply of one label is too short for size to matter.

## Asking the sharper question

The intervals answer "how good is each model". A sharper question is "**on the same cases, which
one wins**", because the models answered the same forty e-mails. Most cases are right for both or
wrong for both and say nothing about the difference. Only the cases where exactly one was right do:

```
ana@desk:~/desk$ python evalkit.py compare runs/triage.jsonl qwen2.5:3b llama3.2:3b
only qwen2.5:3b right: 16 ['c04', 'c07', 'c09', 'c13', 'c14', 'c15', 'c16', 'c19', 'c21', 'c22', 'c28', 'c29', 'c33', 'c37', 'c38', 'c39']
only llama3.2:3b right: 5 ['c01', 'c06', 'c11', 'c36', 'c40']
chance of a split at least this uneven if they were equally good: 0.027
```

Sixteen cases where only qwen2.5:3b was right, five the other way. If the two models were equally
good, each of those twenty-one would be a coin toss, and a split at least that uneven comes up
**about three times in a hundred**: the `0.027` on the last line. The convention is to want one time
in twenty, 0.05, or rarer before calling it a difference, and this passes it. The same comparison
between the two Llama models:

```
ana@desk:~/desk$ python evalkit.py compare runs/triage.jsonl llama3.2:3b llama3.2:1b
only llama3.2:3b right: 16 ['c02', 'c03', 'c05', 'c06', 'c08', 'c12', 'c17', 'c18', 'c20', 'c23', 'c25', 'c27', 'c30', 'c31', 'c36', 'c40']
only llama3.2:1b right: 2 ['c15', 'c16']
chance of a split at least this uneven if they were equally good: 0.001
```

Sixteen to two, `0.001`: the 3b is better than the 1b, by a margin forty cases settle.

## What ana takes from it

- **qwen2.5:3b sorts better than llama3.2:3b**, on these cases, by a margin the paired comparison
  supports even though the intervals touch. The model the course installs for everything is not
  the best sorter of Lantern Books' mail, and only ana's own cases could have said so.
- **None of the three reaches the floor.** Lesson 4 wrote it as 35 of 40; the best here is 30.
  Section 10 says what that means.
- **More cases would narrow every interval, slowly.** An interval narrows with the square root of
  the number of cases: four times as many halve its width. The cheaper move is often to add cases
  like the ones the models disagree on, which are the ones that separate them.
