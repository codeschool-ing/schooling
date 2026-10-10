---
title: Quorums: how many replicas have to answer
version: 1
---

**Without a leader, a client sends each write to several replicas and each read to several replicas,
and three numbers decide whether a read is certain to see the last write.** The wrong picture is
that every replica has to confirm every write. That would make the system as fragile as its least
reliable machine. A **quorum** is the number of replicas that is enough.

The three numbers:

- **N**, how many replicas hold each piece of data;
- **W**, how many must confirm a write before it counts as done;
- **R**, how many are asked on a read, which then keeps the answer with the newest version.

**If R + W is greater than N, every group of R replicas shares at least one replica with every group
of W.** With N = 3, W = 2 and R = 2, a write reached two of the three and a read asks two of the
three; there is no way to pick two out of three that misses both of the written ones. At least one
of the replicas the read asks has the new value, and the version number says which one.

The program below tries it. Bicycle B044 was docked at ST04, and a write moves it to ST06 with a
higher version number. The write reaches W of the three replicas, and the program then tries every
possible group of R replicas a read could ask, and counts how many of those reads see ST06. Save it
as `quorum.py`:

```python
# spread/quorum.py
from itertools import combinations

N = 3


def run(w, r):
    replicas = [{"version": 1, "station": "ST04"} for _ in range(N)]
    for replica in replicas[:w]:            # the write reached w replicas
        replica.update(version=2, station="ST06")
    reads = list(combinations(replicas, r))  # every way of asking r of them
    fresh = sum(max(chosen, key=lambda x: x["version"])["station"] == "ST06"
                for chosen in reads)
    print(f"N={N} W={w} R={r}  R+W={w + r}  {fresh} of {len(reads)} reads see ST06")


for w, r in [(1, 1), (1, 2), (2, 1), (2, 2), (3, 1), (1, 3)]:
    run(w, r)
```

```
ana@lab:~/roda/spread$ python quorum.py
N=3 W=1 R=1  R+W=2  1 of 3 reads see ST06
N=3 W=1 R=2  R+W=3  2 of 3 reads see ST06
N=3 W=2 R=1  R+W=3  2 of 3 reads see ST06
N=3 W=2 R=2  R+W=4  3 of 3 reads see ST06
N=3 W=3 R=1  R+W=4  3 of 3 reads see ST06
N=3 W=1 R=3  R+W=4  1 of 1 reads see ST06
```

The first line is the danger: one replica written and one asked, and only one read in three finds
the new station. With R = 2 and W = 1, or the other way round, two in three. **Every line where R + W
reaches 4 says that every possible read sees the write**, and the lines differ only in where they
put the cost.

| N = 3 | a write needs | a read needs | still works with one replica down |
|---|---|---|---|
| W = 3, R = 1 | every replica | one | reads only |
| W = 1, R = 3 | one | every replica | writes only |
| W = 2, R = 2 | two | two | both |

That last row is why a majority on each side, two of three or three of five, is the setting you
meet most often. Cassandra calls it `QUORUM`, and lets the client choose the level on every request.

## What the rule does not promise

The overlap guarantees that a read meets the newest version. Three things it leaves open, which
you should be able to recognise:

- Something has to say which version is newest. Here it is a counter. A system that uses the
  time of the write instead is trusting clocks, and the first section of this lesson showed how far
  to trust those.
- Two writes at the same moment, from two clients to overlapping replicas, can leave the replicas
  disagreeing about which came last.
- A write that reached fewer than W replicas is reported as failed, and it is still on the ones it
  reached. A later read may find it there.

Each of these is a question about what a read is allowed to return, and lesson 10 gives those
questions their names.
