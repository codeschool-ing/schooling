"""Fairness metrics over a table of decisions, and the data they run on.

THE DECISIONS ARE WRITTEN BY THE COURSE. Tarefa's shortlist feature ranks the
freelancers who apply to a job and shortlists the best; a reviewer later
judged whether each applicant could have done the job (`good`). No model
made these decisions: COUNTS below says how many of each kind there are, and
build() writes one row per applicant from it, in a fixed order. The two
versions are the shortlist before and after the change lesson 3 discusses.

Every metric is a rate over a group. A group with fewer than MINIMUM rows is
reported as too small, the same rule the platform's own item analysis uses:
four people is chance, not a measurement.
"""
import csv

MINIMUM = 30

# region: (good shortlisted, good passed over, not-good shortlisted, not-good passed over)
COUNTS = {
    "v1": {"Sudeste": (96, 24, 16, 64), "Nordeste": (30, 20, 5, 45), "Norte": (3, 3, 1, 5)},
    "v2": {"Sudeste": (96, 24, 16, 64), "Nordeste": (40, 10, 16, 34), "Norte": (4, 2, 2, 4)},
}


def build(path, version):
    rows, n = [], 0
    for region, (tp, fn, fp, tn) in COUNTS[version].items():
        for good, picked, k in ((1, 1, tp), (1, 0, fn), (0, 1, fp), (0, 0, tn)):
            for _ in range(k):
                n += 1
                rows.append({"applicant": "fr-%04d" % n, "region": region,
                             "good": good, "shortlisted": picked})
    with open(path, "w", newline="") as fh:
        w = csv.DictWriter(fh, ["applicant", "region", "good", "shortlisted"])
        w.writeheader()
        w.writerows(rows)


def rates(rows):
    tp = sum(1 for r in rows if r["good"] and r["shortlisted"])
    fn = sum(1 for r in rows if r["good"] and not r["shortlisted"])
    fp = sum(1 for r in rows if not r["good"] and r["shortlisted"])
    tn = sum(1 for r in rows if not r["good"] and not r["shortlisted"])
    n = len(rows)
    div = lambda a, b: a / b if b else float("nan")
    return {"n": n, "base": div(tp + fn, n), "selected": div(tp + fp, n),
            "tpr": div(tp, tp + fn), "fpr": div(fp, fp + tn),
            "precision": div(tp, tp + fp)}


def load(path, group):
    with open(path, newline="") as fh:
        rows = [dict(r, good=int(r["good"]), shortlisted=int(r["shortlisted"]))
                for r in csv.DictReader(fh)]
    groups = {}
    for r in rows:
        groups.setdefault(r[group], []).append(r)
    return groups
