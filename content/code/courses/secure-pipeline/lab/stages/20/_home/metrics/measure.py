"""Measures findings.csv and inventory.csv, the files gen.py writes.

    python3 measure.py REPORT

REPORT is ttr, ttr-any, debt, coverage, trend or teams.
"""
import csv
import datetime as dt
import statistics
import sys

TODAY = dt.date(2026, 10, 1)
SEVERITIES = ["critical", "high", "medium", "low"]
SLA = {"critical": 7, "high": 30, "medium": 90, "low": 180}  # days to fix


def load():
    rows = list(csv.DictReader(open("findings.csv")))
    for r in rows:
        r["opened"] = dt.date.fromisoformat(r["opened"])
        r["closed"] = dt.date.fromisoformat(r["closed"]) if r["closed"] else None
        r["days"] = ((r["closed"] or TODAY) - r["opened"]).days
    return rows


def p90(values):
    return sorted(values)[int(0.9 * (len(values) - 1))]


def ttr(rows, closing=("fixed",)):
    """Time to remediate: days from opened to closed, per severity."""
    print(f"{'severity':9} {'closed':>6} {'mean':>5} {'median':>6} {'p90':>4} {'in SLA':>6}")
    for sev in SEVERITIES:
        days = [r["days"] for r in rows if r["severity"] == sev and r["resolution"] in closing]
        within = sum(d <= SLA[sev] for d in days) / len(days)
        print(f"{sev:9} {len(days):6} {statistics.mean(days):5.1f} {statistics.median(days):6g} "
              f"{p90(days):4} {within:6.0%}")


def debt(rows):
    """What is still open, by age, and how much of it is past its SLA."""
    edges = [(0, 30), (31, 90), (91, 180), (181, 9999)]
    print(f"{'severity':9} {'open':>4} {'0-30':>5} {'31-90':>5} {'91-180':>6} {'181+':>5} {'past SLA':>8}")
    for sev in SEVERITIES:
        ages = [r["days"] for r in rows if r["severity"] == sev and not r["resolution"]]
        buckets = [sum(lo <= a <= hi for a in ages) for lo, hi in edges]
        late = sum(a > SLA[sev] for a in ages)
        print(f"{sev:9} {len(ages):4} {buckets[0]:5} {buckets[1]:5} {buckets[2]:6} {buckets[3]:5} {late:8}")


def coverage(rows):
    """Targets each scanner looks at, out of the targets it applies to."""
    inventory = list(csv.DictReader(open("inventory.csv")))
    for tool, kind in [("sast", "repo"), ("sca", "repo"), ("secrets", "repo"), ("image", "image")]:
        targets = [t for t in inventory if t["kind"] == kind]
        scanned = [t["target"] for t in targets if tool in t["scanners"].split()]
        print(f"{tool:8} {len(scanned):2} of {len(targets):2} {kind}s  {len(scanned) / len(targets):4.0%}")
    never = sorted({t["target"] for t in inventory if not t["scanners"]})
    print("scanned by nothing:", ", ".join(never))


def trend(rows):
    """Findings opened and closed per quarter, and what was open at its end."""
    edges = [dt.date(2025, 10, 1), dt.date(2026, 1, 1), dt.date(2026, 4, 1), dt.date(2026, 7, 1), TODAY]
    print(f"{'quarter':9} {'opened':>6} {'closed':>6} {'open at end':>11}")
    for start, end in zip(edges, edges[1:]):
        opened = sum(start <= r["opened"] < end for r in rows)
        closed = sum(r["closed"] is not None and start <= r["closed"] < end for r in rows)
        still = sum(r["opened"] < end and (r["closed"] is None or r["closed"] >= end) for r in rows)
        print(f"{start:%Y-%m}   {opened:6} {closed:6} {still:11}")


def teams(rows):
    """Per team: how findings left the list, and the median days to close."""
    print(f"{'team':9} {'closed':>6} {'fixed':>5} {'wont_fix':>8} {'median':>6}")
    for team in sorted({r["team"] for r in rows}):
        done = [r for r in rows if r["team"] == team and r["resolution"]]
        wont = sum(r["resolution"] == "wont_fix" for r in done)
        fixed = len(done) - wont - sum(r["resolution"] == "false_positive" for r in done)
        median = statistics.median(r["days"] for r in done)
        print(f"{team:9} {len(done):6} {fixed:5} {wont / len(done):8.0%} {median:6g}")


def ttr_any(rows):
    """The same report, counting every way off the list as a remediation."""
    ttr(rows, closing=("fixed", "wont_fix", "false_positive"))


REPORTS = {"ttr": ttr, "ttr-any": ttr_any, "debt": debt, "coverage": coverage,
           "trend": trend, "teams": teams}
REPORTS[sys.argv[1]](load())
