---
title: Keeping it true
version: 1
---

A set decays in two ways that nobody notices: the documents change and its facts stop being true, and
somebody adds a case without the care the first ones had. `check_set.py` checks for both, on every
case, in seconds:

```python
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

logging.disable(logging.WARNING)   # Presidio warns about every recogniser it loads; none of it is news here
p = argparse.ArgumentParser()
p.add_argument("set")
p.add_argument("--docs", default="data/docs")
a = p.parse_args()
body = open(a.set, "rb").read()
cases = [json.loads(line) for line in body.decode().splitlines()]
manifest = json.load(open("data/eval-v2.manifest.json"))
shop = docs.load(a.docs)
chunks = {cid: text for _, found in shop.values() for cid, text in found.items()}
squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.$]", " ", t.lower())).strip()
analyzer = AnalyzerEngine()
problems = {"ids": [], "gold chunks": [], "facts": [], "personal data": [], "documents": []}
ids = [c["id"] for c in cases]
problems["ids"] = sorted({i for i in ids if ids.count(i) > 1})
for c in cases:
    missing = [g for g in c["gold"] if g not in chunks]
    if missing:
        problems["gold chunks"].append(f"{c['id']} {missing}")
    elif c["facts"]:
        text = " ".join(chunks[g] for g in c["gold"])
        if not any(squash(f) in squash(text) for f in c["facts"]):
            problems["facts"].append(f"{c['id']} {c['facts']}")
    allowed = set(c.get("synthetic", []))
    found = [c["question"][r.start:r.end] for r in analyzer.analyze(c["question"], language="en",
                                                                     entities=["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER"])]
    found += [m.group() for _, pattern in redact.PATTERNS for m in pattern.finditer(c["question"])]
    if set(found) - allowed:
        problems["personal data"].append(f"{c['id']} {sorted(set(found) - allowed)}")
for d, updated in manifest["documents"].items():
    if shop[d][0]["updated"] != updated:
        problems["documents"].append(f"{d} was updated {shop[d][0]['updated']}, the set was checked against {updated}")
pinned = hashlib.sha256(body).hexdigest() == manifest["sha256"]
print(f"{a.set}: {len(cases)} cases, {'the version the manifest pins' if pinned else 'NOT the version the manifest pins'}")
for name, found in problems.items():
    print(f"  {name:14} {'ok' if not found else ''}".rstrip())
    for line in found:
        print(f"    {line}")
```

Five checks, each a line of the report:

- **ids**: no id appears twice.
- **gold sections**: every section a case points to still exists, by document and heading.
- **facts**: at least one of a case's facts is in the text of its gold sections.
- **personal data**: nothing in a question looks like a name, an e-mail address, a telephone number or
  an order number, by Presidio and by lesson 2's patterns, except the values the case declares
  synthetic.
- **documents**: every document is still at the version the manifest pinned.

On version 2 as built:

```
ana@lab:~/obs$ python check_set.py data/eval-v2.jsonl
data/eval-v2.jsonl: 42 cases, the version the manifest pins
  ids            ok
  gold sections  ok
  facts          ok
  personal data  ok
  documents      ok
```

## Two ways it goes wrong

**A case pasted straight from the harvest.** Somebody copies the third line of the harvest into a draft
of the set, keeping its name:

```
ana@lab:~/obs$ cp data/eval-v2.jsonl draft.jsonl && echo '{"id": "e43", "question": "Order [order] - I want to return it. Who pays for the return postage? Tiago Moura, [phone]", "gold": [["returns-policy", "How to start a return"]], "facts": ["Returns are free"]}' >> draft.jsonl
ana@lab:~/obs$ python check_set.py draft.jsonl
draft.jsonl: 43 cases, NOT the version the manifest pins
  ids            ok
  gold sections  ok
  facts          ok
  personal data
    e43 ['Tiago Moura']
  documents      ok
```

Presidio finds the name. The order number and the telephone were already replaced by the harvest's
redaction, so the patterns have nothing left to find. The name would have gone into the repository, into
every run's output, and into every pull request that shows a failing case. The first line of the report
says something too: the draft is not the version the manifest pins, which is true of any edited set
until it is built and released as a new version.

**A document that changes.** The shop raises the free-delivery threshold from 40 to 50, and the shipping
document goes from version 6 to version 7. Here the change is made to a copy:

```
ana@lab:~/obs$ cp -r data/docs docs-next && sed -i -e 's/free on orders over 40/free on orders over 50/' -e 's/^version: 6$/version: 7/' docs-next/shipping-and-delivery.md
ana@lab:~/obs$ python check_set.py data/eval-v2.jsonl --docs docs-next
data/eval-v2.jsonl: 42 cases, the version the manifest pins
  ids            ok
  gold sections  ok
  facts
    e07 ['free on orders over 40']
    e33 ['free on orders over 40']
  personal data  ok
  documents
    shipping-and-delivery is version 7, the set was checked against 6
```

**Two cases have become false**, e07 from version 1 and e33 from this lesson's additions, and the
manifest says why it is worth looking: the document they rest on is not the version the set was checked
against. Without the check, both cases would start failing every release from the day the document
changed, and the failures would be the set's fault, not the assistant's: a model that answered "free on
orders over 50" would be marked wrong for being right.

The fix is the maintenance this lesson's title promises: retire both cases, write new ones with the new
fact, and release version 3. Lesson 15 runs this check in the build, so that the day the documents
change is the day somebody is told.
