---
title: Every key narrow, short-lived and written down
version: 1
---

The scanner finds credentials that are in the wrong place. A second set of questions is about the
credentials themselves, wherever they are kept: **what each one may do, who uses it, and how old it
is.** Those questions need an inventory, one line per key. Tarefa's, written by the course:

```sh
cat > ~/guard/data/keys.json <<'EOF'
{
 "max_age_days": 90,
 "needs": {
  "assistant": ["chat"],
  "issue_refund": ["refund"],
  "lookup_order": ["read"],
  "call-log": ["write"]
 },
 "keys": [
  {"name": "provider-api", "kept_in": "secret store", "used_by": ["assistant"], "scope": ["chat"], "rotated": "2026-09-01"},
  {"name": "payments", "kept_in": "source code", "used_by": ["issue_refund"], "scope": ["refund", "payout", "read"], "rotated": "2025-11-02"},
  {"name": "orders-db", "kept_in": "secret store", "used_by": ["lookup_order"], "scope": ["read", "write"], "rotated": "2026-08-20"},
  {"name": "log-store", "kept_in": "secret store", "used_by": ["call-log"], "scope": ["write"], "rotated": "2026-04-12"}
 ]
}
EOF
```

`needs` says what each component of the assistant has to be able to do, from lesson 10's manifest:
the refund tool refunds, the order lookup reads. The program holds every key to three rules. Save it
as `~/guard/tools/keys.py`:

```python
# keys.py: the inventory of Tarefa's credentials against three rules.
#
#   guard keys --now DATE
#
# data/keys.json lists every key: where it is kept, which components use it,
# what it is allowed to do, and when it was last rotated; and, per component,
# what that component needs. Each key is checked for:
#
#   KEPT   it lives anywhere but the secret store
#   SCOPE  it may do more than every component using it needs
#   AGE    it was last rotated more than max_age_days ago
#
# The exit status is 1 while any key breaks a rule.
import argparse
import datetime as dt
import json
import os

p = argparse.ArgumentParser(prog="guard keys")
p.add_argument("--now", required=True)
a = p.parse_args()
now = dt.date.fromisoformat(a.now)

with open(os.path.expanduser("~/guard/data/keys.json"), encoding="utf-8") as f:
    inv = json.load(f)

broken = 0
for k in inv["keys"]:
    problems = []
    if k["kept_in"] != "secret store":
        problems.append("KEPT   in %s" % k["kept_in"])
    needed = set()
    for user in k["used_by"]:
        needed |= set(inv["needs"][user])
    extra = [s for s in k["scope"] if s not in needed]
    if extra:
        problems.append("SCOPE  %s unused by %s" % (", ".join(extra), ", ".join(k["used_by"])))
    age = (now - dt.date.fromisoformat(k["rotated"])).days
    if age > inv["max_age_days"]:
        problems.append("AGE    %d days since rotation, limit %d" % (age, inv["max_age_days"]))
    broken += bool(problems)
    print("%-13s %s" % (k["name"], problems[0] if problems else "ok"))
    for pr in problems[1:]:
        print("%-13s %s" % ("", pr))
print("%d keys, %d breaking a rule" % (len(inv["keys"]), broken))
raise SystemExit(1 if broken else 0)
```

```
ana@lab:~/guard$ guard keys --now 2026-10-09; echo "exit status $?"
provider-api  ok
payments      KEPT   in source code
              SCOPE  payout, read unused by issue_refund
              AGE    341 days since rotation, limit 90
orders-db     SCOPE  write unused by lookup_order
log-store     AGE    180 days since rotation, limit 90
4 keys, 3 breaking a rule
exit status 1
```

Three of four keys break a rule, and the payments key breaks all three.

- **KEPT.** It lives in the source code, the finding of the first section from the other side. A key
  in the code is a key in every clone.
- **SCOPE.** It may refund, pay freelancers out and read accounts, and the only component using it
  refunds. A leaked payments key that could only refund would be bad; one that can send payouts is
  worse, and nothing gained from that wider scope. **A key gets the permissions of the narrowest
  component that uses it**, which is least privilege applied to credentials as lesson 10 applied it to
  tools. The orders database user may write, and the lookup only reads.
- **AGE.** It was last rotated 341 days ago against a limit of 90. A key that has never been rotated
  is a key nobody knows how to rotate, and the day it leaks is a bad day to find out.

The limit of 90 days is a policy, not a law of nature; some teams rotate weekly through automation,
some yearly. The rule that matters is that there is a limit, a date on every key and a program that
reads the date. `log-store` breaks only that one, at 180 days, and it is the kind of finding a
quarterly review misses because the key works perfectly.

## What the inventory is for

The inventory answers the question an incident asks first, which is lesson 24's subject: **this key
leaked; what can somebody do with it, and what breaks when we revoke it?** `scope` answers the first
half and `used_by` the second. A team without the list answers both by searching the code, during the
incident, under pressure. The exit status of 1 lets `keys.py` run in the build like every other check
here, so a key that passes its date fails a pull request before it becomes a finding nobody owns.
