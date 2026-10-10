---
title: Choosing availability, and the bill that arrives afterwards
version: 1
---

**A system that chooses availability answers on both sides of a cut and pays later: when the link
heals, two histories have to become one.** People call such a system AP. During the partition it
looks better than a CP system, because nobody sees an error. The cost arrives afterwards, as a
decision about which of two true stories to keep.

## Where answering is right

Amazon's Dynamo, described in a paper in 2007, is the classic case. Its example was the shopping
cart: a customer adding an item must never be told to come back later, and if two copies of a cart
disagree, the merged cart can hold both items and the customer removes one. A wrong cart for a
minute costs less than an error on the button that makes money.

At Roda Livre the same reasoning fits **the dock map in the app**. A map that shows Rua XV with 7
bicycles when it has 6 sends nobody far wrong. A map that shows an error sends the customer to walk
there and look.

## Three ways two copies become one

When the link comes back, `n1` and `n2` say 5 and `n3` says 7. Systems that chose availability
resolve that in one of three ways.

| way | what happens | the cost |
|---|---|---|
| last write wins | keep the value written latest, by its timestamp | the other write is thrown away |
| keep both and ask | store both versions and hand them to the application on the next read | the application has to know how to merge |
| merge by construction | store the data in a shape where any two copies can be combined | only some data has such a shape |

The first and the third are easy to run side by side. Save this in `~/roda/cap` as `merge.py`:

```python
# cap/merge.py
# ST02 had 6 bicycles when the link to n3 was cut. During the cut,
# n1 saw one taken at 08:02 and n3 saw one returned at 08:05.

# Last write wins: each copy is a value and the time it was written.
n1 = {"value": 5, "at": "2025-10-03 08:02"}
n3 = {"value": 7, "at": "2025-10-03 08:05"}
print("last write wins:", max(n1, n3, key=lambda c: c["at"])["value"])

# A counter that merges: each node counts only what it saw itself.
START = 6
n1c = {"taken": {"n1": 1}, "returned": {}}
n3c = {"taken": {}, "returned": {"n3": 1}}


def merge(a, b):
    out = {}
    for kind in ("taken", "returned"):
        nodes = set(a[kind]) | set(b[kind])
        out[kind] = {n: max(a[kind].get(n, 0), b[kind].get(n, 0)) for n in nodes}
    return out


def value(c):
    return START - sum(c["taken"].values()) + sum(c["returned"].values())


m = merge(n1c, n3c)
print("merged counter:", value(m))
print("either order:", merge(n3c, n1c) == m)
print("merged twice:", merge(m, n3c) == m)
```

```
ana@lab:~/roda/cap$ python merge.py
last write wins: 7
merged counter: 6
either order: True
merged twice: True
```

## Last write wins lost a bicycle

The return at 08:05 is later than the ride at 08:02, so last write wins kept 7 and threw the ride
away. **Neither node was wrong about what it saw; the rule discarded one of them.** Nothing reports
it, either. Rua XV shows one bicycle more than it holds until somebody walks there and counts.

The rule has a second weakness, which lesson 9 already named: it trusts the clocks. If `n3`'s
clock ran a few minutes fast, a write that happened earlier would still win. Cassandra resolves
conflicting writes exactly this way, by timestamp, one value at a time — which is why its
operators care so much about the clocks of its machines.

## The counter that merges

The second half of the program stores something different. Instead of the count, each node keeps
how many bicycles **it** saw taken and returned. Two such records can always be combined: take, for
each node, the larger of the two numbers it reported, since a node's own count only grows. The
merged counter says 6, which is the truth.

The last two lines are the reason it is safe. **The order of a merge does not matter, and merging
the same copy twice changes nothing.** So copies can be combined whenever they meet, in any order,
as often as the network happens to deliver them. A data type built to have those properties is
called a **CRDT**, a conflict-free replicated data type, a name from 2011. Counters, sets and
registers all have such versions.

The limit is the one section 04 started from. A count merges. "Bicycle `B017`
is unlocked for this customer" does not: there is no way to combine two customers holding one
bicycle into a correct answer. **Data that can be merged can live on the AP side; a decision that
cannot be merged belongs on the CP side.**
