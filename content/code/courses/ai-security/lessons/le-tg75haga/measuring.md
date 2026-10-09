---
title: Measuring a shortlist group by group
version: 2
---

Sixteen profiles show the mechanism and are too few to measure anything. The measurement is made on
the shortlist's real output over many decisions, together with a label saying which decisions were
right. Here that table is `data/shortlist-v1.csv`: 312 applicants, the region of each, whether a
reviewer later judged them able to do the job (`good`), and whether the shortlist chose them. **The
counts were written by the course**, so that the metrics have something to disagree about, and this
program writes the table from them. Save it as `~/guard/tools/shortlist.py`:

```python
# shortlist.py: write a table of shortlist decisions, one row per applicant.
#
#   guard shortlist v1|v2 > FILE
#
# THE DECISIONS ARE WRITTEN BY THE COURSE, from the counts below: for each
# region, how many good applicants were shortlisted and passed over, and how
# many who could not do the job were shortlisted and passed over. v1 is the
# shortlist as it was; v2 is after the change lesson 3 discusses.
import csv
import sys

# region: (good shortlisted, good passed over, not good shortlisted, not good passed over)
COUNTS = {
    "v1": {"Sudeste": (96, 24, 16, 64), "Nordeste": (30, 20, 5, 45), "Norte": (3, 3, 1, 5)},
    "v2": {"Sudeste": (96, 24, 16, 64), "Nordeste": (40, 10, 16, 34), "Norte": (4, 2, 2, 4)},
}

out = csv.writer(sys.stdout, lineterminator="\n")
out.writerow(["applicant", "region", "good", "shortlisted"])
n = 0
for region, (tp, fn, fp, tn) in COUNTS[sys.argv[1]].items():
    for good, picked, k in ((1, 1, tp), (1, 0, fn), (0, 1, fp), (0, 0, tn)):
        for _ in range(k):
            n += 1
            out.writerow(["fr-%04d" % n, region, good, picked])
```

And the measurement, `~/guard/tools/fairness.py`:

```python
# fairness.py: rates per group in a table of decisions, and the gaps between them.
#
#   guard fairness FILE --group COLUMN [--reference VALUE]
#
# FILE is a CSV with a column `good` (could the person do the job) and a column
# `shortlisted`, both 0 or 1. Every rate is computed inside one group. A group
# with fewer than MINIMUM rows is reported as too small: a handful of people
# is chance, not a measurement.
import argparse
import csv

MINIMUM = 30

p = argparse.ArgumentParser(prog="guard fairness")
p.add_argument("file")
p.add_argument("--group", required=True)
p.add_argument("--reference")
a = p.parse_args()


def rates(rows):
    tp = sum(1 for r in rows if r["good"] and r["shortlisted"])
    fn = sum(1 for r in rows if r["good"] and not r["shortlisted"])
    fp = sum(1 for r in rows if not r["good"] and r["shortlisted"])
    tn = sum(1 for r in rows if not r["good"] and not r["shortlisted"])
    n = len(rows)
    return {"n": n, "base": (tp + fn) / n, "selected": (tp + fp) / n,
            "tpr": tp / (tp + fn), "fpr": fp / (fp + tn), "precision": tp / (tp + fp)}


groups = {}
with open(a.file, newline="") as f:
    for r in csv.DictReader(f):
        r["good"], r["shortlisted"] = int(r["good"]), int(r["shortlisted"])
        groups.setdefault(r[a.group], []).append(r)

print("%-10s %4s  %5s  %8s  %5s  %5s  %9s" % (
    a.group, "n", "base", "selected", "TPR", "FPR", "precision"))
measured = {}
for g, rows in groups.items():
    if len(rows) < MINIMUM:
        print("%-10s %4d  too few to measure (fewer than %d)" % (g, len(rows), MINIMUM))
        continue
    s = measured[g] = rates(rows)
    print("%-10s %4d  %5.2f  %8.2f  %5.2f  %5.2f  %9.2f" % (
        g, s["n"], s["base"], s["selected"], s["tpr"], s["fpr"], s["precision"]))

ref = a.reference or max(measured, key=lambda g: measured[g]["selected"])
print("reference: %s" % ref)
for g, s in measured.items():
    if g == ref:
        continue
    r = measured[ref]
    ratio = s["selected"] / r["selected"]
    print("%s against %s" % (g, ref))
    print("  selection ratio   %.2f%s" % (ratio, "   below the four-fifths line (0.80)"
                                             if ratio < 0.8 else ""))
    for key, name in (("tpr", "TPR gap"), ("fpr", "FPR gap"), ("precision", "precision gap")):
        print("  %-17s %+.2f" % (name, s[key] - r[key]))
```

```
ana@lab:~/guard$ guard shortlist v1 > data/shortlist-v1.csv
ana@lab:~/guard$ head -3 data/shortlist-v1.csv
applicant,region,good,shortlisted
fr-0001,Sudeste,1,1
fr-0002,Sudeste,1,1
ana@lab:~/guard$ guard fairness data/shortlist-v1.csv --group region
region        n   base  selected    TPR    FPR  precision
Sudeste     200   0.60      0.56   0.80   0.20       0.86
Nordeste    100   0.50      0.35   0.60   0.10       0.86
Norte        12  too few to measure (fewer than 30)
reference: Sudeste
Nordeste against Sudeste
  selection ratio   0.62   below the four-fifths line (0.80)
  TPR gap           -0.20
  FPR gap           -0.10
  precision gap     +0.00
```

## Five rates, and the question each one answers

Every column is a rate inside one group, and each answers a different question:

| column | of whom | the question it answers |
|---|---|---|
| `base` | everybody in the group | how many were good: the base rate |
| `selected` | everybody in the group | how many the shortlist chose |
| `TPR` | the good ones | of those who could do the job, how many were shortlisted |
| `FPR` | the ones who were not good | of those who could not, how many were shortlisted anyway |
| `precision` | the shortlisted | of those the client saw, how many could do the job |

Read the Nordeste row against the Sudeste row with those questions in mind.

**Selection.** 35% of Northeastern applicants are shortlisted against 56% of Southeastern ones, and
the ratio between the two is 0.62. The *four-fifths rule* flags a ratio below 0.80 as adverse impact.
It comes from guidelines that US employment regulators published in 1978, and it is no law in
Brazil. Even where it applies it is a rule of thumb. It is still the most widely used first screen,
and 0.62 is well below it. Requiring the selection rates to be equal is called **demographic
parity**.

**TPR.** Of the Northeastern freelancers who could do the job, 60% were shortlisted; of the
Southeastern ones, 80%. The gap of −0.20 is the stand-in's CEP bonus showing up in aggregate: a good
freelancer in the Northeast is passed over twice as often, 40% against 20%. Requiring this gap to be
zero is called **equal opportunity**.

**Precision.** 0.86 in both. Of the people a client sees, the same share can do the job wherever they
live. Requiring this is called **predictive parity**, and by it the shortlist is fair.

That last line is what makes this hard. **A client looking at precision sees a fair shortlist; a
freelancer looking at TPR sees an unfair one.** Both are reading the same table correctly. Which
metric a report leads with decides what the report concludes, and that choice is usually made
without anybody noticing it was a choice.

## The group the table refuses to measure

The North has 12 applicants, and the tool prints no rates for it. With 6 good applicants, one more or
one fewer shortlisted moves the TPR by 0.17, so any gap it showed would be mostly chance. The cut-off
of 30 is the same one this platform's own item analysis uses before it judges a question.

Refusing is better than printing a number nobody should read, and it is still a finding: **the
group that is measured worst is usually the group with the most to lose from a bad model**, which is
the representation row of the previous section. The remedy is to collect more decisions before
concluding anything about the North, and not to drop the region from the report because its row is
empty.
