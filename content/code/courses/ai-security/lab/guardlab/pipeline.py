"""The filters a reply passes through before a client sees it, in order.

Each layer is a module from an earlier lesson: detect.py (personal data and
secrets, lesson 11), the canary check below, moderation.py (lesson 6) and the
host allowlist of shapes.py (lesson 9). A reply is blocked by the first layer
that objects, and the report names the layer, so that a block can be traced
to the rule that made it.

THE CANARY is a marker written into the system prompt in data/system-prompt.txt
and nowhere else. It means nothing and is never meant to appear in a reply,
so a reply that contains it has repeated the system prompt, and the reply is
blocked and an alert raised. It detects a verbatim leak and nothing more: a
reply that paraphrases the instructions does not carry the marker.

THE REPLIES IN data/pipeline-outputs.jsonl WERE WRITTEN BY THE COURSE; no
model produced them.
"""
import re
from urllib.parse import urlsplit

from . import detect, moderation

URL = re.compile(r"https?://[^\s)\"']+")


def canary_of(system_prompt):
    m = re.search(r"CANARY-[A-Z0-9-]+", system_prompt)
    return m.group(0) if m else None


def layers(canary, hosts, threshold):
    def personal(text):
        kinds = sorted({k for k, _, _, ok in detect.find(text) if ok})
        return "personal data: " + ", ".join(kinds) if kinds else None

    def leak(text):
        return "system prompt marker %s in the reply: ALERT" % canary if canary and canary in text else None

    def abuse(text):
        scores = moderation.moderate(text)
        over = ["%s %.2f" % (c, s) for c, s in scores.items() if s >= threshold]
        return "moderation: " + ", ".join(over) if over else None

    def links(text):
        bad = [u for u in URL.findall(text) if urlsplit(u).hostname not in hosts]
        return "link to a host not on the allowlist: " + ", ".join(bad) if bad else None

    return [("personal-data", personal), ("canary", leak), ("moderation", abuse), ("links", links)]


def run(text, chain):
    for name, check in chain:
        why = check(text)
        if why:
            return name, why
    return None, None
