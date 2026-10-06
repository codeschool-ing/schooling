---
title: A version, and what pins it
version: 1
---

A set that changes under a comparison makes the comparison meaningless: a release that scores better
on forty-two cases than its predecessor did on thirty has not been compared with anything. So a set is
**released in versions**, like code, and every result names the version it was measured on.

`buildset.py` makes version 2: the thirty cases of version 1, the twelve additions, the split each
case belongs to, and a manifest:

```python
"""buildset.py: version 2 of the evaluation set, version 1 and the additions, and a manifest that pins it."""
import hashlib
import json

import docs

v1 = open("data/eval.jsonl", "rb").read()
cases = [json.loads(line) for line in v1.decode().splitlines()]
cases += [json.loads(line) for line in open("data/eval-additions.jsonl")]
ids = [c["id"] for c in cases]
assert len(ids) == len(set(ids)), "an id is used twice"
for c in cases:   # every third question is held out, decided by its id and nothing else, as in rag
    c["split"] = "held-out" if int(c["id"][1:]) % 3 == 0 else "dev"
body = "".join(json.dumps(c, ensure_ascii=False) + "\n" for c in cases).encode()
open("data/eval-v2.jsonl", "wb").write(body)
shop = docs.load()
manifest = {"set": "marginalia-help", "version": 2, "cases": len(cases),
            "sha256": hashlib.sha256(body).hexdigest(), "parent": hashlib.sha256(v1).hexdigest(),
            "splits": {s: sum(c["split"] == s for c in cases) for s in ("dev", "held-out")},
            "documents": {d: shop[d][0]["version"] for d in sorted({g[0] for c in cases for g in c["gold"]})}}
json.dump(manifest, open("data/eval-v2.manifest.json", "w"), indent=1)
print(json.dumps(manifest, indent=1))
```

`docs.py`, which the build and the check share, reads each document's front matter and the text
under each of its headings:

```python
"""docs.py: the shop's documents as the evaluation set sees them: front matter, and the text under each heading."""
import glob
import os
import re


def load(folder="data/docs"):
    """{doc id: (front matter, {heading: text})} for every document in the folder."""
    docs = {}
    for path in sorted(glob.glob(os.path.join(folder, "*.md"))):
        _, front, body = open(path).read().split("---\n", 2)
        meta = dict(line.split(": ", 1) for line in front.strip().splitlines())
        sections, current = {}, None
        for line in body.splitlines():
            m = re.match(r"#{2,}\s+(.*)", line)
            if m:
                current = m.group(1).strip()
                sections[current] = ""
            elif current:
                sections[current] += line + "\n"
        docs[meta["id"]] = (meta, sections)
    return docs
```

```
ana@lab:~/obs$ python buildset.py
{
 "set": "marginalia-help",
 "version": 2,
 "cases": 42,
 "sha256": "0d464ef783cd67f0007967f4879bf902519d4d75cfb18745629ec4dfb448b1d1",
 "parent": "5a8379ae9de31e3f559bb27fbb151e99c5be6639f07ce189e34437e2f3fd8798",
 "splits": {
  "dev": 28,
  "held-out": 14
 },
 "documents": {
  "affiliate-api": "2.3",
  "ebooks-and-audiobooks": "5",
  "gift-cards": "2",
  "payments-and-invoices": "7",
  "privacy-notice": "6",
  "returns-policy": "4",
  "seller-agreement": "3",
  "shipping-and-delivery": "6",
  "support-handbook": "12",
  "terms-of-sale": "9"
 }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two versions of the evaluation set. Version 1 holds 30 cases written from the documents, sha256 5a8379ae. Twelve cases from the week's doubted questions are added. Version 2 holds 42 cases, 28 for development and 14 held out, sha256 0d464ef7, with version 1's hash as its parent and the version of every document it was checked against.\"><rect x=\"20\" y=\"40\" width=\"200\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">version 1</text><text x=\"36\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">30 cases</text><text x=\"36\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written from the documents</text><text x=\"36\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256 5a8379ae</text><rect x=\"260\" y=\"150\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">+ 12 cases</text><text x=\"276\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from the week's</text><text x=\"276\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">doubted questions</text><rect x=\"480\" y=\"40\" width=\"220\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"496\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">version 2</text><text x=\"496\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">42 cases: 28 dev, 14 held out</text><text x=\"496\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256 0d464ef7</text><text x=\"496\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parent 5a8379ae</text><text x=\"496\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">documents checked against</text><path d=\"M220 85 L472 85\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M466 80 L474 85 L466 90\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M440 185 L590 185 L590 158\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M585 164 L590 156 L595 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path></svg>", "caption": "A version is a fixed file and a hash. The parent hash makes the history a chain, and the document versions say when the set must be checked again."}
```

The manifest is short, and each field is there to answer a question that comes later:

- **`sha256`** is the hash of the set's exact bytes. A run that records it can be checked against the
  set it claims to have used, and a file edited by hand, by anybody, no longer matches.
- **`parent`** is the hash of version 1, so the history of the set is a chain that can be followed
  back, whatever the files are called.
- **`splits`** says how many cases each split holds, the subject of the last section.
- **`documents`** is the version of every document a gold section points into, from the documents' own
  front matter. The set was checked against those versions, and a change to any of them is a reason to
  check it again.

## The rules a version keeps

**An id is never reused and never renumbered.** The twelve new cases are e31 to e42, after the last
id in use. If e14 is ever retired, e14 stays retired, so that a result from version 2 that names e14
still means the question it meant then.

**A case is not edited in place.** If a case's meaning changes, because the shop changed the policy
behind it or the question was wrong, the old case is retired and a new one gets a new id. A wording
fixed without changing what is asked can keep its id; either way the set's version goes up, and the
hash moves with it.

**Every run records the set's version and hash** beside its results. Lesson 14 compares two runs and
refuses when the two were measured on different sets; lesson 15 fails a build when the set in the
repository is not the one its manifest pins.
