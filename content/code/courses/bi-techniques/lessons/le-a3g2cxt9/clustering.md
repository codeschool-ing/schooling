---
title: Letting an algorithm find the groups
version: 1
---

**k-means clustering** puts each customer in one of k groups so that customers in a group are as close
as possible to the group's centre. It is given the numbers and the number of groups, and nothing
else: no rule about what a good customer is. This is the unsupervised learning that lesson 16 puts a
name to, and it is the simplest member of the family.

```schooling-example
{"language": "python", "file": "clusters.py", "parts": [{"code": "import numpy as np\nimport pandas as pd\nfrom sklearn.cluster import KMeans\nfrom sklearn.metrics import silhouette_score\nfrom sklearn.preprocessing import StandardScaler\n\nrfm = pd.read_csv(\"rfm.csv\", index_col=\"customer\")\nfeatures = np.log1p(rfm[[\"recency\", \"frequency\", \"monetary\"]])\nscaled = StandardScaler().fit_transform(features)", "note": "The same three raw numbers. Their logarithm tames the long tails, and scaling gives each the same spread, so that spend in reais does not outweigh recency in days simply by being larger."}, {"code": "print(\" k   inertia   silhouette\")\nfor k in range(2, 7):\n    model = KMeans(n_clusters=k, n_init=10, random_state=0).fit(scaled)\n    print(f\"{k:2} {model.inertia_:9.0f} {silhouette_score(scaled, model.labels_):12.3f}\")", "note": "k-means for two to six groups. Inertia is how far customers sit from their group's centre, which always falls as k grows; silhouette compares that with how far they sit from the next group. `random_state` fixes the starting points, so the result repeats."}, {"code": "model = KMeans(n_clusters=4, n_init=10, random_state=0).fit(scaled)\nrfm[\"cluster\"] = model.labels_\nprofile = rfm.groupby(\"cluster\").agg(customers=(\"recency\", \"size\"), recency=(\"recency\", \"median\"),\n                                     orders=(\"frequency\", \"median\"), spent=(\"monetary\", \"median\"))\nprint(\"\\nfour clusters, medians\")\nprint(profile.sort_values(\"spent\", ascending=False).round(0).to_string())", "note": "Four groups, described by the medians of the original numbers. The algorithm numbers its clusters arbitrarily; the description is what names them."}], "output": " k   inertia   silhouette\n 2      6793        0.435\n 3      4660        0.395\n 4      3364        0.427\n 5      2679        0.395\n 6      2084        0.401\n\nfour clusters, medians\n         customers  recency  orders   spent\ncluster                                    \n0             1581      6.0    24.0  5066.0\n1             1413    155.0    12.0  2319.0\n3              718      5.0     6.0  1231.0\n2              967    275.0     3.0   480.0"}
```

## Choosing k

**There is no right number of clusters in the data**; there is a number that is useful. Two
measurements help.

- **Inertia** falls with every extra group, from 6,793 at two to 2,084 at six, because more centres are
  always closer. The useful sign is an elbow, where the fall slows; here it is gradual.
- **The silhouette** is between −1 and 1, higher when each customer is clearly closer to its own group
  than to the next one. It peaks at 0.435 for two groups and is next best at 0.427 for four.

Two groups, "recent" and "lapsed", are statistically the cleanest split and too coarse to plan
four different campaigns with. Four are nearly as clean and match the number of actions Panela can
take. **The business question chooses k within the range the data allows.**

## Reading the clusters

The four clusters, by their medians, are recognisable:

| cluster, by spend | customers | median recency | median orders | reads as |
|---|---|---|---|---|
| first | 1,581 | 6 days | 24 | regular, recent, the best |
| second | 1,413 | 155 days | 12 | used to order often, now lapsed |
| third | 718 | 5 days | 6 | recent, still occasional |
| fourth | 967 | 275 days | 3 | ordered a few times, long ago |

They are close to the RFM segments: champions, at risk, new or occasional, lost, with the RFM "in
between" spread across them. **That agreement is the reassuring result**: a rule written by a person
and an algorithm that knew no rule found nearly the same structure. When the two disagree sharply, it
is worth finding out why before trusting either.

## RFM or clustering

| | RFM rules | k-means |
|---|---|---|
| explainable | one sentence per segment | a table of medians, named afterwards |
| stable over time | the same rules every month | centres move when the data does |
| finds the unexpected | only what the rules ask about | structure nobody wrote a rule for |
| needs | a person to write rules | scaling, a choice of k, a person to name the groups |

Most teams start with RFM because it can be explained in a meeting, and use clustering to check it
or to explore more numbers than three, where writing rules by hand stops being practical.
