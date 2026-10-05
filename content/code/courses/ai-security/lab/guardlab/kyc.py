"""Knowing the customer before opening the model to it.

The applications, the registry and the usage log in data/ were WRITTEN BY
THE COURSE. data/cnpj-registry.json stands in for the Receita Federal's
public CNPJ data, which a real check would query; nothing here reaches the
network. The CNPJ check digits are the real algorithm.

The policy is in data/use-cases.json and data/tiers.json, and every
decision this module prints names the rule that made it, so a refusal can
be explained to the company that was refused.
"""
import datetime as dt
import re

YOUNG = 180  # days: a company this new has no history to judge by


def cnpj_ok(cnpj):
    d = [int(c) for c in cnpj if c.isdigit()]
    if len(d) != 14 or len(set(d)) == 1:
        return False
    for n, w in ((12, [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]),
                 (13, [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2])):
        r = sum(x * y for x, y in zip(d[:n], w)) % 11
        if d[n] != (0 if r < 2 else 11 - r):
            return False
    return True


def domain(address):
    return address.split("@")[-1].lower() if "@" in address else address.lower()


def onboard(app, registry, use_cases, now):
    """(decision, tier, reasons). Every check runs, so the reasons list
    everything that is wrong, not only the first thing."""
    reasons, stop, review = [], False, False
    if not cnpj_ok(app["cnpj"]):
        reasons.append("CNPJ check digits are wrong")
        stop = True
    else:
        entry = registry.get(app["cnpj"])
        if entry is None:
            reasons.append("CNPJ not in the registry")
            stop = True
        elif entry["status"] != "ATIVA":
            reasons.append("CNPJ status is %s" % entry["status"])
            stop = True
        else:
            age = (now - dt.date.fromisoformat(entry["opened"])).days
            if age < YOUNG:
                reasons.append("company opened %d days ago" % age)
    if domain(app["contact"]) != domain(app["website"]):
        reasons.append("contact %s is not at %s" % (domain(app["contact"]), app["website"]))
    case = app["use_case"]
    if case in use_cases["prohibited"]:
        reasons.append("use case %s is prohibited" % case)
        stop = True
    elif case in use_cases["review"]:
        reasons.append("use case %s needs a person to approve it" % case)
        review = True
    elif case not in use_cases["allowed"]:
        reasons.append("use case %s is on no list" % case)
        review = True
    hits = [m.group(0) for m in (re.search(p, app["description"], re.I)
                                 for p in use_cases["prohibited_phrases"]) if m]
    if hits:
        reasons.append("description says \"%s\", a prohibited use" % "\", \"".join(hits))
        review = True
    if stop:
        return "REFUSE", "-", reasons
    if review:
        return "REVIEW", "sandbox", reasons
    if reasons:
        return "VERIFY", "sandbox", reasons
    return "ACCEPT", "tier-1", ["all checks passed"]
