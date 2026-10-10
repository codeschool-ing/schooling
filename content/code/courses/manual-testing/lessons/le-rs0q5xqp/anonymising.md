---
title: Anonymising a copy of production
version: 1
---

Sooner or later somebody proposes testing with a copy of the real database, and the argument for it
is a good one: production data has every odd name, every abandoned order and every customer who
did something nobody planned for. The argument against it is that **a copy of production is a copy
of every customer's personal data, in an environment with more people, weaker controls and no
reason to hold it**. The answer most teams arrive at is a copy that has been changed so that it no
longer says who anybody is, and the ways of changing it are not equivalent.

## What the law says about it

In Brazil the law is the LGPD, the general data protection law. It treats any information that
identifies a person, or could identify them, as personal data, and copying it into a test
environment is processing it: it needs a purpose, it has to be protected, and access is limited to
the people who need it. **Data that has been anonymised is outside the law**, but only if the
process cannot be reversed with reasonable effort; the law says so in article 12. **Data that has
been pseudonymised, so that it can be linked to the person again by whoever holds some extra
information, is still personal data.** Europe's GDPR draws the same line. The practical
consequence for a tester: a masked or pseudonymised copy is safer than a raw one, and it still has
to be handled as personal data.

## Three ways to change a copy

**Masking** replaces part of a value with fixed characters. `Débora Barbosa` becomes `D***** B******`.
The shape survives, the length and the first letter, which is what a test of a layout or a field
limit needs. Uniqueness does not: Débora Barbosa and Daniel Bezerra both become `D***** B******`,
and any table that refers to the account by its name can no longer tell them apart. And the part that survives still says something: an initial and a length, beside a city and a
birth date, may be enough to recognise somebody in a small theatre's members.

**Pseudonymising with a keyed hash** replaces a value with a code computed from it and a secret
key. The same address with the same key always gives the same code, and nobody without the key can
compute it. That keeps the one property masking loses: **the accounts table and the orders table
are pseudonymised separately and still join**, because the same customer gets the same code in
both. A plain hash with no key does not protect anything here, because anybody holding a list of
likely addresses can compute their hashes and compare; the key is what stops that.

**Generating** replaces the data altogether, as section 03 of this lesson did. Nothing in it was
ever anybody's, so there is nothing to protect, and nothing of production's variety survives
either.

## A program that does the first two

The program below reads an accounts file like the one section 03 made, masks the name, replaces
the address with a keyed pseudonym, and drops the password entirely, because no test needs it.
`accounts.csv` was generated, so nobody's data is at risk here; it stands in for an export from a
real system, which this course never asks you to copy. Create a new file in your `boxoffice`
directory, paste the program into it, and save it. Save it as `pseudonymise.py`, exactly that name:

```python
"""pseudonymise.py: a copy of an accounts file that names nobody.

    PSEUDONYM_KEY=... python3 pseudonymise.py accounts.csv > safe.csv
"""
import csv
import hashlib
import hmac
import os
import sys

key = os.environ.get("PSEUDONYM_KEY", "")      # kept by whoever owns the real data
if not key:
    sys.exit("pseudonymise.py: set PSEUDONYM_KEY to the key you were given")


def pseudonym(email):
    digest = hmac.new(key.encode(), email.lower().encode(), hashlib.sha256).hexdigest()
    return f"user-{digest[:12]}@example.org"


def mask(name):
    return " ".join(word[0] + "*" * (len(word) - 1) for word in name.split())


with open(sys.argv[1], newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

writer = csv.DictWriter(sys.stdout, fieldnames=["name", "email"], lineterminator="\n")
writer.writeheader()
for row in rows:
    writer.writerow({"name": mask(row["name"]), "email": pseudonym(row["email"])})
```

The key goes in the environment, not in the file, so that the program can be shared and the key
cannot travel with it. Run it with a key:

@@capture:pseudo@@

Run it again with the same key and the codes are identical, which is what lets two tables join.
With a different key, the same people get different codes:

@@capture:pseudo-key@@

And with no key it refuses, rather than producing codes anybody could recompute:

@@capture:pseudo-nokey@@

On Windows in PowerShell, set the key on a line of its own first, `$env:PSEUDONYM_KEY="vila-test-key"`,
and then run `python pseudonymise.py accounts.csv`.

@@fig:l20-join@@

## Who holds the key

**Not the tester.** The key belongs to whoever owns the real data, and it stays with them, beside
the production system. Whoever holds the key and the pseudonymised copy together can link every row
back to a person, which turns the copy back into the original. The tester receives the copy and
never the key; the people who make the copy keep the key and never put it in the test environment.

Two more rules make the difference between a safe copy and a leak with extra steps. **Take only the
columns a test needs**: the password went because no test reads it, and a birth date that no case
uses should go the same way. And **look at what is left in free text**: a delivery note that says
"leave it with Débora at number 12" carries a name and an address in a column nobody thought to
mask.
