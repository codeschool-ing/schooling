---
title: Who is asking for the key
version: 2
---

Tarefa is about to open its assistant to other companies through an API: a bakery that wants it to
answer customers, a translation agency, a law firm. Each one gets a key, and the key reaches
Tarefa's model provider through Tarefa's own account. **Whatever a customer does with that key, the
provider sees Tarefa doing**, and Tarefa's agreement with its provider, like most of them, makes
Tarefa answerable for how its own customers use the access. Lesson 7 was about telling Tarefa's
users apart; this lesson is about deciding which companies become users at all.

The usual first instinct is that a signup form and a credit card are enough, since anybody who pays
is a customer. The trouble is that people who want to abuse a model at scale prefer to do it
**through somebody else's account**, so that the warning, the bill and the ban land elsewhere. An API
that hands out keys to anybody with a card becomes exactly that account.

## What Tarefa checks

An application is one line of JSON with a company, its CNPJ, a contact address, a website and the use
case it declares. Eight of them, written by the course for companies it invented:

```sh
cat > ~/guard/data/applications.jsonl <<'EOF'
{"id": "ap-01", "company": "Doce Lar Confeitaria", "cnpj": "45.781.296/0001-63", "contact": "ana@docelar.example", "website": "docelar.example", "use_case": "customer-support", "description": "Answer our customers' questions about orders, delivery times and opening hours."}
{"id": "ap-02", "company": "Contrata Já RH", "cnpj": "23.045.678/0001-96", "contact": "talentos@contrataja.example", "website": "contrataja.example", "use_case": "hiring-screening", "description": "Rank CVs for our clients' job openings and reject the weakest automatically."}
{"id": "ap-03", "company": "Avalia+ Marketing", "cnpj": "38.901.745/0001-02", "contact": "contato@avaliamais.example", "website": "avaliamais.example", "use_case": "marketing-copy", "description": "Write 5-star reviews of our clients' products to post on marketplaces."}
{"id": "ap-04", "company": "Nuvem Tradutora", "cnpj": "61.527.384/0001-90", "contact": "nuvem.tradutora@webmail.example", "website": "nuvemtradutora.example", "use_case": "translation", "description": "Translate product manuals from English into Portuguese."}
{"id": "ap-05", "company": "Clínica Bem Viver", "cnpj": "70.491.836/0001-11", "contact": "ti@bemviver.example", "website": "bemviver.example", "use_case": "health-information", "description": "Answer patients' questions about their symptoms before an appointment."}
{"id": "ap-06", "company": "Disparo Total", "cnpj": "52.836.417/0001-92", "contact": "vendas@disparototal.example", "website": "disparototal.example", "use_case": "mass-messaging", "description": "Send personalised WhatsApp messages to 200 thousand leads a day."}
{"id": "ap-07", "company": "Studio Pixel", "cnpj": "19.384.756/0001-01", "contact": "oi@studiopixel.example", "website": "studiopixel.example", "use_case": "customer-support", "description": "Answer questions from our design clients about invoices and deadlines."}
{"id": "ap-08", "company": "Lima Advocacia", "cnpj": "11.222.333/0001-81", "contact": "socios@limaadv.example", "website": "limaadv.example", "use_case": "legal-drafting", "description": "Draft first versions of contracts, which one of our lawyers reviews before use."}
EOF
```

```
ana@lab:~/guard$ head -1 data/applications.jsonl
{"id": "ap-01", "company": "Doce Lar Confeitaria", "cnpj": "45.781.296/0001-63", "contact": "ana@docelar.example", "website": "docelar.example", "use_case": "customer-support", "description": "Answer our customers' questions about orders, delivery times and opening hours."}
```

The first check is arithmetic. A CNPJ carries two check digits, computed from the twelve before
them, and a number typed wrong almost always fails. The rules of this lesson live in one module,
`~/guard/tools/kyc.py`, and `guard cnpj` runs the first of them:

```python
# kyc.py: deciding which companies get a key to the model.
#
# The policy is in data/use-cases.json; data/cnpj-registry.json stands in for
# the Receita Federal's public CNPJ data, which a real check would query. The
# CNPJ check digits are the real algorithm. Every decision names each rule
# that made it, so that a refusal can be explained to the company refused.
# cnpj.py and onboard.py import it; it prints nothing on its own.
import datetime as dt
import re

YOUNG = 180  # days: a company this new has no history to judge by


def cnpj_ok(cnpj):
    d = [int(c) for c in cnpj if c.isdigit()]
    if len(d) != 14 or len(set(d)) == 1:
        return False
    for n, w in ((12, [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]),
                 (13, [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2])):
        r = sum(x * y for x, y in zip(d[:n], w)) % 11
        if d[n] != (0 if r < 2 else 11 - r):
            return False
    return True


def domain(address):
    return address.split("@")[-1].lower()


def onboard(app, registry, use_cases, now):
    """(decision, tier, reasons). Every check runs, so the reasons list
    everything that is wrong, not only the first thing."""
    reasons, stop, review = [], False, False
    if not cnpj_ok(app["cnpj"]):
        reasons.append("CNPJ check digits are wrong")
        stop = True
    elif app["cnpj"] not in registry:
        reasons.append("CNPJ not in the registry")
        stop = True
    elif registry[app["cnpj"]]["status"] != "ATIVA":
        reasons.append("CNPJ status is %s" % registry[app["cnpj"]]["status"])
        stop = True
    else:
        age = (now - dt.date.fromisoformat(registry[app["cnpj"]]["opened"])).days
        if age < YOUNG:
            reasons.append("company opened %d days ago" % age)
    if domain(app["contact"]) != domain(app["website"]):
        reasons.append("contact %s is not at %s" % (domain(app["contact"]), app["website"]))
    case = app["use_case"]
    if case in use_cases["prohibited"]:
        reasons.append("use case %s is prohibited" % case)
        stop = True
    elif case in use_cases["review"]:
        reasons.append("use case %s needs a person to approve it" % case)
        review = True
    elif case not in use_cases["allowed"]:
        reasons.append("use case %s is on no list" % case)
        review = True
    hits = [m.group(0) for m in (re.search(p, app["description"], re.I)
                                 for p in use_cases["prohibited_phrases"]) if m]
    if hits:
        reasons.append("description says \"%s\", a prohibited use" % "\", \"".join(hits))
        review = True
    if stop:
        return "REFUSE", "-", reasons
    if review:
        return "REVIEW", "sandbox", reasons
    if reasons:
        return "VERIFY", "sandbox", reasons
    return "ACCEPT", "tier-1", ["all checks passed"]
```

```python
# cnpj.py: whether a CNPJ's two check digits are right.
#
#   guard cnpj NUMBER
import sys

from kyc import cnpj_ok

ok = cnpj_ok(sys.argv[1])
print("%s  check digits %s" % (sys.argv[1], "right" if ok else "WRONG"))
sys.exit(0 if ok else 1)
```

```
ana@lab:~/guard$ guard cnpj 19.384.756/0001-01
19.384.756/0001-01  check digits WRONG
ana@lab:~/guard$ guard cnpj 19.384.756/0001-00
19.384.756/0001-00  check digits right
```

The arithmetic says the number is well formed, not that the company exists. The second check asks the
registry. The Receita Federal publishes CNPJ data, including the registration status and the date the
company was opened. `data/cnpj-registry.json` is a short stand-in for it, written by the course,
because nothing in this course reaches the network. Then two cheaper signals: whether the contact
address is at the company's own domain, and how long ago the company was opened. The use case is read
against a policy, which the next section is about. Paste the registry and the policy:

```sh
cat > ~/guard/data/cnpj-registry.json <<'EOF'
{
"45.781.296/0001-63": {"status": "ATIVA", "opened": "2019-03-12"},
"23.045.678/0001-96": {"status": "ATIVA", "opened": "2021-07-01"},
"38.901.745/0001-02": {"status": "ATIVA", "opened": "2026-08-20"},
"61.527.384/0001-90": {"status": "ATIVA", "opened": "2017-11-30"},
"70.491.836/0001-11": {"status": "ATIVA", "opened": "2012-05-08"},
"52.836.417/0001-92": {"status": "INAPTA", "opened": "2020-02-14"},
"19.384.756/0001-00": {"status": "ATIVA", "opened": "2023-04-03"},
"11.222.333/0001-81": {"status": "ATIVA", "opened": "2009-09-21"}
}
EOF
cat > ~/guard/data/use-cases.json <<'EOF'
{
 "allowed": [
  "customer-support",
  "translation",
  "proposal-drafting"
 ],
 "review": [
  "hiring-screening",
  "health-information",
  "legal-drafting",
  "marketing-copy"
 ],
 "prohibited": [
  "mass-messaging",
  "fake-reviews",
  "impersonation",
  "tracking-individuals"
 ],
 "prohibited_phrases": [
  "5-star reviews?",
  "fake",
  "impersonat",
  "without (their )?consent",
  "track (a|one) person"
 ]
}
EOF
```

And the program that runs every rule over every application, `~/guard/tools/onboard.py`:

```python
# onboard.py: applications for API access, each decided with its reasons.
#
#   guard onboard FILE [--id ID] [--now YYYY-MM-DD]
#
# FILE has one application per line, as JSON. --now is the day they are
# judged on, so that a company's age is the same on every run.
import argparse
import datetime as dt
import json
import os

from kyc import onboard

p = argparse.ArgumentParser(prog="guard onboard")
p.add_argument("file")
p.add_argument("--id")
p.add_argument("--now")
a = p.parse_args()

data = os.path.expanduser("~/guard/data/")
with open(data + "cnpj-registry.json") as f:
    registry = json.load(f)
with open(data + "use-cases.json") as f:
    use_cases = json.load(f)
now = dt.date.fromisoformat(a.now) if a.now else dt.date.today()

with open(a.file, encoding="utf-8") as f:
    for line in f:
        if not line.strip():
            continue
        app = json.loads(line)
        if a.id and app["id"] != a.id:
            continue
        decision, tier, reasons = onboard(app, registry, use_cases, now)
        print("%-5s  %-22s %-7s %-8s %s" % (app["id"], app["company"], decision, tier, reasons[0]))
        for r in reasons[1:]:
            print("%-5s  %-22s %-7s %-8s %s" % ("", "", "", "", r))
```

Here are all eight applications, judged on 30 September 2026:

```
ana@lab:~/guard$ guard onboard data/applications.jsonl --now 2026-09-30
ap-01  Doce Lar Confeitaria   ACCEPT  tier-1   all checks passed
ap-02  Contrata Já RH         REVIEW  sandbox  use case hiring-screening needs a person to approve it
ap-03  Avalia+ Marketing      REVIEW  sandbox  company opened 41 days ago
                                               use case marketing-copy needs a person to approve it
                                               description says "5-star reviews", a prohibited use
ap-04  Nuvem Tradutora        VERIFY  sandbox  contact webmail.example is not at nuvemtradutora.example
ap-05  Clínica Bem Viver      REVIEW  sandbox  use case health-information needs a person to approve it
ap-06  Disparo Total          REFUSE  -        CNPJ status is INAPTA
                                               use case mass-messaging is prohibited
ap-07  Studio Pixel           REFUSE  -        CNPJ check digits are wrong
ap-08  Lima Advocacia         REVIEW  sandbox  use case legal-drafting needs a person to approve it
```

Each decision names every rule that produced it, not only the first, so that a refusal can be
explained to the company and a mistake can be fixed. Studio Pixel typed its CNPJ with the last digit
wrong; the registry has the right one, and the refusal tells them which check failed. Disparo Total
is refused twice over: the Receita lists it as *inapta*, a status it gives, among other reasons, to a
company that has stopped filing the declarations it must file; and its use case is prohibited, which
is the next section.

## Signals, not proofs

None of these checks proves that a company is honest. A real CNPJ can be bought with the company that
owns it, a domain costs little, and a company opened 41 days ago may be a perfectly good start-up.
Each signal raises the cost of lying a little, and **what they decide is how much the company starts
with**, not whether it is trustworthy forever. That is why Nuvem Tradutora, whose contact is at a
webmail address rather than at its own domain, gets `VERIFY` and a sandbox rather than a refusal:
confirming the address at the domain fixes it.

The data collected here is personal data too, the contact's name and address at least, and lesson 12
applies to it like anything else: collect what the decision needs, and say why.
