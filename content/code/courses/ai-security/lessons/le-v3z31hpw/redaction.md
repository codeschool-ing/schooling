---
title: Redacting before the record is written
version: 2
---

**Redaction belongs on the way in, before the record reaches any store.** Redacting a log after it
has been written leaves a window in which the unredacted copy exists, and in that window it is
backed up, shipped to a log vendor, indexed for search and read by whoever was debugging. Each of
those is a copy the later redaction never reaches. In `~/guard`, `tiers.py` makes the redacted tier
with the same function `guard redact` calls, and in a real application that call happens at the moment
the record is written.

Before redacting anything, measure what is there. `guard scan` runs the five detectors of
`detect.py` over the text of every record, both the prompt and the output. Save it as
`~/guard/tools/scan.py`:

```python
# scan.py: how many records in a log hold personal data or a secret, by kind.
#
#   guard scan [--show] [--strict] PATH...
#
# PATH is a log file or a directory of them. Both the prompt and the output
# of every record are read. --show lists every match and what was decided:
# redact, or LEAVE for a shape whose check digits are wrong.
import argparse
import json
import os
from collections import Counter

from detect import KINDS, find

p = argparse.ArgumentParser(prog="guard scan")
p.add_argument("paths", nargs="+")
p.add_argument("--show", action="store_true")
p.add_argument("--strict", action="store_true")
a = p.parse_args()

files = []
for path in a.paths:
    if os.path.isdir(path):
        files += sorted(os.path.join(path, n) for n in os.listdir(path) if n.endswith(".jsonl"))
    else:
        files.append(path)

held, shaped, total, hit = Counter(), Counter(), 0, 0
for name in files:
    with open(name, encoding="utf-8") as f:
        for rec in map(json.loads, f):
            total += 1
            kinds, rejected = set(), set()
            for field in ("prompt", "output"):
                for kind, x, y, ok in find(rec[field], a.strict):
                    (kinds if ok else rejected).add(kind)
                    if a.show:
                        print("%s  %-6s  %-6s  %-8s %s" % (rec["request"], field, kind,
                                                          "redact" if ok else "LEAVE", rec[field][x:y]))
            held.update(kinds)
            shaped.update(rejected)
            hit += bool(kinds)
if a.show:
    print()
print("%d records in %d files" % (total, len(files)))
for kind in KINDS:
    line = "  %-7s %2d records" % (kind, held[kind])
    if shaped[kind]:
        line += "   (%d more %s-shaped, check digits wrong)" % (
            shaped[kind], kind.upper() if kind == "cpf" else kind)
    print(line)
print("%d of %d records hold at least one" % (hit, total))
```

```
ana@lab:~/guard$ guard scan logs/raw
22 records in 19 files
  secret   2 records
  email    3 records
  phone    2 records
  card     1 records   (1 more card-shaped, check digits wrong)
  cpf      4 records   (1 more CPF-shaped, check digits wrong)
11 of 22 records hold at least one
```

Half the log. These are records of a support assistant that never asked anybody for a document
number, and the proportion is the course's invention, but the shape is what teams find when they
first look: people paste what they are asked about, and they are asked about their accounts.

## A shape, and then arithmetic

Each detector is a pattern for a shape: eleven digits punctuated like a CPF, thirteen to nineteen
digits like a card. A shape alone is a poor test, because order numbers and tracking codes have
the same shapes. **A CPF and a card number carry their own check digits**, so the detector checks
the arithmetic too, and leaves alone the numbers that fail it. `--show` lists every match and what
was decided:

```
ana@lab:~/guard$ guard scan --show logs/raw
rq-0001  prompt  email   redact   marcos.teixeira@example.com.br
rq-0003  prompt  cpf     redact   529.982.247-25
rq-0004  prompt  cpf     LEAVE    123.456.789-00
rq-0004  output  cpf     LEAVE    123.456.789-00
rq-0005  prompt  card    redact   4111 1111 1111 1111
rq-0006  prompt  phone   redact   +55 11 98765-4321
rq-0008  prompt  secret  redact   sk-lab-EXAMPLE7fQ2mX9pL4vT8nR1wZ6
rq-0010  prompt  card    LEAVE    1234 5678 9012 3456
rq-0011  prompt  email   redact   fernanda.rocha@example.com
rq-0013  prompt  cpf     redact   111.444.777-35
rq-0017  prompt  phone   redact   (21) 99876-5432
rq-0018  prompt  secret  redact   AKIAIOSFODNN7EXAMPLE
rq-0019  prompt  cpf     redact   390.533.447-05
rq-0021  prompt  email   redact   marcos.t@example.org
rq-0021  prompt  cpf     redact   714.602.380-01

22 records in 19 files
  secret   2 records
  email    3 records
  phone    2 records
  card     1 records   (1 more card-shaped, check digits wrong)
  cpf      4 records   (1 more CPF-shaped, check digits wrong)
11 of 22 records hold at least one
```

`123.456.789-00` in `rq-0004` is an order number written like a CPF, and its check digits are
wrong, so it stays. Keeping it matters more than it seems: an order number is what a person
debugging the conversation needs to find the order, and a log redacted into a row of `[CPF]`s
answers no questions at all. `1234 5678 9012 3456` in `rq-0010` is a parcel's tracking code and
fails the Luhn check that every card number passes.

Note that `rq-0004` matched in the output as well as the prompt. **The model repeats what it is
told**, so the output is as likely to carry personal data as the prompt, and a redactor that reads
only the prompt protects half the record.

The arithmetic has a cost, and `--strict` shows it by dropping the check and redacting every shape:

```
ana@lab:~/guard$ guard scan --strict logs/raw
22 records in 19 files
  secret   2 records
  email    3 records
  phone    2 records
  card     2 records
  cpf      5 records
13 of 22 records hold at least one
```

Two more records lose a number. In this log both were harmless, but a client who types their CPF
with one digit wrong produces a number that fails the check and is most of their CPF. Which way to
lean is a decision about the log: a tier only a handful of people can read may keep the order
numbers, and one that goes to an outside vendor may lose them.

## What a pattern cannot see

Redaction replaces what it recognises, and it recognises shapes. Three records in this log show
what falls outside every shape:

```
ana@lab:~/guard$ guard redact logs/raw/2026-09-29.jsonl
rq-0021  prompt  My new e-mail is [EMAIL] and the CPF on file [CPF] is right
         output  Thanks. The e-mail change needs confirming from the new address; your CPF is unchanged.
rq-0022  prompt  Ok, my number is 21 99876 5432 if the freelancer needs it
         output  Contact details are shared with the freelancer automatically once you accept a proposal, so there's no need to send them here.
ana@lab:~/guard$ guard redact logs/raw/2026-07-28.jsonl
rq-0012  prompt  Write a short bio. Rafael Moreira, backend developer, lives at Rua das Flores 120, Curitiba
         output  Rafael Moreira is a backend developer based in Curitiba who builds reliable APIs...
ana@lab:~/guard$ guard redact logs/raw/2026-04-21.jsonl
rq-0005  prompt  Pay with this card: [CARD], expiry 08/29, CVV 123
         output  Please don't send card details in chat. Use the Payment page, which never shows the number to anybody here.
```

- `rq-0022` is a phone number written with a space where the pattern expects a hyphen. A pattern
  can be widened for it, and the next client will write it in a way nobody has thought of yet.
- `rq-0012` names a person and gives their street address. **No pattern recognises a name.** A
  named-entity model can find many of them, at a rate you would have to measure on your own logs,
  and it will still miss some.
- `rq-0005` lost the card number and kept the expiry date and the security code. Without the
  number they are close to useless, but this is exactly the field the previous section said no
  store may keep, and it is still in one.

So redaction is a floor and not a guarantee. **The decisions that protect people are the ones
about what gets written at all**: which tiers keep text, who can read them, and how long they
last. Redaction makes the longer-lived tiers safer to keep. It does not make them safe to keep
forever, and the next section is about the clock.
