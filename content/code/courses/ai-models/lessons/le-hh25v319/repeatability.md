---
title: The same question, twice
version: 1
---

A program run twice on the same input gives the same output. A model may not, and an evaluation
that ran each case once has measured one draw from something that varies.

Where the variation comes from is the **temperature** setting that `prompt-engineering` covers:
above zero, the model samples among likely next tokens instead of always taking the likeliest, so
the same prompt can produce different replies. At zero most providers come close to repeatable,
though not all of them guarantee it.

## At temperature 0

`evalkit` sends temperature 0 unless told otherwise. Ana runs qwen2.5:3b again on the same cases
and compares the answers with the first run's:

```
ana@desk:~/desk$ python evalkit.py run triage runs/again.jsonl 0 qwen2.5:3b && diff <(cut -d, -f4,5 runs/again.jsonl) <(grep qwen2.5:3b runs/triage.jsonl | cut -d, -f4,5) && echo same answers
same answers
```

Identical, case for case. On a local server with nothing else running that is what to expect; a
provider serving thousands of requests at once may not repeat itself exactly even at zero, and
running twice is how you find out.

## At temperature 1

Then twice at temperature 1, the setting some applications leave on for drafting:

```
ana@desk:~/desk$ python evalkit.py run triage runs/hot-a.jsonl 1 qwen2.5:3b; python evalkit.py run triage runs/hot-b.jsonl 1 qwen2.5:3b
```

```
ana@desk:~/desk$ python evalkit.py report runs/hot-a.jsonl; python evalkit.py report runs/hot-b.jsonl | tail -1
model         strict   loose     loose, 95%  p50 s  out tok
qwen2.5:3b     29/40   29/40     57% to  84%   0.82      2.8
qwen2.5:3b     30/40   30/40     60% to  86%   0.81      2.7
```

Same model, same cases, same prompt: **29 one time and 30 the next**. And the totals hide more than
they show, because four cases changed between the two runs:

```
ana@desk:~/desk$ diff <(cut -d, -f3,4 runs/hot-a.jsonl) <(cut -d, -f3,4 runs/hot-b.jsonl)
6c6
<  "case": "c06", "answer": "order-status"
---
>  "case": "c06", "answer": "refund"
10c10
<  "case": "c10", "answer": "refund"
---
>  "case": "c10", "answer": "product-question"
32c32
<  "case": "c32", "answer": "order-status"
---
>  "case": "c32", "answer": "address-change"
39c39
<  "case": "c39", "answer": "order-status"
---
>  "case": "c39", "answer": "other"
```

c06, the parcel marked delivered, was `order-status` once and `refund` the other time; c10, the
invoice, was `refund` and then `product-question`. c32 and c39 went the other way: wrong in the
first run, right in the second. **Four answers moved and the score moved by one**, because two of
the moves cancelled out. These are the cases that sit close to the model's own boundaries, and you
find out which ones they are by running more than once.

## What follows

- **Classify and extract at temperature 0.** There is one right answer; variety is only noise.
- **Where temperature has to stay up**, as it may for drafting, run each case several times and
  report the spread, not one score. "29 to 30 in two runs" is a true statement; "30" alone is not.
- **A difference between two models smaller than one model's own run-to-run spread is not a
  difference.** Four answers moved between these two runs of one model. The comparison in section
  06 rested on twenty-one cases where only one of the two was right, which is why it survives this,
  and a split of two or three cases would not.
