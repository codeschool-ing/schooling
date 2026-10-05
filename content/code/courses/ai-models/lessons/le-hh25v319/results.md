---
title: Reading the scores
version: 1
---

`evalkit report` reads a run back and prints one line per model:

```
ana@desk:~/desk$ python lab/evalkit.py report runs/triage.jsonl
model           strict   loose     loose, 95%  p50 s  $ per 1k
standin-large    38/40   38/40     83% to  99%   0.70    0.2001
standin-small    32/40   34/40     71% to  93%   0.21    0.0167
standin-local    32/40   32/40     65% to  90%   1.04    0.0000
```

Read it left to right.

**strict and loose.** standin-large sorted 38 of 40, and wrote every answer cleanly. standin-small
chose right 34 times and wrote 32 of them in the exact form the program wants. standin-local chose
right 32 times, cleanly.

**The interval.** 38 of 40 is 95%, and with forty cases the honest statement is that the true rate
is **somewhere between 83% and 99%**. That is the Wilson interval at 95% confidence, the `wilson`
function in section 05, and it is the most important column in the table. standin-small's 34 sits in
71% to 93%, standin-local's 32 in 65% to 90%. **The three intervals overlap.** On forty cases these
numbers do not prove that any of the three is better than the others.

**Speed and cost**: the median time per request and the cost of a thousand requests at the course's
prices. standin-large costs about twelve times what standin-small does per request; standin-local
costs nothing per request because its cost is a machine (lesson 3).

## Asking the sharper question

The intervals answer "how good is each model". A sharper question is "**on the same cases, which
one wins**", because both models answered the same forty e-mails. Most cases are right for both or
wrong for both and say nothing about the difference. Only the cases where exactly one was right do:

```
ana@desk:~/desk$ python lab/evalkit.py compare runs/triage.jsonl standin-large standin-small
only standin-large right: 4 ['c22', 'c26', 'c31', 'c37']
only standin-small right: 0 []
chance of a split at least this uneven if they were equally good: 0.125
```

Four cases where only standin-large was right, none the other way. If the two models were equally
good, each of those four would be a coin toss, and four heads in a row comes up **one time in
eight**: the `0.125` on the last line. That is suggestive and not conclusive; the convention is to
want one time in twenty or rarer before calling it a difference. The same comparison between the
small and local models:

```
ana@desk:~/desk$ python lab/evalkit.py compare runs/triage.jsonl standin-small standin-local
only standin-small right: 3 ['c06', 'c30', 'c34']
only standin-local right: 1 ['c37']
chance of a split at least this uneven if they were equally good: 0.625
```

Three to one. Splits like this happen by chance most of the time (`0.625`), so on these cases the
two are **not distinguishable**, even though one scored 34 and the other 32.

## What ana takes from it

- **standin-large is probably better** at sorting than standin-small, by a margin forty cases cannot
  pin down. Four cases in forty is 10%; if the inbox looked like the set, that would be forty of
  its 400 e-mails a day moved by hand.
- **More cases would settle it, slowly.** An interval narrows with the square root of the number
  of cases: four times as many halve its width. The cheaper move is often to add cases like the
  ones the models disagree on, which are the ones that separate them.
- **The decision is not only accuracy.** Section 10 puts the price and the floor from lesson 4 back
  next to these numbers.
