---
title: Three candidates
version: 1
---

The same report for each candidate against the release in production, starting with the new model:

```
ana@lab:~/obs$ python regress.py 2026.10.1 2026.10.2
data/eval-v2.jsonl sha256 0d464ef783cd: 2026.10.1 -> 2026.10.2
               both right  both wrong  fixed  broken
  dev                 10          18      0       0
  held-out             8           6      0       0
exact McNemar p = 1.0000 on 0 changed verdicts
checks newly failing: none
replies changed: 5 of 42
output tokens         637 ->        782   +23%
cost US$       0.00944242 -> 0.02061592   +118%
median ms              92 ->         95   +2%
```

**Nothing moved, and the price more than doubled.** Not one verdict changed, five replies read
differently, extract-2 writes 23% more tokens, and at twice the price per token the set costs 118% more
to answer. A pass rate alone would have reported this candidate as "no change". It is a regression, in
money, and it buys nothing these 42 questions can see.

The five changed replies still need reading, because the set grades facts and form, and a reply can
change in ways neither sees: an extra sentence that is true but beside the point, as lesson 11's
definitions of relevance disagreed about. `regress.py` counts them so that somebody knows how many to
read.

The floor put back:

```
ana@lab:~/obs$ python regress.py 2026.10.1 2026.10.3
data/eval-v2.jsonl sha256 0d464ef783cd: 2026.10.1 -> 2026.10.3
               both right  both wrong  fixed  broken
  dev                 10          15      3       0
  held-out             8           4      2       0
exact McNemar p = 0.0625 on 5 changed verdicts
  fixed  e07 dev      Above what order value is standard delivery free?
  fixed  e17 dev      When is the contract of sale formed?
  fixed  e38 dev      My parcel MG-00000001 still hasn't arrived, two weeks no
  fixed  e24 held-out Do you store my IP address?
  fixed  e42 held-out right of withdrawal days
checks newly failing: none
replies changed: 12 of 42
output tokens         637 ->        956   +50%
cost US$       0.00944242 -> 0.01821592   +93%
median ms              92 ->        651   +604%
```

**The mirror of the release that shipped.** The same five cases fixed, nothing broken, and the cost and
the latency go back to about what they were before 2 October. The p-value is the same 0.0625, for the same
reason: five cases. Nobody needs it to be smaller to ship this one, because every changed case changed
in the right direction and each can be read.

Both changes together:

```
ana@lab:~/obs$ python regress.py 2026.10.1 2026.10.4
data/eval-v2.jsonl sha256 0d464ef783cd: 2026.10.1 -> 2026.10.4
               both right  both wrong  fixed  broken
  dev                 10          14      4       0
  held-out             8           4      2       0
exact McNemar p = 0.0312 on 6 changed verdicts
  fixed  e04 dev      Can I return a signed copy?
  fixed  e07 dev      Above what order value is standard delivery free?
  fixed  e17 dev      When is the contract of sale formed?
  fixed  e38 dev      My parcel MG-00000001 still hasn't arrived, two weeks no
  fixed  e24 held-out Do you store my IP address?
  fixed  e42 held-out right of withdrawal days
checks newly failing: e38 short_enough
replies changed: 23 of 42
output tokens         637 ->       1389   +118%
cost US$       0.00944242 -> 0.04161892   +341%
median ms              92 ->        904   +877%
```

**Six fixed, and the first significant result of the lesson, p = 0.031**, and still not the candidate to
ship. One reply, e38, now fails a check it passed: lesson 8's `short_enough`, more than eighty words,
because extract-2 keeps up to four sentences and the lower floor gives it more to choose from. And the
set costs more than four times as much to answer and takes about ten times as long.

A team choosing among the three would ship **2026.10.3**: it fixes what the floor release broke, at the
cost the shop paid before. The sixth fix, e04, is the one thing 2026.10.4 adds, and it comes with a
check broken and a bill quadrupled; it is a reason to look at e04, not to change the model.
