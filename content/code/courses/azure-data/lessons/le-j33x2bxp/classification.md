---
title: Classification, with a classifier of our own
version: 1
---

**A classification is a label Purview puts on a column or a file, such as "this column holds CPF
numbers".** Purview ships with a large set of **system classifications**, more than two hundred in
Microsoft's documentation, for things like credit card numbers, passport numbers, e-mail addresses
and national identifiers of many countries, Brazil's among them. A scan applies them to the sample of
data it reads. When the built-in ones do not cover something, such as Quitanda's own customer ids, a
**custom classification rule** adds one: a pattern for the column's name, a pattern for its data, or
both, and a minimum share of the sampled values that must match.

How Purview decides internally is Microsoft's business and is not something a laptop can run. What
can be run is the idea, and a classifier small enough to read shows its two failure modes better than
any description. **What follows is a program written for this course. It is not Purview**, and its
rules, its names and its threshold are its own.

## Quitanda's export, generated

The export has the columns a customer export usually has, and two that are traps for a classifier: a
courier tracking number of eleven digits, the length of a CPF, and a free-text note in which one
customer's CPF was typed by an operator. The rows are made by a program, so you get the same file
without copying personal data from anywhere; the names are invented, the e-mail addresses use the
`example.com` domain kept for documentation, and the CPFs are random numbers built to pass the check
digits, belonging to nobody on purpose. Save it as `make_export.py`:

`make_export.py`:

```python
import csv
import random
import sys
import unicodedata

rng = random.Random(2026)
FIRST = ["Ana", "Bruno", "Carla", "Diego", "Elisa", "Fábio", "Gabi", "Hugo", "Iara", "João"]
LAST = ["Souza", "Lima", "Alves", "Rocha", "Pires", "Costa", "Melo", "Dias", "Nunes", "Reis"]

def cpf():
    d = [rng.randrange(10) for _ in range(9)]
    for n in (10, 11):
        s = sum(x * w for x, w in zip(d, range(n, 1, -1)))
        d.append(0 if s % 11 < 2 else 11 - s % 11)
    s = "".join(map(str, d))
    return f"{s[:3]}.{s[3:6]}.{s[6:9]}-{s[9:]}"

out = csv.writer(sys.stdout, lineterminator="\n")
out.writerow(["order_id", "customer", "cpf", "email", "phone", "tracking", "notes", "total_cents"])
for i in range(10):
    name = f"{FIRST[i]} {LAST[i]}"
    mail = unicodedata.normalize("NFKD", name.lower().replace(" ", ".")).encode("ascii", "ignore").decode()
    note = f"nota fiscal com CPF {cpf()}" if i == 3 else rng.choice(["", "deixar na portaria", "sem cebola"])
    out.writerow([f"o-{401 + i}", name, cpf(), f"{mail}@example.com",
                  f"+55 11 9{rng.randrange(1000, 9999)}-{rng.randrange(1000, 9999)}",
                  "".join(str(rng.randrange(10)) for _ in range(11)), note, rng.randrange(1500, 30000)])
```

Generate the file, look at its first lines, and put it in Azurite where the nightly export would land:

```
ana@laptop:~/azure$ python make_export.py > customers.csv && head -4 customers.csv
order_id,customer,cpf,email,phone,tracking,notes,total_cents
o-401,Ana Souza,588.139.986-27,ana.souza@example.com,+55 11 99975-9042,97309114170,,28198
o-402,Bruno Lima,753.645.568-24,bruno.lima@example.com,+55 11 92250-6577,18844729405,sem cebola,13412
o-403,Carla Alves,616.987.168-77,carla.alves@example.com,+55 11 99045-7523,84697880932,deixar na portaria,28308
ana@laptop:~/azure$ az storage container create -n quitanda-raw -o none && az storage blob upload -c quitanda-raw -n exports/2026-10-29/customers.csv -f customers.csv --no-progress -o none
```

## The classifier

Save it as `classify.py`:

```schooling-example
{"language": "python", "file": "classify.py", "parts": [{"code": "import csv\nimport io\nimport re\nimport sys\n\nfrom azure.storage.blob import BlobClient\n\nTHRESHOLD = 0.6\n\n", "note": "**`THRESHOLD` is the share of a column's rows that must match before the whole column is labelled.** Purview's custom classification rules have the same idea, a minimum match threshold, and this program's 60 per cent is a value of its own."}, {"code": "def cpf_digits_ok(value):\n    d = [int(c) for c in re.sub(r\"\\D\", \"\", value)]\n    if len(d) != 11 or len(set(d)) == 1:\n        return False\n    for n in (9, 10):\n        s = sum(x * w for x, w in zip(d[:n], range(n + 1, 1, -1)))\n        if d[n] != (0 if s % 11 < 2 else 11 - s % 11):\n            return False\n    return True\n\n", "note": "**A CPF carries two check digits**, computed from the nine before them with weights from 10 down to 2 and then 11 down to 2. A string of eleven digits that fails this arithmetic is not a CPF, whatever it looks like. Eleven equal digits pass the arithmetic and are refused anyway, as the Receita Federal's rules refuse them."}, {"code": "RULES = {\n    \"Brazil CPF\": (re.compile(r\"\\b\\d{3}\\.?\\d{3}\\.?\\d{3}-?\\d{2}\\b\"), cpf_digits_ok),\n    \"Email address\": (re.compile(r\"\\b[\\w.+-]+@[\\w-]+\\.[\\w.]+\\b\"), None),\n    \"Brazil phone\": (re.compile(r\"\\+55 ?\\d{2} ?9?\\d{4}-?\\d{4}\"), None),\n}\n\n", "note": "Three rules, each a pattern and, for the CPF, a validator. The pattern finds things that look right; the validator throws out those that only look right. The names are this program's, not Purview's."}, {"code": "blob = BlobClient.from_connection_string(\"UseDevelopmentStorage=true\", sys.argv[1], sys.argv[2])\nrows = list(csv.DictReader(io.StringIO(blob.download_blob().readall().decode())))\nprint(f\"{len(rows)} rows sampled from {sys.argv[1]}/{sys.argv[2]}\")\n\n", "note": "The export is read from Azurite with the short connection string, which this library understands. A real scan reads a sample of each file rather than all of it; ten rows is the whole of this one."}, {"code": "for column in rows[0]:\n    values = [r[column] for r in rows if r[column]]\n    found = []\n    for label, (pattern, check) in RULES.items():\n        hits = [v for v in values if pattern.search(v)]\n        valid = [v for v in hits if check is None or check(pattern.search(v).group())]\n        if hits:\n            share = len(valid) / len(rows)\n            verdict = label if share >= THRESHOLD else \"-\"\n            found.append(f\"{label}: {len(hits)} look like it, {len(valid)} pass, {share:.0%} -> {verdict}\")\n    print(f\"{column:<12} \" + (\"; \".join(found) if found else \"nothing\"))\n", "note": "For each column, every rule: how many values look like a match, how many pass the validator, what share of all the rows that is, and the verdict against the threshold. A rule that matches nothing in a column is not printed."}]}
```

```
ana@laptop:~/azure$ python classify.py quitanda-raw exports/2026-10-29/customers.csv
10 rows sampled from quitanda-raw/exports/2026-10-29/customers.csv
order_id     nothing
customer     nothing
cpf          Brazil CPF: 10 look like it, 10 pass, 100% -> Brazil CPF
email        Email address: 10 look like it, 10 pass, 100% -> Email address
phone        Brazil phone: 10 look like it, 10 pass, 100% -> Brazil phone
tracking     Brazil CPF: 10 look like it, 0 pass, 0% -> -
notes        Brazil CPF: 1 look like it, 1 pass, 10% -> -
total_cents  nothing
```

**Three columns labelled, correctly, and two decisions worth looking at.** The `tracking` column
looked like CPFs ten times out of ten, eleven digits each, and **not one passed the check digits**, so
it was not labelled. A classifier that stopped at the pattern would have marked the courier's numbers
as personal data, and the people reviewing the catalogue would learn to ignore its labels, which is
the worst thing a classifier can teach. The validator is what keeps the pattern honest.

**The `notes` column held a real CPF and was not labelled.** One row in ten, 10 per cent, is under the
threshold of 60. That is the threshold doing its job, since a column where one value in ten looks like
a CPF is usually not a column of CPFs, and it is also how personal data hides in a catalogue that
looks complete: the free-text field, the comment, the JSON blob, where a person typed what they
should not have. Lower the threshold and see what changes:

```
ana@laptop:~/azure$ sed 's/^THRESHOLD = 0.6/THRESHOLD = 0.1/' classify.py > classify_low.py && python classify_low.py quitanda-raw exports/2026-10-29/customers.csv | grep -E 'cpf|tracking|notes'
cpf          Brazil CPF: 10 look like it, 10 pass, 100% -> Brazil CPF
tracking     Brazil CPF: 10 look like it, 0 pass, 0% -> -
notes        Brazil CPF: 1 look like it, 1 pass, 10% -> Brazil CPF
```

**`notes` is now labelled, and so would be any column with one stray match.** No threshold catches
the one CPF in a notes field without also labelling every column where a number happens to pass the
arithmetic. Purview faces the same trade, which is why its custom rules expose the threshold, and why
the honest description of a scan's output is "the columns that are mostly this", never "everywhere
this appears". Free-text fields that may hold personal data are better handled at the source, by not
letting the shop's operators type it there, than found afterwards.

**What the program did not do is also what Purview does not do for you**: decide what the label
means. A column labelled CPF still needs somebody to decide who may read it, how long it is kept and
whether it should be masked, which are the next section's labels and the subjects of `data-governance`.
