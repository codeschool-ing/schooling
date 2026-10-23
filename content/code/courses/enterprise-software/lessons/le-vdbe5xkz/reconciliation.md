---
title: Reconciliation: proving that what arrived is what left
version: 1
---

A load that finished without an error has proved one thing: nothing it checked went wrong. It says
nothing about the rows it did not check, the values it transformed wrongly but validly, or the rows
it never read. **Reconciliation is the separate, independent proof that the target holds what the
source sent**, and it is what the go/no-go decision is taken on. A migration without one is
finished when the script stops, which is not the same as being right.

The common mistake is to treat reconciliation as a count. A count is the first of three levels,
and each level catches something the one above it lets through.

## Three levels

**Count.** The number of records on each side. It catches the rows that were dropped and the rows
that were loaded twice. It cannot see a row that arrived with the wrong value in it.

**Control total.** The sum of a field that matters, on each side: at Serra Alta, the litres, and in
a finance migration, the amounts. It catches a value that changed on the way, such as a unit
divided once too often, or a truncated decimal. It cannot see two errors that cancel out: litres
moved from one farm to another leave the total exactly where it was.

**Record.** Each record on one side compared with the record with the same key on the other. It
says which records are missing, which are extra and which changed, by name. Comparing every field
of millions of records across two systems is slow and awkward, so each side computes a
**fingerprint**, a hash of the record's fields in an agreed form, and only the keys and the hashes
are compared. Two records with the same hash hold the same values.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l14-levels\" aria-label=\"A grid of four checks against five faults. The checks, one per row: count, control total, record by fingerprint, and a sample read by the data owner. The faults, one per column: a row dropped, one value changed, two values swapped, a farm loaded under the wrong code, and a wrong rule in the specification. The count catches only the dropped row. The control total catches the dropped row and the changed value. The record check catches the first four faults. Only the owner’s sample catches the wrong rule, because every check written from the same specification agrees with it.\"><text x=\"264.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a row</text><text x=\"264.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dropped</text><text x=\"364.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one value</text><text x=\"364.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">changed</text><text x=\"464.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">two values</text><text x=\"464.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">swapped</text><text x=\"564.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a farm under</text><text x=\"564.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the wrong code</text><text x=\"664.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a wrong rule in</text><text x=\"664.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the specification</text><text x=\"16.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">count</text><circle cx=\"264.0\" cy=\"86.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"364.0\" cy=\"86.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"464.0\" cy=\"86.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"564.0\" cy=\"86.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"664.0\" cy=\"86.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><text x=\"16.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">control total</text><circle cx=\"264.0\" cy=\"128.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"364.0\" cy=\"128.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"464.0\" cy=\"128.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"564.0\" cy=\"128.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"664.0\" cy=\"128.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><text x=\"16.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">record, by fingerprint</text><circle cx=\"264.0\" cy=\"170.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"364.0\" cy=\"170.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"464.0\" cy=\"170.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"564.0\" cy=\"170.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"664.0\" cy=\"170.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><path d=\"M16.0 191.0 L714.0 191.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"16.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the owner’s sample</text><circle cx=\"264.0\" cy=\"212.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"364.0\" cy=\"212.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"464.0\" cy=\"212.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"564.0\" cy=\"212.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"664.0\" cy=\"212.0\" r=\"8\" fill=\"var(--amber)\"></circle><circle cx=\"232.0\" cy=\"268.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"246.0\" y=\"268.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">caught</text><circle cx=\"330.0\" cy=\"268.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><text x=\"344.0\" y=\"268.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">passes unseen</text></svg>", "caption": "What each level of reconciliation can see. Each level down catches what the one above lets through; the last row is a person, because a check built from the specification cannot doubt it."}
```

Serra Alta learnt the third level the expensive way. **Joana's first go/no-go criteria asked for
counts and totals only**, because in the systems she had migrated before, the code that moved the
data was the code that had written it, and a wrong value was rare. Dress rehearsal 1 passed both
levels with 214 collection rows carrying another farm's litres, and only the record level saw them.

## Compare the ends, not the middle

A reconciliation is only independent if it reads what the migration did not write. **The source
side is extracted from Coleta itself at the moment of the freeze**, not from the staging files the
transformation read; **the target side is read from the new system as its users see it**, not from
the load's own tables. A reconciliation that compares the load's input with the load's output
proves that the load agrees with itself.

Both extracts are also brought to one form before they are compared. Coleta stores litres as
hundredths in an integer; the new system stores a decimal. Coleta pads the SAP vendor number to ten
digits; the new system stores the number. **The comparison is of meaning, not of bytes**, and the
rules that bring the two to one form are short, separate from the transformation, and written by
somebody other than whoever wrote the transformation.

## Expected differences

The source and the target are not meant to be identical. The specification removes and merges
things on purpose, and the reconciliation has to account for every row:

> source rows = target rows + rows rejected with a reason + rows excluded or merged by a rule

At Serra Alta the farm master balances like this: 1,958 farms in scope, 7 merged into their
survivors, so **1,951 farms are expected in the target**, with nothing rejected. The control total
balances without an adjustment, because a merged farm's litres move to its survivor rather than
disappearing. At the record level the 7 survivors are expected to differ from their source records,
since each now carries a second farm's history, and they are listed as expected changes rather than
found ones. **A difference with a rule behind it is a result; a difference without one stops the
cutover.**

## The program

The program below does all three levels on a small scale. It compares two extracts of July's
litres, one from each side, by count, by total litres and by a fingerprint of each farm. Running it
is optional: the transcripts below show what it prints. If you want to run it, use the Linux machine
from lesson 1 or any computer with Python 3.

This script writes the two extracts, eight farms each, and a third file with the target as it might
have looked after a faulty load:

```sh
# make-extracts.sh: the July extracts from both sides, and a target with three faults
cat > coleta.csv <<'END'
farm_code;sap_vendor;litres_x100
100127;0000300127;2828440
100245;0000300245;1395000
100318;0000300318;471975
100436;0000300436;3620800
100554;0000300554;902330
100672;0000300672;1785610
100790;0000300790;640520
100818;0000300818;2210115
END

cat > target.csv <<'END'
farm_id;legacy_code;vendor;litres
F-000214;100127;300127;28284.40
F-000215;100245;300245;13950.00
F-000216;100318;300318;4719.75
F-000217;100436;300436;36208.00
F-000218;100554;300554;9023.30
F-000219;100672;300672;17856.10
F-000220;100790;300790;6405.20
F-000221;100818;300818;22101.15
END

cat > target-faulty.csv <<'END'
farm_id;legacy_code;vendor;litres
F-000214;100127;300127;28284.40
F-000215;100245;300245;4719.75
F-000216;100318;300318;13950.00
F-000217;100436;300436;36208.00
F-000218;100545;300554;9023.30
F-000219;100672;300672;17856.10
F-000220;100790;300790;6405.20
F-000221;100818;300818;22101.15
END
```

Save it as `make-extracts.sh` in an empty directory and run it with `sh`. On Windows, use Git Bash
or WSL, or create the three files by hand from the script.

```
$ sh make-extracts.sh
$ head -3 coleta.csv target.csv
==> coleta.csv <==
farm_code;sap_vendor;litres_x100
100127;0000300127;2828440
100245;0000300245;1395000

==> target.csv <==
farm_id;legacy_code;vendor;litres
F-000214;100127;300127;28284.40
F-000215;100245;300245;13950.00
```

The two sides do not look alike, which is the normal case: different column names, the vendor
number with and without its leading zeros, the litres as an integer of hundredths and as a decimal.
The target also carries a new `farm_id` of its own, with the Coleta code kept beside it in
`legacy_code`.

Save this beside them as `reconcile.py`. It uses the standard library only.

```schooling-example
{
  "language": "python",
  "file": "reconcile.py",
  "parts": [
    {
      "code": "# reconcile.py: prove the target holds what the source sent, at three levels\nimport csv\nimport hashlib\nimport sys\nfrom decimal import Decimal",
      "note": "Four modules from the standard library. `hashlib` makes the fingerprints and `Decimal` holds the litres, because a reconciliation that adds litres as floating-point numbers can disagree with itself in the last decimal."
    },
    {
      "code": "\n\ndef hundredths(text):\n    value = Decimal(text) * 100\n    if value != value.to_integral_value():\n        raise ValueError(f\"more than two decimals: {text}\")\n    return int(value)",
      "note": "The target writes litres as a decimal and Coleta as hundredths, so both become an integer number of hundredths. A value with a third decimal is refused rather than rounded: a reconciliation that quietly rounds has stopped checking that digit."
    },
    {
      "code": "\n\ndef from_coleta(row):\n    return row[\"farm_code\"], int(row[\"sap_vendor\"]), int(row[\"litres_x100\"])\n\n\ndef from_target(row):\n    return row[\"legacy_code\"], int(row[\"vendor\"]), hundredths(row[\"litres\"])",
      "note": "One small function per side, bringing its own format to one form: the farm code, the vendor as a number without its leading zeros, and the litres in hundredths. These rules are the only place the two formats meet, and they are kept apart from the code that did the migration."
    },
    {
      "code": "\n\ndef read(path, convert):\n    count, total, farms = 0, 0, {}\n    with open(path, newline=\"\", encoding=\"utf-8\") as f:\n        for row in csv.DictReader(f, delimiter=\";\"):\n            code, vendor, litres = convert(row)\n            if code in farms:\n                raise ValueError(f\"{path}: farm {code} appears twice\")\n            count, total = count + 1, total + litres\n            record = f\"{code}|{vendor}|{litres}\".encode()\n            farms[code] = hashlib.sha256(record).hexdigest()\n    return count, total, farms",
      "note": "One pass over an extract gives all three levels' raw material: the count, the total, and one fingerprint per farm. A farm code seen twice is an error that stops the run, because quietly keeping the second row would hide exactly the duplicate a count should find."
    },
    {
      "code": "\n\ndef main(source, target):\n    s_count, s_total, s_farms = read(source, from_coleta)\n    t_count, t_total, t_farms = read(target, from_target)\n    ok = True\n\n    def level(name, left, right):\n        nonlocal ok\n        ok = ok and left == right\n        verdict = \"ok\" if left == right else \"DIFFERENT\"\n        print(f\"{name:<8} source {left:>12}  target {right:>12}  {verdict}\")\n\n    level(\"count\", s_count, t_count)\n    level(\"litres\", f\"{Decimal(s_total) / 100:,.2f}\", f\"{Decimal(t_total) / 100:,.2f}\")",
      "note": "The first two levels. Each prints both sides and a verdict, and any disagreement turns `ok` false. The total is printed in litres with two decimals so a person can compare it with a report."
    },
    {
      "code": "    both = s_farms.keys() & t_farms.keys()\n    found = {\n        \"missing\": sorted(s_farms.keys() - t_farms.keys()),\n        \"extra\": sorted(t_farms.keys() - s_farms.keys()),\n        \"changed\": sorted(c for c in both if s_farms[c] != t_farms[c]),\n    }\n    for name, codes in found.items():\n        print(f\"{name:<8} {len(codes)}  {' '.join(codes)}\".rstrip())\n        ok = ok and not codes",
      "note": "The third level, by key. A code only in the source is missing, a code only in the target is extra, and a code on both sides with different fingerprints has changed. Each list names the farms, which is what somebody needs at three in the morning."
    },
    {
      "code": "    print(\"RECONCILED\" if ok else \"NOT RECONCILED\")\n    return 0 if ok else 1\n\n\nif __name__ == \"__main__\":\n    sys.exit(main(sys.argv[1], sys.argv[2]))",
      "note": "The exit status is what a runbook or a scheduler reads: `0` when every level agrees, `1` otherwise."
    }
  ]
}
```

Run it on the clean target first (on Windows the command is `python` rather than `python3`):

```
$ python3 reconcile.py coleta.csv target.csv
count    source            8  target            8  ok
litres   source   138,547.90  target   138,547.90  ok
missing  0
extra    0
changed  0
RECONCILED
$ echo $?
0
```

Every level agrees, and the exit status is `0`, which a scheduler or a runbook step can read
without a person.

Now run it on the faulty target:

```
$ python3 reconcile.py coleta.csv target-faulty.csv
count    source            8  target            8  ok
litres   source   138,547.90  target   138,547.90  ok
missing  1  100554
extra    1  100545
changed  2  100245 100318
NOT RECONCILED
$ echo $?
1
```

**The count and the total both pass, and the target is wrong in four farms.** Farm `100554` is
missing and farm `100545` is extra: the same farm, loaded under a code with two digits swapped, so
the count does not move and neither do the litres. Farms `100245` and `100318` have exchanged their
litres, 13,950.00 and 4,719.75, which leaves the total exactly where it was. That is a miniature of
what dress rehearsal 1 found, and the reason the third level exists. The exit status is `1`, and
the output names every farm somebody has to look at.

## What no program can see

All three levels compare the target with what the specification said it should hold. **If the
specification is wrong, the reconciliation agrees with the mistake**, because whoever wrote it read
the same specification. A mapping that put the fat result into the protein field, in both the load
and the reconciliation's rules, reconciles perfectly.

That is what the fourth check is for, and it is done by a person. Before each go/no-go, Cláudia's team opened 40 farms chosen at random in the new
system's screens, beside the same farms in Coleta's. They read them as somebody who knows milk
reads them: does this farm's fat look like this farm's fat, is this bacterial count plausible for
the time of year. Finance did the same for the
vendor links of 40 farms in SAP. **A sample read by an owner checks meaning, which no fingerprint
can.** It is small because it does not need to be large: it is looking for a wrong rule, which
shows up in every farm it touches, not for one wrong row among millions.
