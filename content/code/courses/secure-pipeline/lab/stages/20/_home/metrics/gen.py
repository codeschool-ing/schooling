"""A year of security findings for a made-up company of four teams, the
same every time it runs. It writes two files: inventory.csv, what exists
and which scanners look at it, and findings.csv, what those scanners found
and what happened to each finding."""
import csv
import datetime as dt
import math
import random

rng = random.Random(19)
START, TODAY = dt.date(2025, 10, 1), dt.date(2026, 10, 1)

# What exists: name, team, kind, and the scanners that run on it.
INVENTORY = [
    ("linkbox", "links", "repo", "sast sca secrets"),
    ("linkbox", "links", "image", "image"),
    ("link-stats", "links", "repo", "sast sca secrets"),
    ("billing-api", "payments", "repo", "sast sca secrets"),
    ("billing-api", "payments", "image", "image"),
    ("invoices", "payments", "repo", "sca secrets"),
    ("refunds-worker", "payments", "image", ""),
    ("storefront", "web", "repo", "sast sca secrets"),
    ("storefront", "web", "image", "image"),
    ("web-assets", "web", "repo", "secrets"),
    ("auth-gateway", "platform", "repo", "sast sca secrets"),
    ("auth-gateway", "platform", "image", "image"),
    ("legacy-reports", "platform", "repo", ""),
    ("legacy-reports", "platform", "image", ""),
]

# Findings a scanner raises per month on one target, and their severities.
RATE = {"sast": 2.0, "sca": 2.5, "secrets": 0.2, "image": 4.0}
SEVERITY = {"critical": 0.05, "high": 0.20, "medium": 0.45, "low": 0.30}
# The median number of days a fix takes, per severity.
TYPICAL_FIX = {"critical": 5, "high": 18, "medium": 40, "low": 70}


def poisson(mean):
    n, p, limit = 0, 1.0, math.exp(-mean)
    while True:
        p *= rng.random()
        if p < limit:
            return n
        n += 1


def outcome(team, severity):
    """How a finding leaves the open list, and how many days that takes."""
    roll = rng.random()
    if roll < 0.08:
        return "false_positive", rng.randint(1, 10)
    # One team closes much of what is not urgent as "won't fix", and fast.
    if team == "payments" and severity in ("medium", "low") and roll < 0.55:
        return "wont_fix", rng.randint(1, 5)
    if roll < 0.12:
        return "wont_fix", rng.randint(10, 60)
    return "fixed", max(1, round(TYPICAL_FIX[severity] * rng.lognormvariate(0, 0.9)))


findings = []
for name, team, kind, scanners in INVENTORY:
    for tool in scanners.split():
        day = START
        while day < TODAY:
            for _ in range(poisson(RATE[tool] / 30)):
                severity = rng.choices(list(SEVERITY), list(SEVERITY.values()))[0]
                if tool == "secrets":  # a leaked credential is high, always
                    severity = "high"
                resolution, days = outcome(team, severity)
                closed = day + dt.timedelta(days=days)
                if closed > TODAY:
                    resolution, closed = "", None
                findings.append([name, kind, team, tool, severity, day, closed, resolution])
            day += dt.timedelta(days=1)

findings.sort(key=lambda f: f[5])
with open("findings.csv", "w", newline="") as out:
    w = csv.writer(out)
    w.writerow(["id", "target", "kind", "team", "tool", "severity", "opened", "closed", "resolution"])
    for n, f in enumerate(findings, 1):
        w.writerow([f"F{n:04d}", *f[:6], f[6] or "", f[7]])
with open("inventory.csv", "w", newline="") as out:
    w = csv.writer(out)
    w.writerow(["target", "team", "kind", "scanners"])
    w.writerows(INVENTORY)
print(f"{len(findings)} findings on {len(INVENTORY)} targets")
