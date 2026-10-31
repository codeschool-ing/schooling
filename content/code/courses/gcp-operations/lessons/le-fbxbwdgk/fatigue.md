---
title: On-call fatigue, measured
version: 1
---

**An alert that fires when nothing needs doing teaches the person on call to ignore alerts.** That is
fatigue, and it is not a matter of temperament: after a month of pages that resolve themselves, a reasonable
person stops getting up for them, including the one that mattered. The cure starts with counting, because
every alert looks reasonable on its own and only the month's list shows which ones are noise.

The program below generates a month of the shop's notifications, the kind of list Cloud Monitoring's
incident history gives, and summarises it. Write it into `~/gcp/pages.py`:

```python
# pages.py
"""pages.py: a month of the shop's alert notifications, and what they say about on-call.

The notifications are generated, seeded. Each has the policy that sent it, when
it opened, how long the incident lasted, and whether anybody had to do anything.
"""
import random
from datetime import datetime, timedelta

rng = random.Random(5)
start = datetime(2026, 10, 1)
POLICIES = {                       # name: (notifications a month, minutes open, acted on?)
    "cpu above 80%": (61, (2, 6), 0.0),
    "payment retries high": (9, (10, 40), 0.8),
    "uptime check failing": (4, (3, 20), 1.0),
    "fast error-budget burn": (2, (30, 90), 1.0),
}
pages = []
for name, (n, (lo, hi), acted) in POLICIES.items():
    for _ in range(n):
        at = start + timedelta(minutes=rng.randint(0, 30 * 24 * 60))
        pages.append((name, at, rng.randint(lo, hi), rng.random() < acted))

night = lambda t: t.hour < 7 or t.hour >= 22
print(f'{"policy":<24}{"pages":>6}{"at night":>9}{"closed <10 min":>15}{"acted on":>9}')
for name in POLICIES:
    p = [x for x in pages if x[0] == name]
    print(f'{name:<24}{len(p):>6}{sum(night(t) for _, t, _, _ in p):>9}'
          f'{sum(m < 10 for _, _, m, _ in p):>15}{sum(a for *_, a in p):>9}')
print(f'{"total":<24}{len(pages):>6}{sum(night(t) for _, t, _, _ in pages):>9}'
      f'{sum(m < 10 for _, _, m, _ in pages):>15}{sum(a for *_, a in pages):>9}')
```

```
ana@laptop:~/gcp$ python3 pages.py
policy                   pages at night closed <10 min acted on
cpu above 80%               61       31             61        0
payment retries high         9        1              0        5
uptime check failing         4        0              2        4
fast error-budget burn       2        1              0        2
total                       76       33             63       11
```

**76 notifications in a month, 33 of them at night, and 11 that anybody acted on.** Read the rows:

- **`cpu above 80%`** sent 61, half of them at night, every one closed by itself within ten minutes, and nobody
  ever did anything. CPU on Cloud Run is high when the service is busy, which is when it is doing its job. This
  policy is pure noise: it measures a cause, not a symptom the user feels, and lesson 13's SLI already says
  whether users are failing. **Delete it.**
- **`payment retries high`** sent 9, and 5 needed action. That is a useful signal on the wrong channel: it is
  work for working hours, and goes to the ticket queue, as the last section did.
- **`uptime check failing`** and **`fast error-budget burn`** sent 6 between them, and all 6 needed somebody.
  Those are pages.

Deleting one policy takes the month from 76 notifications to 15, and from 33 at night to 2. Nothing about the
shop's ability to notice a real failure changes, because the policies that notice real failures are untouched.

## Questions for every policy

1. **Is it a symptom a user feels?** If it is a cause (CPU, memory, a queue's depth), it belongs on a
   dashboard, where somebody investigating will look, not on a phone.
2. **Did anybody act on it last month?** A policy whose notifications are all closed with no action is noise
   by measurement, whatever the reason it was created.
3. **Does it need a person now?** If not, a ticket.
4. **Does its notification say what to do?** The `documentation` field is the first thing read at 3 a.m.

## On-call itself

The shop has two people. Each takes a week of on-call in turn, with the other as the second level if the first
does not acknowledge within fifteen minutes. A week with more than two night pages is reviewed the following
Monday, policy by policy, with this lesson's four questions, and a page that arrived and needed nothing is a
defect in a policy, fixed like a defect in the code. The next lesson is what happens when a page does need
somebody.
