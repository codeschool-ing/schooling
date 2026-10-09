---
title: A register of every place a model is used
version: 1
---

Twenty-four lessons built controls around one assistant. A company the size of Tarefa does not have
one: it has the assistant, a classifier, a summary for disputes, a feature that drafts proposals for
freelancers, and whatever somebody in marketing tried on a Tuesday afternoon. **Governance starts
with knowing what exists**, because a control cannot protect a system nobody knows is running.

## What each entry says

The register is one file, kept in the repository like everything else in `~/guard`. Each system
names an owner, the provider and model it calls, the project it is billed under, whether it handles
personal data and on what legal basis, where its threat model is, and when it was last reviewed. The
file also lists the staff and the providers lesson 19 assessed, so the checks have something to
compare against. Paste it:

```sh
cat > ~/guard/data/ai-register.json <<'EOF'
{
 "staff": ["ana.lima", "bruno.alves", "diego.rocha"],
 "assessed": ["local", "provider-c"],
 "systems": [
  {"name": "support-assistant", "owner": "ana.lima", "provider": "local", "model": "llama3.2:3b",
   "project": "assistant", "personal_data": true, "legal_basis": "contract, art. 7 V",
   "threat_model": "data/threats.json", "last_review": "2026-10-01"},
  {"name": "ticket-classifier", "owner": "bruno.alves", "provider": "local", "model": "llama3.2:3b",
   "project": "classifier", "personal_data": true, "legal_basis": "contract, art. 7 V",
   "threat_model": "data/threats.json", "last_review": "2026-10-09"},
  {"name": "dispute-summary", "owner": "carla.dias", "provider": "provider-c", "model": "c-large-2026-03",
   "project": "disputes", "personal_data": true, "legal_basis": "contract, art. 7 V",
   "threat_model": "data/threats.json", "last_review": "2025-08-14"},
  {"name": "proposal-drafting", "owner": "diego.rocha", "provider": "provider-c", "model": "c-small-2026-03",
   "project": "proposals", "personal_data": true, "legal_basis": null,
   "threat_model": null, "last_review": "2026-06-30"}
 ]
}
EOF
```

A register that is only a list goes stale the week after it is written. What keeps it honest is a
check that compares it with things that change on their own: the staff list changes when somebody
leaves, the calendar moves, and the provider's bill lists every project that spent money, whether or
not anybody wrote it down. September's bill from `provider-c`, by project; paste it:

```sh
cat > ~/guard/data/invoice-provider-c.json <<'EOF'
{"provider": "provider-c", "month": "2026-09", "currency": "BRL",
 "projects": [
  {"project": "disputes", "cents": 18240},
  {"project": "proposals", "cents": 40110},
  {"project": "growth-test", "cents": 9870}
 ]}
EOF
```

Save the check as `~/guard/tools/register.py`:

```python
# register.py: every place Tarefa uses a model, and what each one is missing.
#
#   guard register --now DATE [--invoice FILE ...]
#
# data/ai-register.json lists the staff, the providers lesson 19 assessed,
# and every system that calls a model. Each system is checked for:
#
#   OWNER     no owner, or an owner who is no longer on the staff list
#   REVIEW    no review in the last 365 days
#   BASIS     personal data with no legal basis written down (lesson 12)
#   THREATS   no threat model (lesson 13)
#   PROVIDER  a provider nobody assessed (lesson 19)
#
# Each --invoice is a provider's bill, by project. A project billed and not in
# the register is a system nobody registered, and is reported as UNREGISTERED.
# The exit status is 1 while anything is reported.
import argparse
import datetime as dt
import json
import os

p = argparse.ArgumentParser(prog="guard register")
p.add_argument("--now", required=True)
p.add_argument("--invoice", action="append", default=[])
a = p.parse_args()
now = dt.date.fromisoformat(a.now)

with open(os.path.expanduser("~/guard/data/ai-register.json"), encoding="utf-8") as f:
    reg = json.load(f)

bad = 0
for s in reg["systems"]:
    found = []
    if not s.get("owner") or s["owner"] not in reg["staff"]:
        found.append("OWNER %s is not on the staff list" % s.get("owner"))
    age = (now - dt.date.fromisoformat(s["last_review"])).days
    if age > 365:
        found.append("REVIEW last %s, %d days ago" % (s["last_review"], age))
    if s["personal_data"] and not s.get("legal_basis"):
        found.append("BASIS personal data, no legal basis")
    if not s.get("threat_model"):
        found.append("THREATS no threat model")
    if s["provider"] not in reg["assessed"]:
        found.append("PROVIDER %s was never assessed" % s["provider"])
    bad += bool(found)
    print("%-18s %-12s %s" % (s["name"], s.get("owner") or "-", "; ".join(found) or "ok"))

known = {(s["provider"], s["project"]) for s in reg["systems"]}
total = len(reg["systems"])
for path in a.invoice:
    with open(path, encoding="utf-8") as f:
        bill = json.load(f)
    for line in bill["projects"]:
        if (bill["provider"], line["project"]) not in known:
            total += 1
            bad += 1
            print("%-18s %-12s UNREGISTERED billed by %s for %s: %s %d.%02d" % (
                line["project"], "-", bill["provider"], bill["month"], bill["currency"],
                line["cents"] // 100, line["cents"] % 100))
print("%d systems, %d with problems" % (total, bad))
raise SystemExit(1 if bad else 0)
```

```
ana@lab:~/guard$ guard register --now 2026-10-09 --invoice data/invoice-provider-c.json; echo "exit status $?"
support-assistant  ana.lima     ok
ticket-classifier  bruno.alves  ok
dispute-summary    carla.dias   OWNER carla.dias is not on the staff list; REVIEW last 2025-08-14, 421 days ago
proposal-drafting  diego.rocha  BASIS personal data, no legal basis; THREATS no threat model
growth-test        -            UNREGISTERED billed by provider-c for 2026-09: BRL 98.70
5 systems, 3 with problems
exit status 1
```

## Three kinds of gap

**An owner who left.** Carla wrote the dispute summary and moved on; the register still names her,
so the system has no owner and nobody noticed, because nothing about it broke. It has not been
reviewed for 421 days either, which is the same problem seen from the calendar: an owner is the
person who would have scheduled the review.

**A system registered without its homework.** The proposal drafter sends freelancers' profiles to a
provider and has no legal basis written down and no threat model. Lesson 12's question, *on what
basis?*, and lesson 13's, *where does the data cross a boundary?*, were never asked. Both fields
exist in the register; neither was ever filled in.

**A system nobody registered.** `growth-test` cost R$ 98,70 in September and appears nowhere else.
Somebody, probably with good intentions, gave a provider key to an experiment. What it sends, whether
it touches personal data, and whether lesson 8's review of marketing use cases applies, nobody at
Tarefa can say. **The bill is the one inventory that cannot be forgotten**, because the provider
writes it, so it is the right thing to compare the register against. Each provider's key should be
issued per project, as lesson 17 did per component, precisely so the bill can be read this way.

The exit status is 1, so this check joins lesson 23's suite, with each finding as a known failure
with an owner and a date.
