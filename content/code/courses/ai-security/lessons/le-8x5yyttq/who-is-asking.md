---
title: Who is asking for the key
version: 1
---

Tarefa is about to open its assistant to other companies through an API: a bakery that wants it to
answer customers, a translation agency, a law firm. Each one gets a key, and the key reaches
Tarefa's model provider through Tarefa's own account. **Whatever a customer does with that key, the
provider sees Tarefa doing**, and Tarefa's agreement with its provider, like most of them, makes
Tarefa answerable for how its own customers use the access. Lesson 17 was about telling Tarefa's
users apart; this lesson is about deciding which companies become users at all.

The usual first instinct is that a signup form and a credit card are enough, since anybody who pays
is a customer. The trouble is that people who want to abuse a model at scale prefer to do it
**through somebody else's account**, so that the warning, the bill and the ban land elsewhere. An API
that hands out keys to anybody with a card becomes exactly that account.

## What the lab checks

An application in the lab is one line of JSON, written by the course, with a company, its CNPJ, a
contact address, a website and the use case it declares:

```
ana@lab:~/guard$ head -1 data/applications.jsonl
{"id": "ap-01", "company": "Doce Lar Confeitaria", "cnpj": "45.781.296/0001-63", "contact": "ana@docelar.example", "website": "docelar.example", "use_case": "customer-support", "description": "Answer our customers' questions about orders, delivery times and opening hours."}
```

The first check is arithmetic. A CNPJ carries two check digits, computed from the twelve before
them, and a number typed wrong almost always fails:

```
ana@lab:~/guard$ guard cnpj 19.384.756/0001-01
19.384.756/0001-01  check digits WRONG
ana@lab:~/guard$ guard cnpj 19.384.756/0001-00
19.384.756/0001-00  check digits right
```

The arithmetic says the number is well formed, not that the company exists. The second check asks the
registry. The Receita Federal publishes CNPJ data, including the registration status and the date the
company was opened; the lab's `data/cnpj-registry.json` is a short stand-in for it, written by the
course, because nothing in the lab reaches the network. Then two cheaper signals: whether the contact
address is at the company's own domain, and how long ago the company was opened. Here are all eight
applications, judged on 30 September 2026:

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

The data collected here is personal data too, the contact's name and address at least, and lesson 22
applies to it like anything else: collect what the decision needs, and say why.
