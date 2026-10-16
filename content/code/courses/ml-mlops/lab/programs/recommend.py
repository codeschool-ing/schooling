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
