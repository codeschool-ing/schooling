---
title: From scores to a choice
version: 1
---

It is tempting to picture a model deciding on the next word. **What it produces is a score for
every word it could write next**, and a separate step, the sampler, turns those scores into one
choice. Temperature, top-k and top-p are settings of that step and of nothing else.
`prompt-engineering` introduced them in its lessons 13 and 14. This lesson takes them again on
purpose and measures them on the triage task, where a sampled answer is either right or wrong.

The lab has a sampler you can run on its own. Its scores are for one sentence, *Your parcel is ___*,
and they were written by the course; they are not read out of any model:

```
ana@lab:~/triage$ grep -A1 '^NEXT' promptlab/sample.py
NEXT = [("on", 3.1), ("delayed", 2.6), ("here", 1.9), ("lost", 1.2),
        ("ready", 1.0), ("wet", -0.4), ("singing", -2.5), ("purple", -3.0)]
ana@lab:~/triage$ pl sample
Your parcel is ___   temperature 1, top-k off, top-p 1, 1000 draws
  on         45.1%    490  ##################
  delayed    27.4%    243  ###########
  here       13.6%    122  #####
  lost        6.7%     67  ###
  ready       5.5%     64  ##
  wet         1.4%     12  #
  singing     0.2%      2  
  purple      0.1%      0  
```

Each line is a candidate, its probability, how many of 1,000 draws picked it, and a bar. **Softmax
is the step that turns scores into probabilities**: raise *e* to each score, then divide each result
by their total, so that everything adds up to one. Only the differences between scores matter. `on`
scores 0.5 more than `delayed`, and *e* to the 0.5 is about 1.65, which is the ratio between 45.1%
and 27.4%.

The counts are a sample of those probabilities, and they wander the way samples do. `lost` is the
likelier of the two, at 6.7% against 5.5%, and `ready` came close to it, 64 draws against 67.
`purple`, at 0.1%, was never drawn in a thousand tries; at a million calls a day it would be
written about a thousand times.

## The same machinery in the stand-in

The stand-in does the same thing with its category scores. At temperature 0 it takes the label with
the highest score. Above 0 it hands the five scores to the same function, `distribution` in
`promptlab/sample.py`, and draws a label. So everything this lesson shows on *Your parcel is ___*
happens to the triage answers as well, and the last section counts what it costs.
