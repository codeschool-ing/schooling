---
title: A retention limit is a job that runs
version: 2
---

Tarefa's policy is in `retention.json`: the raw text for 30 days, the redacted text for 180, the
counts for 730. **Those numbers are choices, and no law hands them to you.** The LGPD asks for data
to be kept for as long as its purpose requires and then removed, which means the purpose sets the
number. Thirty days for the raw text is a bet that a client who received a bad answer complains
within a month. A company whose disputes take ninety days to arrive needs a longer raw tier and a
stronger reason to keep it.

A limit written in a document does nothing on its own. The job that applies it reads the policy and a
second file, `holds.json`, which the end of this section explains; paste it now:

```sh
cat > ~/guard/holds.json <<'EOF'
[
 {"file": "raw/2026-08-14.jsonl", "case": "INC-2208", "until": "2026-12-31",
  "reason": "a client asking for a freelancer's address and phone; kept for the safety team's investigation"}
]
EOF
```

And save the job as `~/guard/tools/sweep.py`:

```python
# sweep.py: the retention policy, applied to logs/.
#
#   guard sweep [--now YYYY-MM-DD] [--dry-run | --check]
#
# Every file older than its tier's limit in retention.json is deleted, unless
# holds.json keeps it until a date that has not passed. --dry-run prints what
# would go; --check prints what is overdue and exits 1 if anything is.
import argparse
import datetime as dt
import json
import os
import sys

HOME = os.path.expanduser("~/guard/")
p = argparse.ArgumentParser(prog="guard sweep")
p.add_argument("--now")
g = p.add_mutually_exclusive_group()
g.add_argument("--dry-run", action="store_true")
g.add_argument("--check", action="store_true")
a = p.parse_args()

with open(HOME + "retention.json") as f:
    policy = json.load(f)
with open(HOME + "holds.json") as f:
    holds = {h["file"]: h for h in json.load(f)}
now = dt.date.fromisoformat(a.now) if a.now else dt.date.today()

print("policy: " + ", ".join("%s %d days" % (t, policy[t]["days"]) for t in policy))
gone = kept = late = 0
for tier, rule in policy.items():
    folder = HOME + "logs/" + tier
    for name in sorted(os.listdir(folder)):
        rel = tier + "/" + name
        age = (now - dt.date.fromisoformat(name.split(".")[0])).days
        if age <= rule["days"]:
            continue
        hold = holds.get(rel)
        if hold and dt.date.fromisoformat(hold["until"]) >= now:
            print("%-27s %4d days  KEEP    hold %s until %s" % (rel, age, hold["case"], hold["until"]))
            kept += 1
        elif a.check:
            print("%-27s %4d days  OVERDUE limit %d" % (rel, age, rule["days"]))
            late += 1
        else:
            print("%-27s %4d days  %s" % (rel, age, "would delete" if a.dry_run else "deleted"))
            if not a.dry_run:
                os.remove(os.path.join(folder, name))
            gone += 1
if a.check:
    print("%d file(s) past their limit, %d kept by a hold" % (late, kept))
    sys.exit(1 if late else 0)
print("%s%d file(s) %s, %d kept by a hold" % ("dry run: " if a.dry_run else "", gone,
                                            "would be deleted" if a.dry_run else "deleted", kept))
```

Here is what the logs look like when the policy has been written down and nothing has ever applied it:

```
ana@lab:~/guard$ guard sweep --now 2026-09-30 --check; echo "exit $?"
policy: raw 30 days, redacted 180 days, metrics 730 days
raw/2026-03-10.jsonl         204 days  OVERDUE limit 30
raw/2026-03-24.jsonl         190 days  OVERDUE limit 30
raw/2026-04-07.jsonl         176 days  OVERDUE limit 30
raw/2026-04-21.jsonl         162 days  OVERDUE limit 30
raw/2026-05-05.jsonl         148 days  OVERDUE limit 30
raw/2026-05-19.jsonl         134 days  OVERDUE limit 30
raw/2026-06-02.jsonl         120 days  OVERDUE limit 30
raw/2026-06-16.jsonl         106 days  OVERDUE limit 30
raw/2026-06-30.jsonl          92 days  OVERDUE limit 30
raw/2026-07-14.jsonl          78 days  OVERDUE limit 30
raw/2026-07-28.jsonl          64 days  OVERDUE limit 30
raw/2026-08-11.jsonl          50 days  OVERDUE limit 30
raw/2026-08-14.jsonl          47 days  KEEP    hold INC-2208 until 2026-12-31
raw/2026-08-25.jsonl          36 days  OVERDUE limit 30
redacted/2026-03-10.jsonl    204 days  OVERDUE limit 180
redacted/2026-03-24.jsonl    190 days  OVERDUE limit 180
15 file(s) past their limit, 1 kept by a hold
exit 1
```

Fifteen files past their limit, and the oldest raw file is 204 days old against a promise of 30.
One of the records in the log is a client asking how long chats are kept, and the assistant answers
with the policy. On this machine that answer is false. Nobody wrote anything false: the policy was
written, the job that applies it was not.

`--check` deletes nothing. It reports and **exits 1 when anything is overdue**, so it can run in
the same scheduler as the sweep and raise an alarm when the sweep has stopped. A sweep that fails
silently and a sweep that was never set up look identical from the outside, and the check is what
tells them apart from a dashboard.

## A hold stops the clock, for a reason and until a date

One file in the check is marked `KEEP`. The client in `rq-0014` and `rq-0015` asked the assistant
for a freelancer's home address and phone number, and said they were going to find him. The safety
team opened an investigation, and the raw text of that day is its evidence:

```
ana@lab:~/guard$ cat holds.json
[
 {"file": "raw/2026-08-14.jsonl", "case": "INC-2208", "until": "2026-12-31",
  "reason": "a client asking for a freelancer's address and phone; kept for the safety team's investigation"}
]
```

A hold names the file, the case, the reason and an end date. **A hold without an end date is a
second retention policy that nobody wrote down**, and the case that justified it closes while the
file stays. When `until` passes, the next sweep deletes the file like any other; extending the hold
is a decision somebody has to make again, with the case still open.

## Running it

`--dry-run` prints what a sweep would delete without deleting it, which is how a new policy is
tried on a real store before it is trusted:

```
ana@lab:~/guard$ guard sweep --now 2026-09-30 --dry-run | tail -4
raw/2026-08-25.jsonl          36 days  would delete
redacted/2026-03-10.jsonl    204 days  would delete
redacted/2026-03-24.jsonl    190 days  would delete
dry run: 15 file(s) would be deleted, 1 kept by a hold
ana@lab:~/guard$ guard sweep --now 2026-09-30 | tail -4
raw/2026-08-25.jsonl          36 days  deleted
redacted/2026-03-10.jsonl    204 days  deleted
redacted/2026-03-24.jsonl    190 days  deleted
15 file(s) deleted, 1 kept by a hold
ana@lab:~/guard$ guard sweep --now 2026-09-30 --check; echo "exit $?"
policy: raw 30 days, redacted 180 days, metrics 730 days
raw/2026-08-14.jsonl          47 days  KEEP    hold INC-2208 until 2026-12-31
0 file(s) past their limit, 1 kept by a hold
exit 0
ana@lab:~/guard$ ls logs/raw
2026-08-14.jsonl
2026-09-01.jsonl
2026-09-08.jsonl
2026-09-15.jsonl
2026-09-22.jsonl
2026-09-29.jsonl
```

The raw tier now holds the last thirty days and the one held file. Every `--now` in this lesson is
fixed at 30 September 2026 so the ages match the text; a real sweep takes today's date.

## The copies the sweep does not reach

Deleting a file deletes one copy. Three others are common, and each needs its own answer:

- **Backups.** A backup kept for a year holds a year of the raw tier, whatever the sweep did. Either
  the raw tier is left out of backups, or the backups are kept no longer than the shortest tier
  they contain.
- **The places logs are shipped to.** An observability vendor that receives the raw text keeps it
  for its own retention period. Send it the metrics, or the redacted tier at most.
- **The model provider.** The provider receives every prompt and keeps its own records of your
  calls, for abuse monitoring, for a period set by its terms. Your sweep does not touch them. What
  the provider keeps, where, and whether an arrangement with no retention is available to you is a
  question for the contract, and lesson 12 is about that contract.
