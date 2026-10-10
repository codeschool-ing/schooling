---
title: Unsupervised learning, with no answer to learn from
version: 1
---

**Unsupervised learning is given rows and no answer.** It finds structure the rows have on their
own: groups of members who resemble each other, a few directions along which most of the variation
runs, the rows that resemble nothing else. Nobody tells it what a good group is, so nobody can tell
it that it got one wrong.

That last sentence is the one to hold on to. A supervised model has a score, because its answers
can be compared with the real ones. An unsupervised result has no real answer to be compared with,
so **whether it is useful is decided by somebody reading it**, and two runs with different settings
can both be "right".

## Four groups of members

The commonest unsupervised method is **k-means**: choose a number of groups, `k`, and it moves `k`
centres around until each member sits with the nearest one and each centre sits in the middle of
its members. Save this as `unsupervised.py`:

```python
"""unsupervised.py: group members by how they buy, with no answer to learn from."""
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

import features

COLUMNS = ["recency_days", "visits_180d", "spend_180d"]

members = features.build("2025-11-30")
scaled = StandardScaler().fit_transform(members[COLUMNS])
members["group"] = KMeans(n_clusters=4, n_init=10, random_state=0).fit_predict(scaled)

summary = members.groupby("group").agg(
    members=("member_id", "count"),
    recency_days=("recency_days", "median"),
    visits_180d=("visits_180d", "median"),
    spend_180d=("spend_180d", "median"),
    lapsed=("lapsed", "mean"),          # never shown to KMeans: read afterwards
)
print(summary.round(2).to_string())
```

**`StandardScaler` comes first for a reason that is pure arithmetic.** k-means measures distance,
and `spend_180d` is in cents, running to six figures, while `visits_180d` runs to about twenty.
Unscaled, a difference of one visit would weigh less than a difference of one centavo, and the
groups would be groups by spending alone. Scaling puts each column on the same footing: the mean
becomes 0 and a typical spread becomes 1.

```
ana@dev:~/ml$ python unsupervised.py
       members  recency_days  visits_180d  spend_180d  lapsed
group                                                        
0          382           9.0         14.0    133790.0    0.05
1          451         109.0          2.0     19970.0    0.53
2         1064          14.0          8.0     77870.0    0.09
3         1233          22.0          4.0     32940.0    0.15
```

The groups have numbers and no names, because k-means does not name anything. Reading the medians,
a person would call them something like:

| group | the medians say | a name a person might give it |
| --- | --- | --- |
| 0 | here 9 days ago, 14 visits, R$ 1,337.90 | the regulars |
| 1 | here 109 days ago, 2 visits | the fading |
| 2 | here 14 days ago, 8 visits | the steady |
| 3 | here 22 days ago, 4 visits | the occasional |

**The last column was never shown to k-means.** `lapsed` came along in the table, and the program
reads it only after the groups exist. It says 53% of group 1 lapsed in the following 90 days
against 5% of group 0, so the groups found something real about the members. That check was only
possible because this shop happens to have a label; most unsupervised work has none, and the
reading in the table above is all there is.

## What it is for in a platform

Segments like these go into a dashboard, into a campaign list, or **into another model as a
feature**: "group 1" is one column that summarises three. Lesson 2 uses clustering as one of the
four common tasks, and lesson 10 meets a different unsupervised idea, comparing the distribution of
today's rows with last month's, which needs no label either.
