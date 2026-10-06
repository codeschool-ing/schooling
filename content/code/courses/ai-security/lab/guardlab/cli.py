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
    guard moderate TEXT             the stand-in moderation endpoint's scores
    guard modeval FILE --category C (--threshold T [--show] | --sweep |
                  --review R --block B)
                                    the endpoint measured against labels
    guard enduser ACCOUNT [--provider P] | --naive EMAIL
                                    the id sent to a provider for one user
    guard reverse HASH --list FILE  a dictionary attack on such an id
    guard ratelimit FILE --per-key N [--per-user M]
                                    a request log replayed against limits
    guard cnpj NUMBER               whether a CNPJ's check digits are right
    guard onboard FILE [--id ID]    applications for API access, decided
    guard drift ACCOUNT [--limit PCT]
                                    a customer's usage against its use case
    guard check-in FILE             requests against the input rules
    guard check-out FILE            model replies against the output schema
    guard retry ID [ID ...]         the retry loop, with course-written replies
                                    standing in for the model's attempts
    guard filter FILE [--skip LAYER]
                                    replies through the chain of output filters
    guard ground FILE               answers against the help centre they cite
    guard deps FILE                 suggested packages against a registry snapshot
    guard gate FILE [--confirm ID --by NAME] [--budget N]
                                    proposed tool calls against the manifest
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


# ---- moderation -------------------------------------------------------------

def cmd_moderate(a):
    from . import moderation as m
    print(json.dumps(m.moderate(a.text)))


def ratio(a, b):
    return "%.2f" % (a / b) if b else "  - "


def cmd_modeval(a):
    from . import moderation as m
    rows = m.load(a.file)
    cat = a.category
    pos = sum(1 for r in rows if cat in r["labels"])
    print("category %s: %d of %d messages labelled %s by a person" % (
        cat, pos, len(rows), cat))
    if a.sweep:
        print("threshold  flagged  precision  recall")
        for t in [x / 10 for x in range(1, 10)]:
            tp, fp, fn, tn = m.confusion(rows, cat, t)
            print("     %.1f      %3d       %s    %s" % (
                t, tp + fp, ratio(tp, tp + fp), ratio(tp, tp + fn)))
        return 0
    if a.block is not None:
        lanes = {"block": [0, 0], "review": [0, 0], "publish": [0, 0]}
        for r in rows:
            s = m.moderate(r["text"])[cat]
            lane = "block" if s >= a.block else "review" if s >= a.review else "publish"
            lanes[lane][0 if cat in r["labels"] else 1] += 1
            if a.show and (lane == "block") != (cat in r["labels"]) and lane != "review":
                print("  %-7s %s %.2f  %s" % (lane, r["id"], s, r["text"]))
        print("lane     score        labelled yes  labelled no")
        print("block    >= %.2f            %3d          %3d" % (a.block, *lanes["block"]))
        print("review   %.2f-%.2f          %3d          %3d" % (a.review, a.block, *lanes["review"]))
        print("publish  <  %.2f            %3d          %3d" % (a.review, *lanes["publish"]))
        return 0
    tp, fp, fn, tn = m.confusion(rows, cat, a.threshold)
    print("threshold %.2f" % a.threshold)
    print("              labelled yes  labelled no")
    print("flagged               %3d          %3d" % (tp, fp))
    print("not flagged           %3d          %3d" % (fn, tn))
    print("precision %s   recall %s" % (ratio(tp, tp + fp), ratio(tp, tp + fn)))
    for lang in sorted({r["lang"] for r in rows}):
        sub = [r for r in rows if r["lang"] == lang]
        ltp, _, lfn, _ = m.confusion(sub, cat, a.threshold)
        print("  recall, messages in %s: %d of %d" % (lang, ltp, ltp + lfn))
    if a.show:
        for r in rows:
            s = m.moderate(r["text"])[cat]
            flagged, labelled = s >= a.threshold, cat in r["labels"]
            if flagged != labelled:
                print("  %s %s %.2f  %s" % ("FALSE POSITIVE" if flagged else "MISSED        ",
                                           r["id"], s, r["text"]))
    return 0


# ---- end-user ids and rate limits ------------------------------------------

def cmd_enduser(a):
    from . import enduser as e
    if a.naive:
        print(e.naive_id(a.naive))
        return 0
    with open(os.path.join(HOME, "keys", a.provider + ".key"), "rb") as fh:
        key = fh.read().strip()
    print(e.end_user_id(a.account, key))
    return 0


def cmd_reverse(a):
    from . import enduser as e
    with open(a.list, encoding="utf-8") as fh:
        guesses = [line.strip() for line in fh if line.strip()]
    for n, g in enumerate(guesses, 1):
        if e.naive_id(g) == a.hash:
            print("found after %d guesses: %s" % (n, g))
            return 0
    print("not found in %d guesses" % len(guesses))
    return 1


def cmd_ratelimit(a):
    from . import ratelimit as r
    with open(a.file) as fh:
        rows = [json.loads(line) for line in fh if line.strip()]
    out = r.replay(rows, a.per_key, a.per_user)
    print("limits: %d a minute per key%s" % (
        a.per_key, ", %d a minute per user" % a.per_user if a.per_user else ""))
    print("%-25s %5s %8s %8s" % ("end user", "sent", "allowed", "refused"))
    for user in sorted(out):
        sent, allowed = out[user]
        print("%-25s %5d %8d %8d" % (user, sent, allowed, sent - allowed))
    hit = [u for u, (s_, al) in out.items() if s_ > al]
    print("%d of %d users had a request refused" % (len(hit), len(out)))
    return 0


# ---- knowing the customer ----------------------------------------------------

def cmd_cnpj(a):
    from . import kyc
    ok = kyc.cnpj_ok(a.number)
    print("%s  check digits %s" % (a.number, "right" if ok else "WRONG"))
    return 0 if ok else 1


def cmd_onboard(a):
    from . import kyc
    registry = load("data/cnpj-registry.json")
    use_cases = load("data/use-cases.json")
    with open(a.file, encoding="utf-8") as fh:
        apps = [json.loads(line) for line in fh if line.strip()]
    for app in apps:
        if a.id and app["id"] != a.id:
            continue
        now = dt.date.fromisoformat(a.now) if a.now else dt.date.today()
        decision, tier, reasons = kyc.onboard(app, registry, use_cases, now)
        print("%-5s  %-22s %-7s %-8s %s" % (app["id"], app["company"], decision, tier, reasons[0]))
        for r in reasons[1:]:
            print("%-5s  %-22s %-7s %-8s %s" % ("", "", "", "", r))


def cmd_drift(a):
    declared = {"p-docelar": "customer-support"}[a.account]
    with open(os.path.join(HOME, "data", "partner-usage.jsonl")) as fh:
        rows = [json.loads(line) for line in fh if line.strip()]
    weeks = {}
    for r in rows:
        if r["account"] == a.account:
            weeks.setdefault(r["week"], {})[r["topic"]] = r["requests"]
    print("%s declared: %s" % (a.account, declared))
    print("week       requests  in use case  outside  largest outside")
    for week, topics in weeks.items():
        n = sum(topics.values())
        inside = topics.get(declared, 0)
        out = {t: k for t, k in topics.items() if t != declared}
        top = max(out, key=out.get) if out else "-"
        share = 100 * (n - inside) / n
        flag = "  DRIFT" if share > a.limit else ""
        print("%s  %8d  %10.0f%%  %6.0f%%  %s%s" % (
            week, n, 100 * inside / n, share, top, flag))
    print("limit: more than %d%% of a week outside the declared use case" % a.limit)


# ---- inputs and outputs ------------------------------------------------------

def jsonl(path):
    with open(path, encoding="utf-8") as fh:
        return [json.loads(line) for line in fh if line.strip()]


def report(ident, problems):
    if not problems:
        print("%-6s ok" % ident)
    for i, p in enumerate(problems):
        print("%-6s %-7s %s" % (ident if i == 0 else "", "REJECT" if i == 0 else "", p))


def cmd_check_in(a):
    from . import shapes
    rules = load("data/input-rules.json")
    bad = 0
    for req in jsonl(a.file):
        ident = req.pop("id")
        problems = shapes.check_input(req, rules)
        bad += bool(problems)
        report(ident, problems)
    return 1 if bad else 0


def cmd_check_out(a):
    from . import shapes
    schema = load("data/output-schema.json")
    hosts = load("data/allowed-hosts.json")
    budgets = {r["id"]: r.get("budget_cents") for r in jsonl(os.path.join(HOME, "data", "inputs.jsonl"))}
    bad = 0
    for out in jsonl(a.file):
        if a.id and out["id"] != a.id:
            continue
        if a.show:
            print(out["text"])
        problems = shapes.check_output(out["text"], schema, hosts, budgets.get(out["request"]))
        bad += bool(problems)
        report(out["id"], problems)
    return 1 if bad else 0


def cmd_retry(a):
    """THE MODEL IS A STAND-IN HERE: each attempt is the next reply named on
    the command line, taken from data/outputs.jsonl, which the course wrote.
    What is real is the loop and the checks."""
    from . import retry, shapes
    schema = load("data/output-schema.json")
    hosts = load("data/allowed-hosts.json")
    texts = {o["id"]: o["text"] for o in jsonl(os.path.join(HOME, "data", "outputs.jsonl"))}
    replies = iter(a.ids)

    def call(feedback):
        if feedback:
            print("           sent back: %d problem(s) with the previous reply" % len(feedback))
        return texts[next(replies)]

    def check(text):
        return shapes.check_output(text, schema, hosts, 120000)

    for n, problems in retry.ask(call, check, attempts=len(a.ids)):
        print("attempt %d  %s" % (n, "ok" if not problems else "REJECT " + problems[0]))
        for p in problems[1:]:
            print("                  %s" % p)
    if problems:
        print("no valid reply after %d attempts: the job goes to a person" % len(a.ids))
        return 1
    return 0


# ---- the filter chain ------------------------------------------------------

def cmd_filter(a):
    from . import pipeline
    with open(os.path.join(HOME, "data", "system-prompt.txt"), encoding="utf-8") as fh:
        canary = pipeline.canary_of(fh.read())
    chain = [l for l in pipeline.layers(canary, load("data/allowed-hosts.json"), 0.5)
             if l[0] not in (a.skip or [])]
    print("layers: " + " -> ".join(n for n, _ in chain))
    for out in jsonl(a.file):
        layer, why = pipeline.run(out["text"], chain)
        print("%-3s %-5s %s" % (out["id"], "pass" if not layer else "BLOCK", why or ""))
    return 0


# ---- grounding ----------------------------------------------------------------

def cmd_ground(a):
    from . import ground
    docs = ground.load_docs(os.path.join(HOME, "data", "helpdesk"))
    bad = 0
    for ans in jsonl(a.file):
        notes, ok = ground.check(ans, docs)
        bad += not ok
        print("%-3s %-5s %s" % (ans["id"], "ok" if ok else "FLAG", notes[0]))
        for n in notes[1:]:
            print("%-3s %-5s %s" % ("", "", n))
    print("%d of %d answers flagged" % (bad, len(jsonl(a.file))))
    return 1 if bad else 0


def cmd_deps(a):
    from . import ground
    with open(os.path.join(HOME, "data", "registry-snapshot.txt")) as fh:
        registry = {line.strip().lower() for line in fh if line.strip()}
    with open(a.file) as fh:
        names = [line.strip() for line in fh if line.strip()]
    missing = 0
    for name, known in ground.deps(names, registry):
        missing += not known
        print("%-26s %s" % (name, "in the snapshot" if known else "NOT IN THE SNAPSHOT: do not install"))
    return 1 if missing else 0


# ---- tool calls -------------------------------------------------------------

def cmd_gate(a):
    from . import toolgate
    manifest = load("data/tools.json")
    session = manifest["session"]
    if a.budget:
        manifest["calls_per_conversation"] = a.budget
    confirmed = {a.confirm: a.by} if a.confirm else {}
    if a.confirm and not a.by:
        print("a confirmation names the person who gave it: add --by NAME")
        return 2
    print("session %s, %d calls allowed" % (session["account"], manifest["calls_per_conversation"]))
    for call, decision, why in toolgate.run(jsonl(a.file), session, manifest, confirmed):
        print("%-3s %-14s %-5s  %s" % (call["id"], call["tool"], decision, why))
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
    from . import ratelimit
    ratelimit.build(os.path.join(HOME, "data", "api-requests.jsonl"))
    first = ["ana", "bruno", "carla", "diego", "elisa", "fernanda", "gustavo", "helena",
             "igor", "juliana", "karina", "lucas", "marcos", "natalia", "otavio", "paula",
             "rafael", "sofia", "tiago", "vitoria"]
    last = ["almeida", "barros", "costa", "dias", "ferreira", "gomes", "lima", "moreira",
            "nunes", "oliveira", "prado", "ribeiro", "rocha", "santos", "silva", "souza",
            "teixeira", "vieira", "xavier", "zanetti"]
    with open(os.path.join(HOME, "data", "emails.txt"), "w") as fh:
        for f in first:
            for l in last:
                fh.write("%s.%s@example.com.br\n" % (f, l))
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

    s = sub.add_parser("moderate")
    s.add_argument("text")
    s.set_defaults(fn=cmd_moderate)

    s = sub.add_parser("modeval")
    s.add_argument("file")
    s.add_argument("--category", required=True)
    s.add_argument("--threshold", type=float, default=0.5)
    s.add_argument("--show", action="store_true")
    s.add_argument("--sweep", action="store_true")
    s.add_argument("--review", type=float)
    s.add_argument("--block", type=float)
    s.set_defaults(fn=cmd_modeval)

    s = sub.add_parser("enduser")
    s.add_argument("account", nargs="?")
    s.add_argument("--provider", default="provider-a")
    s.add_argument("--naive")
    s.set_defaults(fn=cmd_enduser)

    s = sub.add_parser("reverse")
    s.add_argument("hash")
    s.add_argument("--list", required=True)
    s.set_defaults(fn=cmd_reverse)

    s = sub.add_parser("ratelimit")
    s.add_argument("file")
    s.add_argument("--per-key", type=int, required=True)
    s.add_argument("--per-user", type=int)
    s.set_defaults(fn=cmd_ratelimit)

    s = sub.add_parser("cnpj")
    s.add_argument("number")
    s.set_defaults(fn=cmd_cnpj)

    s = sub.add_parser("onboard")
    s.add_argument("file")
    s.add_argument("--id")
    s.add_argument("--now")
    s.set_defaults(fn=cmd_onboard)

    s = sub.add_parser("drift")
    s.add_argument("account")
    s.add_argument("--limit", type=int, default=30)
    s.set_defaults(fn=cmd_drift)

    s = sub.add_parser("check-in")
    s.add_argument("file")
    s.set_defaults(fn=cmd_check_in)

    s = sub.add_parser("check-out")
    s.add_argument("file")
    s.add_argument("--id")
    s.add_argument("--show", action="store_true")
    s.set_defaults(fn=cmd_check_out)

    s = sub.add_parser("retry")
    s.add_argument("ids", nargs="+")
    s.set_defaults(fn=cmd_retry)

    s = sub.add_parser("filter")
    s.add_argument("file")
    s.add_argument("--skip", action="append")
    s.set_defaults(fn=cmd_filter)

    s = sub.add_parser("ground")
    s.add_argument("file")
    s.set_defaults(fn=cmd_ground)

    s = sub.add_parser("deps")
    s.add_argument("file")
    s.set_defaults(fn=cmd_deps)

    s = sub.add_parser("gate")
    s.add_argument("file")
    s.add_argument("--confirm")
    s.add_argument("--by")
    s.add_argument("--budget", type=int)
    s.set_defaults(fn=cmd_gate)

    s = sub.add_parser("_build")
    s.set_defaults(fn=cmd_build)

    a = p.parse_args(argv)
    return a.fn(a) or 0


if __name__ == "__main__":
    sys.exit(main())
