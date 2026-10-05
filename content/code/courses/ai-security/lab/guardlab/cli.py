"""guard: the defensive tools of the course ai-security.

Every command reads files under ~/guard and prints what it found. None of them
calls a model or the network; where a lesson needs what a model or a
provider would have answered, the file it reads says it was written by the
course.

    guard scan PATH...              personal data and secrets in a log
    guard redact FILE [--strict]    the same records with them replaced
    guard sweep [--now DATE] [--dry-run | --check]
                                    the retention policy, applied
"""
import argparse
import datetime as dt
import json
import os
import sys
from collections import Counter

from . import detect

HOME = os.environ.get("GUARD", os.path.expanduser("~/guard"))
TEXT = ("prompt", "output")


def records(paths):
    """Every record in the files named, or in the .jsonl files under a
    directory, in the order of their file names."""
    files = []
    for p in paths:
        if os.path.isdir(p):
            files += sorted(os.path.join(p, f) for f in os.listdir(p)
                            if f.endswith(".jsonl"))
        else:
            files.append(p)
    for f in files:
        with open(f, encoding="utf-8") as fh:
            for line in fh:
                if line.strip():
                    yield f, json.loads(line)


# ---- scan and redact ------------------------------------------------------

def cmd_scan(a):
    held, shaped, total, files = Counter(), Counter(), 0, set()
    any_hit = 0
    for f, rec in records(a.paths):
        files.add(f)
        total += 1
        kinds, rejected = set(), set()
        for field in TEXT:
            for kind, x, y, ok in detect.find(rec[field], a.strict):
                if ok:
                    kinds.add(kind)
                else:
                    rejected.add(kind)
                if a.show:
                    print("%s  %-6s  %-6s  %-8s %s" % (
                        rec["request"], field, kind,
                        "redact" if ok else "LEAVE", rec[field][x:y]))
        held.update(kinds)
        shaped.update(rejected)
        any_hit += bool(kinds)
    if a.show:
        print()
    print("%d records in %d files" % (total, len(files)))
    for kind in detect.KINDS:
        line = "  %-7s %2d records" % (kind, held[kind])
        if shaped[kind]:
            line += "   (%d more %s-shaped, check digits wrong)" % (
                shaped[kind], kind.upper() if kind == "cpf" else kind)
        print(line)
    print("%d of %d records hold at least one" % (any_hit, total))


def cmd_redact(a):
    for _, rec in records([a.file]):
        if a.request and rec["request"] != a.request:
            continue
        for i, field in enumerate(TEXT):
            print("%-8s %-6s  %s" % (rec["request"] if i == 0 else "", field,
                                    detect.redact(rec[field], a.strict)))


# ---- retention ------------------------------------------------------------

def day_of(name):
    return dt.date.fromisoformat(name.split(".")[0])


def load(name):
    with open(os.path.join(HOME, name), encoding="utf-8") as fh:
        return json.load(fh)


def cmd_sweep(a):
    policy = load("retention.json")
    holds = {h["file"]: h for h in load("holds.json")}
    now = dt.date.fromisoformat(a.now) if a.now else dt.date.today()
    print("policy: " + ", ".join("%s %d days" % (t, policy[t]["days"])
                                 for t in policy))
    gone = kept = late = 0
    for tier in policy:
        limit = policy[tier]["days"]
        folder = os.path.join(HOME, "logs", tier)
        for name in sorted(os.listdir(folder)):
            rel = tier + "/" + name
            age = (now - day_of(name)).days
            if age <= limit:
                continue
            hold = holds.get(rel)
            if hold and dt.date.fromisoformat(hold["until"]) >= now:
                print("%-27s %4d days  KEEP    hold %s until %s" % (
                    rel, age, hold["case"], hold["until"]))
                kept += 1
                continue
            if a.check:
                print("%-27s %4d days  OVERDUE limit %d" % (rel, age, limit))
                late += 1
                continue
            print("%-27s %4d days  %s" % (
                rel, age, "would delete" if a.dry_run else "deleted"))
            if not a.dry_run:
                os.remove(os.path.join(folder, name))
            gone += 1
    if a.check:
        print("%d file(s) past their limit, %d kept by a hold" % (late, kept))
        return 1 if late else 0
    print("%s%d file(s) %s, %d kept by a hold" % (
        "dry run: " if a.dry_run else "", gone,
        "would be deleted" if a.dry_run else "deleted", kept))
    return 0


# ---- the lab's own setup --------------------------------------------------

def cmd_build(a):
    """Lay data/calls.json out as the three tiers of logs. lab.sh runs it;
    the redacted copy is made by the same function `guard redact` uses."""
    calls = load("data/calls.json")
    by_day = {}
    for rec in calls:
        by_day.setdefault(rec["ts"][:10], []).append(rec)
    for tier in ("raw", "redacted", "metrics"):
        os.makedirs(os.path.join(HOME, "logs", tier), exist_ok=True)
    for day, recs in by_day.items():
        def write(tier, rows):
            with open(os.path.join(HOME, "logs", tier, day + ".jsonl"), "w",
                      encoding="utf-8") as fh:
                for row in rows:
                    fh.write(json.dumps(row, ensure_ascii=False) + "\n")
        write("raw", recs)
        write("redacted", [dict(r, **{f: detect.redact(r[f]) for f in TEXT})
                           for r in recs])
        write("metrics", [{
            "day": day, "surface": s, "calls": len(rs),
            "in_tokens": sum(r["in_tokens"] for r in rs),
            "out_tokens": sum(r["out_tokens"] for r in rs),
            "ms_max": max(r["ms"] for r in rs)}
            for s, rs in sorted(group(recs, "surface").items())])


def group(rows, key):
    out = {}
    for r in rows:
        out.setdefault(r[key], []).append(r)
    return out


def main(argv=None):
    p = argparse.ArgumentParser(prog="guard")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("scan")
    s.add_argument("paths", nargs="+")
    s.add_argument("--strict", action="store_true")
    s.add_argument("--show", action="store_true")
    s.set_defaults(fn=cmd_scan)

    s = sub.add_parser("redact")
    s.add_argument("file")
    s.add_argument("--strict", action="store_true")
    s.add_argument("--request")
    s.set_defaults(fn=cmd_redact)

    s = sub.add_parser("sweep")
    s.add_argument("--now")
    g = s.add_mutually_exclusive_group()
    g.add_argument("--dry-run", action="store_true")
    g.add_argument("--check", action="store_true")
    s.set_defaults(fn=cmd_sweep)

    s = sub.add_parser("_build")
    s.set_defaults(fn=cmd_build)

    a = p.parse_args(argv)
    return a.fn(a) or 0


if __name__ == "__main__":
    sys.exit(main())
