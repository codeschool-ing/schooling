"""guard: the defensive tools of the course ai-security.

Every command reads files under ~/guard and prints what it found. None of them
calls a model or the network; where a lesson needs what a model or a
provider would have answered, the file it reads says it was written by the
course.

    guard scan PATH...              personal data and secrets in a log
    guard redact FILE [--strict]    the same records with them replaced
    guard sweep [--now DATE] [--dry-run | --check]
                                    the retention policy, applied
    guard minimise TICKET --purpose NAME [--sensitive remove]
                                    what a third-party model is sent
    guard restore VAULT REPLY       its reply, with the placeholders put back
    guard sensitive TEXT            what the sensitive-data word list sees
    guard fairness FILE --group COL [--reference VALUE]
                                    rates per group, and the gaps between them
    guard score FILE                the stand-in scorer over a set of profiles
    guard counterfactual FILE       the same, with each CEP moved to the
                                    other end of the country
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


# ---- minimise and restore -------------------------------------------------

def cmd_minimise(a):
    from . import minimise as m
    with open(a.ticket, encoding="utf-8") as fh:
        raw = fh.read()
    ticket = json.loads(raw)
    purpose = load("data/purposes.json")[a.purpose]
    out, vault, report = m.minimise(ticket, purpose, a.sensitive == "remove")
    print("purpose    %s: %s" % (a.purpose, purpose["what"]))
    for label, text in report:
        print("%-10s %s" % (label, text))
    if out is None:
        print("NOTHING WRITTEN: sensitive data in the text. Remove it with "
              "--sensitive remove, or record the legal basis that allows "
              "sending it (LGPD art. 11) and change the purpose.")
        return 3
    body = json.dumps(out, ensure_ascii=False, indent=1) + "\n"
    name = ticket["ticket"] + ".json"
    for folder, data in (("outbox", body),
                         ("vault", json.dumps(vault.by_token, ensure_ascii=False,
                                              indent=1) + "\n")):
        os.makedirs(os.path.join(HOME, folder), exist_ok=True)
        with open(os.path.join(HOME, folder, name), "w", encoding="utf-8") as fh:
            fh.write(data)
    print("%-10s %d -> %d" % ("bytes", len(raw.encode()), len(body.encode())))
    print("%-10s outbox/%s (to the provider), vault/%s (stays here)" % (
        "wrote", name, name))
    return 0


def cmd_sensitive(a):
    from . import minimise as m
    found = m.sensitive_terms(a.text)
    if not found:
        print("nothing found")
    for cat, words in found.items():
        print("%s: %s" % (cat, ", ".join(words)))


def cmd_restore(a):
    from . import minimise as m
    with open(a.vault, encoding="utf-8") as fh:
        vault = json.load(fh)
    with open(a.reply, encoding="utf-8") as fh:
        text, unknown = m.restore(fh.read(), vault)
    sys.stdout.write(text)
    if unknown:
        print("UNKNOWN placeholder(s), left as they were: " + ", ".join(unknown))
        return 4
    return 0


# ---- fairness ---------------------------------------------------------------

def fmt(x):
    return "  -  " if x != x else "%.2f" % x


def cmd_fairness(a):
    from . import fairness as f
    groups = f.load(a.file, a.group)
    stats = {g: f.rates(rows) for g, rows in groups.items()}
    print("%-10s %4s  %5s  %8s  %5s  %5s  %9s" % (
        a.group, "n", "base", "selected", "TPR", "FPR", "precision"))
    for g, s in stats.items():
        if s["n"] < f.MINIMUM:
            print("%-10s %4d  too few to measure (fewer than %d)" % (g, s["n"], f.MINIMUM))
            continue
        print("%-10s %4d  %5s  %8s  %5s  %5s  %9s" % (
            g, s["n"], fmt(s["base"]), fmt(s["selected"]), fmt(s["tpr"]),
            fmt(s["fpr"]), fmt(s["precision"])))
    measured = {g: s for g, s in stats.items() if s["n"] >= f.MINIMUM}
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
        for key, name in (("tpr", "TPR gap"), ("fpr", "FPR gap"),
                          ("precision", "precision gap")):
            print("  %-17s %+.2f" % (name, s[key] - r[key]))


def profiles(path):
    with open(path, encoding="utf-8") as fh:
        return [json.loads(line) for line in fh if line.strip()]


def cmd_score(a):
    from . import standin
    print("%-8s %-9s %-10s %6s %4s  %5s  %s" % (
        "who", "region", "cep", "rating", "jobs", "score", "shortlisted"))
    for p in profiles(a.file):
        s = standin.score(p)
        print("%-8s %-9s %-10s %6.1f %4d  %5.2f  %s" % (
            p["applicant"], p["region"], p["cep"], p["rating"], p["jobs"], s,
            "yes" if s >= standin.THRESHOLD else "no"))
    print("threshold %.1f" % standin.THRESHOLD)


def cmd_counterfactual(a):
    """Moves every CEP to the other end of the country and scores again.
    Nothing else about the profile changes, so any decision that flips was
    decided by the CEP alone."""
    from . import standin
    flips = {}
    print("%-8s %-9s %-10s %5s   %-10s %5s" % (
        "who", "region", "cep", "score", "swapped", "score"))
    for p in profiles(a.file):
        other = dict(p, cep="50010-000" if p["cep"][0] in "0123" else "01310-100")
        s1, s2 = standin.score(p), standin.score(other)
        before, after = s1 >= standin.THRESHOLD, s2 >= standin.THRESHOLD
        note = ""
        if before != after:
            note = "  FLIP: %s" % ("shortlisted -> out" if before else "out -> shortlisted")
            flips[p["region"]] = flips.get(p["region"], 0) + 1
        print("%-8s %-9s %-10s %5.2f   %-10s %5.2f%s" % (
            p["applicant"], p["region"], p["cep"], s1, other["cep"], s2, note))
    total = len(profiles(a.file))
    print("%d of %d decisions changed when only the CEP did (%s)" % (
        sum(flips.values()), total,
        ", ".join("%s %d" % kv for kv in flips.items()) or "none"))


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
    from . import fairness
    for version in fairness.COUNTS:
        fairness.build(os.path.join(HOME, "data", "shortlist-%s.csv" % version), version)


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

    s = sub.add_parser("minimise")
    s.add_argument("ticket")
    s.add_argument("--purpose", required=True)
    s.add_argument("--sensitive", choices=["hold", "remove"], default="hold")
    s.set_defaults(fn=cmd_minimise)

    s = sub.add_parser("restore")
    s.add_argument("vault")
    s.add_argument("reply")
    s.set_defaults(fn=cmd_restore)

    s = sub.add_parser("sensitive")
    s.add_argument("text")
    s.set_defaults(fn=cmd_sensitive)

    s = sub.add_parser("fairness")
    s.add_argument("file")
    s.add_argument("--group", required=True)
    s.add_argument("--reference")
    s.set_defaults(fn=cmd_fairness)

    s = sub.add_parser("score")
    s.add_argument("file")
    s.set_defaults(fn=cmd_score)

    s = sub.add_parser("counterfactual")
    s.add_argument("file")
    s.set_defaults(fn=cmd_counterfactual)

    s = sub.add_parser("_build")
    s.set_defaults(fn=cmd_build)

    a = p.parse_args(argv)
    return a.fn(a) or 0


if __name__ == "__main__":
    sys.exit(main())
