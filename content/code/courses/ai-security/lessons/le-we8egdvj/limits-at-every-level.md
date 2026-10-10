---
title: A budget per person, and a ceiling for the day
version: 1
---

One call costs cents. **A loop costs the month.** An integration that retries on every error, an
agent that calls itself, a client script with a bug: each sends the same kind of request again and
again, and each request is cheap enough that nobody notices until the total arrives.

A day of the assistant's calls, written by a rule rather than observed: five clients asking twenty
questions each through the day, and one account, `ac-3H8V`, whose integration loops from 14:00 and
sends six hundred requests in an hour. Save the generator as `~/guard/tools/daylog.py`:

```python
# daylog.py: one day of the assistant's calls, written by a rule, not observed.
#
#   guard daylog
#
# It writes data/day-usage.jsonl: five clients asking twenty questions each,
# spread from 08:00 to 17:30, and one account, ac-3H8V, whose integration
# loops from 14:00 and sends six hundred requests in an hour. Every number is
# the course's: the token counts are typical of a support question, not
# measured from anybody's traffic.
import json
import os

rows = []
for c, account in enumerate(["ac-7Q2M", "ac-0Z5Q", "ac-5K2W", "ac-9P4R", "ac-2D6M"]):
    for n in range(20):
        minute = 8 * 60 + n * 30 + c * 5
        rows.append({"time": "%02d:%02d:00" % divmod(minute, 60), "account": account,
                     "in": 1200, "out": 300})
for n in range(600):
    seconds = 14 * 3600 + n * 6
    rows.append({"time": "%02d:%02d:%02d" % (seconds // 3600, seconds // 60 % 60, seconds % 60),
                 "account": "ac-3H8V", "in": 2500, "out": 500})
rows.sort(key=lambda r: r["time"])
with open(os.path.expanduser("~/guard/data/day-usage.jsonl"), "w", encoding="utf-8") as f:
    for r in rows:
        f.write(json.dumps(r) + "\n")
print("%d calls written to data/day-usage.jsonl" % len(rows))
```

And the replay, which serves or refuses each call in the order it arrived, against two kinds of
limit. Save it as `~/guard/tools/budget.py`:

```python
# budget.py: a day of calls replayed against spending limits.
#
#   guard budget FILE [--user-tokens N] [--day-cents C]
#
# Each call is served or refused in the order it arrived. --user-tokens is a
# daily budget per account, in tokens; a call that would take the account past
# it is refused. --day-cents is a daily ceiling on what the whole assistant
# may spend: an ALERT is printed when spending reaches 80% of it, and from the
# moment it is reached every further call is refused, for every account.
# Prices come from data/prices.json, and money is integer millionths of a
# cent until it is printed.
import argparse
import json
import os

p = argparse.ArgumentParser(prog="guard budget")
p.add_argument("file")
p.add_argument("--user-tokens", type=int)
p.add_argument("--day-cents", type=int)
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/prices.json"), encoding="utf-8") as f:
    prices = json.load(f)
with open(a.file, encoding="utf-8") as f:
    calls = [json.loads(line) for line in f]


def cost(call):
    return (call["in"] * prices["cents_per_million_input"]
            + call["out"] * prices["cents_per_million_output"])


def brl(millionths):
    cents = (millionths + 500_000) // 1_000_000
    return "R$ %d,%02d" % divmod(cents, 100)


spent = 0
alerted = stopped = False
per = {}
for call in calls:
    s = per.setdefault(call["account"], {"sent": 0, "served": 0, "tokens": 0, "spent": 0})
    s["sent"] += 1
    tokens = call["in"] + call["out"]
    if stopped:
        continue
    if a.user_tokens and s["tokens"] + tokens > a.user_tokens:
        continue
    s["served"] += 1
    s["tokens"] += tokens
    s["spent"] += cost(call)
    spent += cost(call)
    if a.day_cents and not alerted and spent * 100 >= a.day_cents * 1_000_000 * 80:
        alerted = True
        print("%s ALERT  spending reached 80%% of %s" % (call["time"], brl(a.day_cents * 1_000_000)))
    if a.day_cents and spent >= a.day_cents * 1_000_000:
        stopped = True
        print("%s STOP   the day's ceiling is spent; every further call is refused" % call["time"])

print("limits: %s per account a day, %s for the day" % (
    "%d tokens" % a.user_tokens if a.user_tokens else "none",
    brl(a.day_cents * 1_000_000) if a.day_cents else "no ceiling"))
print("%-9s %5s %7s %8s %9s" % ("account", "sent", "served", "tokens", "spent"))
for account in sorted(per):
    s = per[account]
    print("%-9s %5d %7d %8d %9s" % (account, s["sent"], s["served"], s["tokens"], brl(s["spent"])))
print("total spent %s" % brl(spent))
```

First the day as it happened, with no limit of any kind:

```
ana@lab:~/guard$ guard daylog
700 calls written to data/day-usage.jsonl
ana@lab:~/guard$ guard budget data/day-usage.jsonl
limits: none per account a day, no ceiling for the day
account    sent  served   tokens     spent
ac-0Z5Q      20      20    30000   R$ 0,72
ac-2D6M      20      20    30000   R$ 0,72
ac-3H8V     600     600  1800000  R$ 40,50
ac-5K2W      20      20    30000   R$ 0,72
ac-7Q2M      20      20    30000   R$ 0,72
ac-9P4R      20      20    30000   R$ 0,72
total spent R$ 44,10
```

**R$ 40,50 of R$ 44,10 is one account in one hour.** Every honest client spent 72 centavos. Nothing in
this replay is malicious, and nothing needs to be: a loop does not have to be an attack to cost the
same as one.

## A ceiling alone stops everybody

The obvious protection is a ceiling for the whole assistant, R$ 20,00 a day, with an alert at 80%:

```
ana@lab:~/guard$ guard budget data/day-usage.jsonl --day-cents 2000
14:20:12 ALERT  spending reached 80% of R$ 20,00
14:26:06 STOP   the day's ceiling is spent; every further call is refused
limits: none per account a day, R$ 20,00 for the day
account    sent  served   tokens     spent
ac-0Z5Q      20      13    19500   R$ 0,47
ac-2D6M      20      13    19500   R$ 0,47
ac-3H8V     600     262   786000  R$ 17,69
ac-5K2W      20      13    19500   R$ 0,47
ac-7Q2M      20      13    19500   R$ 0,47
ac-9P4R      20      13    19500   R$ 0,47
total spent R$ 20,03
```

The ceiling held, and the alert came six minutes before it. **It also stopped every client who asked
anything after 14:26**: each of the five lost seven of their twenty questions, for a loop they had
nothing to do with. The total stopped at R$ 20,03, past the ceiling by part of one call, because the
check runs after a call is served; a ceiling that must never be crossed checks the estimated cost
before. A global ceiling is the last line, for the case nothing else caught. As the only line, it
turns one account's bug into everybody's outage.

## A budget per person isolates the loop

The same day with a daily budget of 100,000 tokens per account, and the same ceiling behind it:

```
ana@lab:~/guard$ guard budget data/day-usage.jsonl --user-tokens 100000 --day-cents 2000
limits: 100000 tokens per account a day, R$ 20,00 for the day
account    sent  served   tokens     spent
ac-0Z5Q      20      20    30000   R$ 0,72
ac-2D6M      20      20    30000   R$ 0,72
ac-3H8V     600      33    99000   R$ 2,23
ac-5K2W      20      20    30000   R$ 0,72
ac-7Q2M      20      20    30000   R$ 0,72
ac-9P4R      20      20    30000   R$ 0,72
total spent R$ 5,83
```

**The looping account was cut after 33 calls, and everybody else was served in full.** The total
fell to R$ 5,83, and the ceiling was never approached, which is how a ceiling should usually look.
The per-account budget is enforced with the end-user identifier of lesson 7, which is what makes "per
account" mean something when the requests all arrive through one partner's key.

Three levels, then, and each catches what the others cannot:

| limit | stops | lesson |
|---|---|---|
| `max_tokens` per call | one reply that runs on | this one, and lesson 9 |
| requests per minute | a burst | lesson 7 |
| tokens per account per day | one account's loop, slow or fast | this one |
| a ceiling for the day, with an alert | everything else, at the cost of everybody | this one |
