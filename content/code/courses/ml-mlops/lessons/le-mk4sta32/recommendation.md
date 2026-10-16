---
title: Recommendation, and how to know it works
version: 1
---

**A recommender ranks things for somebody.** Its input is a member and its output is a short list
of titles, best first. There are whole families of algorithms for it; this section uses the oldest,
which a data engineer can build in SQL and a page of Python: **members who bought this also bought
that.** Count, for every pair of titles, how many members own both. A member who owns title A is
then recommended the titles that most often appear beside A.

Counted raw, the most popular titles appear beside everything, so every member would be recommended
the same bestsellers. The program divides each count by how popular the recommended title is, which
asks a better question: **is B bought with A more than B is bought anyway?** Save it as
`recommend.py`:

```python
"""recommend.py: members who bought this also bought, tested on the months that followed."""
import sqlite3
from collections import Counter
from itertools import combinations

CUT = "2025-11-30"
BOUGHT = """
SELECT DISTINCT p.member_id, l.title_id, p.day > :cut AS later
FROM purchases p JOIN lines l USING (purchase_id)
"""

with sqlite3.connect("shop.db") as db:
    rows = db.execute(BOUGHT, {"cut": CUT}).fetchall()
    names = dict(db.execute("SELECT title_id, title FROM titles"))
before, after = {}, {}
for member, title, later in rows:
    (after if later else before).setdefault(member, set()).add(title)

popular = Counter(t for titles in before.values() for t in titles)
together = Counter()
for titles in before.values():
    for a, b in combinations(sorted(titles), 2):
        together[a, b] += 1
        together[b, a] += 1


def recommend(member, n=5):
    owned = before.get(member, set())
    score = Counter()
    for a in owned:
        for b in names:
            if b not in owned:
                score[b] += together[a, b] / popular[b]   # lift over plain popularity
    return [t for t, _ in score.most_common(n)]


def most_popular(member, n=5):
    owned = before.get(member, set())
    return [t for t, _ in popular.most_common() if t not in owned][:n]


member = 2
print("member 2 owned:", ", ".join(names[t] for t in sorted(before[member])))
print("recommended:   ", ", ".join(names[t] for t in recommend(member)))

tested = [m for m in after if m in before and after[m] - before[m]]
for name, fn in (("co-purchase", recommend), ("most popular", most_popular)):
    hits = sum(bool(set(fn(m)) & after[m]) for m in tested)
    print(f"{name:13} a new title bought after {CUT} was in the top 5 for "
          f"{hits} of {len(tested)} members ({hits / len(tested):.1%})")
```

The counting uses only purchases up to 30 November. What members bought **after** that date is
kept apart, and it is how the recommender is judged.

```
ana@dev:~/ml$ python recommend.py
member 2 owned: The Garden of Crime, The Winter of Crime, The Letter of Crime, The Island of Crime, The Lantern of Crime, The Orchard of Crime, The River of Literary, The Garden of Literary, The Lantern of Literary, The Orchard of Literary, The Harbour of Cooking, The Harbour of Science
recommended:    The Harbour of Crime, The Mirror of Crime, The Station of Crime, The River of Crime, The Mirror of Literary
co-purchase   a new title bought after 2025-11-30 was in the top 5 for 1573 of 2343 members (67.1%)
most popular  a new title bought after 2025-11-30 was in the top 5 for 492 of 2343 members (21.0%)
```

Member 2 owned six crime titles and four literary ones, and was recommended four more crime and one
literary. That reads well, which proves nothing; a recommender is judged on what members actually
did next.

## The test

**For every member who bought a title they did not already own after 30 November, was one of those
titles in the top five recommended on 30 November?** That is called **hit rate at 5**, and it is
the same question asked of the baseline, the five most popular titles the member does not own.

| | hit rate at 5 |
| --- | --- |
| most popular | 21.0% |
| co-purchase | 67.1% |

Three times as many members found something they went on to buy. Two cautions keep that number
honest. **The shop's members have very regular taste**, because the generator gives every member
two favourite categories and draws at least 80% of their books from them, and real readers
wander more.
And **a hit is not a sale the recommendation caused**: those members bought those books without
ever being shown the list. Whether showing it changes anything is a question only an experiment
answers, which is lesson 8's subject when a new model is tried on part of the traffic.
