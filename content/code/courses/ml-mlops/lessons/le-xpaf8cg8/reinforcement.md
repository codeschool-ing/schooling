---
title: Reinforcement learning, by acting and being told how it went
version: 1
---

The third kind has no table of examples at all. **A reinforcement learner acts, receives a reward,
and adjusts what it does next.** Nobody hands it the right answer; it finds out which actions pay
by taking them, and every action it takes changes what it gets to learn from.

Four words carry it:

- the **agent** chooses;
- the **actions** are what it may choose between;
- the **reward** is the number it is told afterwards;
- the **environment** is everything that decides the reward and that the agent cannot see.

And one tension carries all four. Every round, the agent can **exploit**, choosing the action that
has paid best so far, or **explore**, trying another in case it pays better. Only exploiting stops
it learning; only exploring stops it earning.

## A voucher, chosen by trying

The smallest case with that tension is called a **bandit**, after a row of slot machines with
different, unknown payouts. Ponto Final has three vouchers it could send a fading member, and it
does not know which one brings people back. The program below **invents a shop to try them on**:
each voucher has a true rate at which members return, written in the code where the learner cannot
read it, and the learner has to find the best one by sending them. Save it as `bandit.py`:

```python
"""bandit.py: learn which voucher to send by sending them, in a simulated shop.

The shop is made up: each voucher brings a member back with a probability the
program is never told, and it has to find the best one by trying.
"""
import numpy as np

VOUCHERS = ["10% off", "free coffee", "double points"]
TRUE_RATE = [0.04, 0.07, 0.05]             # the world's, hidden from the learner
rng = np.random.default_rng(7)

sent = np.zeros(3)
returned = np.zeros(3)
for member in range(5000):
    if rng.random() < 0.1 or sent.min() == 0:
        choice = int(rng.integers(3))      # explore: try any voucher
    else:
        choice = int(np.argmax(returned / sent))   # exploit: the best so far
    came_back = rng.random() < TRUE_RATE[choice]   # the reward
    sent[choice] += 1
    returned[choice] += came_back

for name, s, r in zip(VOUCHERS, sent, returned):
    print(f"{name:14} sent {int(s):5}  came back {int(r):4}  rate {r / s:.3f}")
print(f"members brought back: {int(returned.sum())} of 5000")
```

This strategy is called **epsilon-greedy**: one time in ten it explores at random, the rest of the
time it sends the voucher with the best rate so far.

```
ana@dev:~/ml$ python bandit.py
10% off        sent  1799  came back   73  rate 0.041
free coffee    sent  2373  came back  159  rate 0.067
double points  sent   828  came back   39  rate 0.047
members brought back: 271 of 5000
```

It found the free coffee, and sent it more than any other. Its estimates, 0.041, 0.067 and 0.047,
are close to the true 0.04, 0.07 and 0.05 it was never shown. **And it paid for finding out**: 1,799
members got the worst voucher, more than got the second best, because early on a run of luck made
10% off look like the winner and the learner kept exploiting it until the numbers corrected
themselves. Sending free coffee to all 5,000 would have brought back about 350; the learner brought
back 271, and the difference is the price of not knowing.

## Why a data engineer meets it least

Reinforcement learning is what plays games, steers robots and tunes recommendations live, and it is
the kind a data platform supports least often, for a reason the program shows: **it learns from the
consequences of its own actions**, so it cannot be trained on last year's table. It needs to act on
real members, or on a simulator good enough to stand in for them, and the simulator above is good
only because it was written to be. What the platform does provide is the log: every action taken,
when, to whom, and what came of it, kept so that the next policy can be judged against the last.

Lessons 2 to 10 are supervised and unsupervised. When this kind of learning comes up again it is in
lesson 8, where sending a new model to a fraction of requests is the same explore-or-exploit choice
made by a person.
