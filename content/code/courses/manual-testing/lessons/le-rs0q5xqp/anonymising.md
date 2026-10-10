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

```
ana@laptop:~/boxoffice$ PSEUDONYM_KEY=vila-test-key python3 pseudonymise.py accounts.csv
name,email
C*** B******,user-fd0012e00e53@example.org
D***** B******,user-9b1313cc8669@example.org
D***** M******,user-81a46e112012@example.org
G****** D*****,user-b0f365144ba2@example.org
F******* B******,user-800010070afe@example.org
```

Run it again with the same key and the codes are identical, which is what lets two tables join.
With a different key, the same people get different codes:

```
ana@laptop:~/boxoffice$ PSEUDONYM_KEY=vila-test-key python3 pseudonymise.py accounts.csv
name,email
C*** B******,user-fd0012e00e53@example.org
D***** B******,user-9b1313cc8669@example.org
D***** M******,user-81a46e112012@example.org
G****** D*****,user-b0f365144ba2@example.org
F******* B******,user-800010070afe@example.org
ana@laptop:~/boxoffice$ PSEUDONYM_KEY=another-key python3 pseudonymise.py accounts.csv
name,email
C*** B******,user-18ad58b96e1c@example.org
D***** B******,user-989fc93f33c9@example.org
D***** M******,user-f60bb686e4d8@example.org
G****** D*****,user-5db6a3c85348@example.org
F******* B******,user-ef74d7540351@example.org
```

And with no key it refuses, rather than producing codes anybody could recompute:

```
ana@laptop:~/boxoffice$ python3 pseudonymise.py accounts.csv
pseudonymise.py: set PSEUDONYM_KEY to the key you were given
```

On Windows in PowerShell, set the key on a line of its own first, `$env:PSEUDONYM_KEY="vila-test-key"`,
and then run `python pseudonymise.py accounts.csv`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"l20-join\" aria-label=\"On the left, the original: an accounts row for Débora Barbosa, test002@example.org, and an orders row, order 1003 for Hamlet, with the same address. Both pass through a keyed hash whose key stays with the data's owner. On the right, the test copy: the name masked as D***** B******, and the address replaced by user-9b1313cc8669@example.org in both tables, so they still join. Underneath, the same address with another key becomes user-989fc93f33c9@example.org.\"><defs><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"10.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the original</text><text x=\"440.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the test copy</text><text x=\"10.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">accounts</text><text x=\"10.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orders</text><text x=\"440.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">accounts</text><text x=\"440.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orders</text><rect x=\"10.0\" y=\"52.0\" width=\"92.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"18.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Débora Barbosa</text><rect x=\"102.0\" y=\"52.0\" width=\"136.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">test002@example.org</text><rect x=\"10.0\" y=\"128.0\" width=\"40.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"18.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1003</text><rect x=\"50.0\" y=\"128.0\" width=\"136.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"58.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">test002@example.org</text><rect x=\"186.0\" y=\"128.0\" width=\"52.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"194.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Hamlet</text><rect x=\"440.0\" y=\"52.0\" width=\"92.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">D***** B******</text><rect x=\"532.0\" y=\"52.0\" width=\"180.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">user-9b1313cc8669@example.org</text><rect x=\"440.0\" y=\"128.0\" width=\"40.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1003</text><rect x=\"480.0\" y=\"128.0\" width=\"180.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"488.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">user-9b1313cc8669@example.org</text><rect x=\"660.0\" y=\"128.0\" width=\"52.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Hamlet</text><rect x=\"285.0\" y=\"72.0\" width=\"128.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"349.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">keyed hash</text><text x=\"349.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the key stays with</text><text x=\"349.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the data's owner</text><path d=\"M238.0 65.0 L282.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M238.0 141.0 L282.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M416.0 92.0 L437.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M416.0 118.0 L437.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M600.0 79.0 L600.0 127.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"716.0\" y=\"174.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">same code in both: the tables still join</text><path d=\"M10.0 200.0 L710.0 200.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"10.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">with another key, the same address becomes</text><text x=\"10.0\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">user-989fc93f33c9@example.org</text></svg>", "caption": "Pseudonymising each table separately keeps the join, because the same address and the same key give the same code. A different key gives a different code, which is why the key is never sent with the copy."}
```

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
