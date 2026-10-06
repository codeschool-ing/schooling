"""check_set.py: whether an evaluation set is still true of the documents, and holds nobody's data.

    python check_set.py SET [--docs FOLDER]
"""
import argparse
import hashlib
import json
import logging
import re

from presidio_analyzer import AnalyzerEngine

import docs
import redact

logging.disable(logging.WARNING)   # tldextract warns that it could not fetch a list; it uses its own copy
p = argparse.ArgumentParser()
p.add_argument("set")
p.add_argument("--docs", default="data/docs")
a = p.parse_args()
body = open(a.set, "rb").read()
cases = [json.loads(line) for line in body.decode().splitlines()]
manifest = json.load(open("data/eval-v2.manifest.json"))
shop = docs.load(a.docs)
squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.]", " ", t.lower())).strip()
analyzer = AnalyzerEngine()
problems = {"ids": [], "gold sections": [], "facts": [], "personal data": [], "documents": []}
ids = [c["id"] for c in cases]
problems["ids"] = sorted({i for i in ids if ids.count(i) > 1})
for c in cases:
    missing = [g for g in c["gold"] if g[0] not in shop or g[1] not in shop[g[0]][1]]
    if missing:
        problems["gold sections"].append(f"{c['id']} {missing}")
    elif c["facts"]:
        text = " ".join(shop[d][1][h] for d, h in c["gold"])
        if not any(squash(f) in squash(text) for f in c["facts"]):
            problems["facts"].append(f"{c['id']} {c['facts']}")
    allowed = set(c.get("synthetic", []))
    found = [c["question"][r.start:r.end] for r in analyzer.analyze(c["question"], language="en",
                                                                     entities=["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER"])]
    found += [m.group() for _, pattern in redact.PATTERNS for m in pattern.finditer(c["question"])]
    if set(found) - allowed:
        problems["personal data"].append(f"{c['id']} {sorted(set(found) - allowed)}")
for d, version in manifest["documents"].items():
    if shop[d][0]["version"] != version:
        problems["documents"].append(f"{d} is version {shop[d][0]['version']}, the set was checked against {version}")
pinned = hashlib.sha256(body).hexdigest() == manifest["sha256"]
print(f"{a.set}: {len(cases)} cases, {'the version the manifest pins' if pinned else 'NOT the version the manifest pins'}")
for name, found in problems.items():
    print(f"  {name:14} {'ok' if not found else ''}".rstrip())
    for line in found:
        print(f"    {line}")
