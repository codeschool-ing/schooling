---
title: Three prompts that agree too much
version: 2
---

Save it as `vote.py`:

```python
"""vote: the category each run gave each case, and what a majority of them
says. Several run files vote as one voter each; one run file with samples
votes with its samples."""
import collections
import sys

from pl import parse, read_jsonl


def answers(path):
    """case -> the categories its replies gave, None for a reply that does not parse."""
    found = collections.defaultdict(list)
    for r in read_jsonl(path):
        found[r["case"]].append((parse(r["text"]) or {}).get("category"))
    return found


paths = sys.argv[1:]
runs = [answers(p) for p in paths]
expect = {c["id"]: c["expect"]["category"] for c in read_jsonl(read_jsonl(paths[0])[0]["cases"])}
if len(runs) == 1:
    ballots = runs[0]
    voters = ["sample %d" % n for n in range(len(next(iter(ballots.values()))))]
    columns = [{k: v[n] for k, v in ballots.items()} for n in range(len(voters))]
else:
    voters = paths
    columns = [{k: v[0] for k, v in run.items()} for run in runs]
    ballots = {k: [col[k] for col in columns] for k in expect}

for name, col in zip(voters, columns):
    print("%-24s %3d/%d right" % (name, sum(col[k] == expect[k] for k in expect), len(expect)))
majority = unanimous = ties = 0
for k in expect:
    counts = collections.Counter(b for b in ballots[k] if b is not None).most_common()
    if len(counts) > 1 and counts[0][1] == counts[1][1]:
        ties += 1
    elif counts and counts[0][0] == expect[k]:
        majority += 1
    unanimous += len(set(ballots[k])) == 1
print("%-24s %3d/%d right" % ("majority of %d" % len(columns), majority, len(expect)))
print("unanimous on %d cases, a tie on %d" % (unanimous, ties))
```
