---
title: Tuning a threshold, with numbers
version: 1
---

The rule says `gte: 10`. Why ten? A threshold is a decision with a cost on each side: lower, and it flags
strangers who tried two names; higher, and a careful guesser who tries nine stays under it. **The way to
choose is to count**, against a period you know. Save this as `sweep.sh`:

```bash
#!/bin/bash
# sweep.sh: how many addresses would the rule flag at each threshold?
for n in 2 3 4 10; do
  sed "s/gte: 10/gte: $n/" spray.yml > try.yml
  ~/sigma/bin/sigma convert -t sqlite try.yml -o try.sql 2>/dev/null
  printf 'gte %-3s %s addresses\n' "$n" "$(bash grouped.sh try.sql | tail -n +3 | wc -l)"
done
```

```
ana@soc:~/week$ bash sweep.sh
gte 2   30 addresses
gte 3   14 addresses
gte 4   1 addresses
gte 10  1 addresses
```

| threshold | addresses flagged | what they are |
|---|---|---|
| 2 accounts in an hour | 30 | nearly every stranger of the week, each trying two or three names |
| 3 | 14 | still the background noise of the internet |
| 4 | 1 | Thursday's address |
| 10 | 1 | the same |

Between 3 and 4 the count drops from 14 to 1, and that cliff is the information. In this week, **any
threshold from 4 to 19 catches Thursday and nothing else**, so 10 sits comfortably inside the safe range.
Had the cliff been at 9, a threshold of 10 would have been one careful guesser away from missing it.

Note what the dashboard's second panel showed: `203.0.113.174` tried 6 accounts over the **week**. The
rule's window is one **hour**, and within any hour that address tried at most three. **The window is part
of the threshold**: "6 in a week" and "6 in an hour" are different rules.

Two other tools beside the threshold. An **allowlist** with an owner and an expiry date (a scanner the
company hired, until the end of its contract) removes a known source without blinding the rule. And
**suppression after action**: once an address is blocked, further alerts about it add nothing until the
block is lifted.
