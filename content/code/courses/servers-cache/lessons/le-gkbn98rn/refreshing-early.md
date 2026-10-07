---
title: Refreshing before the key expires
version: 1
---

A stampede happens at the moment of expiry. **If one reader refreshes the key shortly before that
moment, the moment never comes.** The question is which reader, and the answer that needs no lock and no
coordination is: whichever one happens to roll a low number.

The rule is called **probabilistic early expiration**, published in 2015 as *XFetch*. Each reader, before
using a cached value, computes the time left and decides, with a probability that grows as expiry gets
closer, to refresh now:

```python
now - delta * beta * math.log(1 - random.random()) >= expiry
```

`delta` is how long a refresh takes, which the value stores beside itself, and `beta`, 1 by default,
leans the decision earlier when it is larger. The logarithm of a random number between 0 and 1 is
negative, so each reader pretends it is a little later than it is: usually by a fraction of `delta`,
occasionally by several. Far from expiry, nobody pretends that much. A second before it, somebody does.

This simulation does not touch Redis. It runs the rule for a key that expires at 300 seconds, with a
120-millisecond refresh and a read every 10 milliseconds, a thousand times:

```python
import math
import random

random.seed(2026)
EXPIRY, DELTA, GAP = 300.0, 0.12, 0.01  # expires at 300 s; a refresh takes 120 ms; a read every 10 ms


def should_refresh(now, expiry, delta, beta=1.0):
    return now - delta * beta * math.log(1 - random.random()) >= expiry


for beta in (1.0, 2.0):
    early = []
    for trial in range(1000):
        now = EXPIRY - 5
        while not should_refresh(now, EXPIRY, DELTA, beta):
            now += GAP
        early.append(EXPIRY - now)
    early.sort()
    print(f"beta {beta}: median {early[500]:.2f} s before expiry, latest {early[0]:.2f} s before, "
          f"{sum(e <= 0 for e in early)} of 1000 reached expiry")
```

```
ana@web:~/work$ python3 early.py
beta 1.0: median 0.34 s before expiry, latest 0.08 s before, 0 of 1000 reached expiry
beta 2.0: median 0.86 s before expiry, latest 0.29 s before, 0 of 1000 reached expiry
```

**In 1,000 trials, the key never reached its expiry.** With `beta` 1, the refresh came a third of a
second early in the typical trial, and never later than 80 milliseconds before. With `beta` 2, earlier
still. A busy key gets refreshed shortly before expiry by one reader; **a quiet key may simply expire**,
and that is fine, because a quiet key has nobody to stampede.

Its strength is that each reader decides alone. Its weakness is the word *probabilistic*: two readers
can roll low together and both refresh, so it reduces a stampede to a few queries rather than exactly
one. In practice it is often combined with the refresh flag of the previous section.
