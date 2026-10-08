---
title: Trust that grows, and use that drifts
version: 2
---

Every check in this lesson so far happens once, on the day of the application, and a company is not
the same thing on the day it applies and six months later. Two mechanisms carry the decision forward
in time: **limits that grow with a clean history**, and **a comparison between what a company declared
and what it does**.

## Tiers

The tiers are a small file of their own:

```sh
cat > ~/guard/data/tiers.json <<'EOF'
{
 "sandbox": {
  "requests_a_day": 100,
  "what": "test data only, no end users"
 },
 "tier-1": {
  "requests_a_day": 5000,
  "needs": "an accepted application"
 },
 "tier-2": {
  "requests_a_day": 50000,
  "needs": "60 days at tier-1 with no incident, and a person reviewing the usage"
 }
}
EOF
```

```
ana@lab:~/guard$ cat data/tiers.json
{
 "sandbox": {
  "requests_a_day": 100,
  "what": "test data only, no end users"
 },
 "tier-1": {
  "requests_a_day": 5000,
  "needs": "an accepted application"
 },
 "tier-2": {
  "requests_a_day": 50000,
  "needs": "60 days at tier-1 with no incident, and a person reviewing the usage"
 }
}
```

A new customer, even an accepted one, starts at 5,000 requests a day, and a customer under review
starts in the sandbox with 100 and test data. The step to 50,000 needs two things: sixty days without
an incident, and a person looking at what the customer actually did with the first tier. The numbers
are the course's, but the shape is common to providers and to the platforms built on them: the
damage a key can do is bounded by what it is allowed, so a key that nobody knows yet is allowed
little.

The tier is also the lever when something goes wrong. A customer whose use is in question can be
moved back to the sandbox, where the product keeps working for testing and nothing reaches end
users, which is a much smaller decision to take than a suspension.

## Drift

Doce Lar Confeitaria was accepted on the first day: a real CNPJ, its own domain, and customer support
as its use case. Its usage is logged by week with the topic of each request. **The topics were written
by the course** as a classifier would label them; a real one is a classifier like those in lesson 6,
with errors of its own. Four weeks of it, and the program that compares each week with the declared use
case, `~/guard/tools/drift.py`:

```sh
cat > ~/guard/data/partner-usage.jsonl <<'EOF'
{"account": "p-docelar", "week": "2026-W33", "topic": "customer-support", "requests": 2016}
{"account": "p-docelar", "week": "2026-W33", "topic": "other", "requests": 84}
{"account": "p-docelar", "week": "2026-W34", "topic": "customer-support", "requests": 2128}
{"account": "p-docelar", "week": "2026-W34", "topic": "other", "requests": 112}
{"account": "p-docelar", "week": "2026-W35", "topic": "customer-support", "requests": 2262}
{"account": "p-docelar", "week": "2026-W35", "topic": "product-reviews", "requests": 1521}
{"account": "p-docelar", "week": "2026-W35", "topic": "other", "requests": 117}
{"account": "p-docelar", "week": "2026-W36", "topic": "customer-support", "requests": 2058}
{"account": "p-docelar", "week": "2026-W36", "topic": "product-reviews", "requests": 7546}
{"account": "p-docelar", "week": "2026-W36", "topic": "other", "requests": 196}
EOF
```

```python
# drift.py: a customer's weekly usage against the use case it declared.
#
#   guard drift ACCOUNT [--limit PCT]
#
# It reads data/partner-usage.jsonl, one line per account, week and topic, and
# flags a week in which more than PCT percent of the requests fell outside
# the declared use case.
import argparse
import json
import os

DECLARED = {"p-docelar": "customer-support"}

p = argparse.ArgumentParser(prog="guard drift")
p.add_argument("account")
p.add_argument("--limit", type=int, default=30)
a = p.parse_args()
declared = DECLARED[a.account]

weeks = {}
with open(os.path.expanduser("~/guard/data/partner-usage.jsonl")) as f:
    for line in f:
        r = json.loads(line)
        if r["account"] == a.account:
            weeks.setdefault(r["week"], {})[r["topic"]] = r["requests"]

print("%s declared: %s" % (a.account, declared))
print("week       requests  in use case  outside  largest outside")
for week, topics in weeks.items():
    n = sum(topics.values())
    inside = topics.get(declared, 0)
    out = {t: k for t, k in topics.items() if t != declared}
    top = max(out, key=out.get) if out else "-"
    share = 100 * (n - inside) / n
    print("%s  %8d  %10.0f%%  %6.0f%%  %s%s" % (
        week, n, 100 * inside / n, share, top, "  DRIFT" if share > a.limit else ""))
print("limit: more than %d%% of a week outside the declared use case" % a.limit)
```

```
ana@lab:~/guard$ guard drift p-docelar
p-docelar declared: customer-support
week       requests  in use case  outside  largest outside
2026-W33      2100          96%       4%  other
2026-W34      2240          95%       5%  other
2026-W35      3900          58%      42%  product-reviews  DRIFT
2026-W36      9800          21%      79%  product-reviews  DRIFT
limit: more than 30% of a week outside the declared use case
```

For two weeks, 95% or more of the bakery's requests are customer support. In the third week, 42% are
something else, and the largest something else is `product-reviews`. In the fourth, it is 79%, and
the volume has more than quadrupled since the second week, from 2,240 to 9,800 requests. Both signals point the same way:
the key is now mostly writing reviews of products, which is the fake-reviews use the policy
prohibits. Reviews written by the seller and posted as if by customers mislead the people who read
them, which is what the Consumer Defence Code forbids in advertising (art. 37), and they break the
rules of every marketplace they are posted on.

What happens next is a ladder rather than a switch:

1. **Ask.** A message to the customer, quoting the numbers. A use case can change for a legitimate
   reason, such as a bakery that starts writing product descriptions, which a classifier might
   label as reviews.
2. **Restrict.** Back to the sandbox while the answer is pending, if the numbers are as large as
   week 36's.
3. **Suspend.** If the answer confirms a prohibited use, or does not come.

Every step is recorded with who took it and why, and the numbers that justified it go with the
record. The same discipline as lesson 3 and lesson 6 applies here: **the threshold, 30% in this course,
is a choice**, written down with its reason and revisited when it fires on customers who turned out to
be fine.

## Where this leaves the defences

Lesson 7 made every request carry a person's identifier; this lesson makes every key carry a known
company and a declared purpose; lesson 9 restricts what any single request may put in and get out.
None of the three is enough alone, and an attacker has to get past all of them at once.
