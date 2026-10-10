---
title: A version, and what pins it
version: 2
---

A set that changes under a comparison makes the comparison meaningless: a release that scores better
on thirty-two cases than its predecessor did on twenty-four has not been compared with anything. So
a set is **released in versions**, like code, and every result names the version it was measured on.

`buildset.py` makes version 2: the twenty-four cases of version 1, the eight additions, the split each
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
for c in cases:   # every third question is held out, decided by its id and nothing else
    c["split"] = "held-out" if int(c["id"][1:]) % 3 == 0 else "dev"
body = "".join(json.dumps(c, ensure_ascii=False) + "\n" for c in cases).encode()
open("data/eval-v2.jsonl", "wb").write(body)
shop = docs.load()
manifest = {"set": "marginalia-help", "version": 2, "cases": len(cases),
            "sha256": hashlib.sha256(body).hexdigest(), "parent": hashlib.sha256(v1).hexdigest(),
            "splits": {s: sum(c["split"] == s for c in cases) for s in ("dev", "held-out")},
            "documents": {d: shop[d][0]["updated"] for d in sorted({g.split(":")[0] for c in cases for g in c["gold"]})}}
json.dump(manifest, open("data/eval-v2.manifest.json", "w"), indent=1)
print(json.dumps(manifest, indent=1))
```

`docs.py`, which the build and the check share, reads each document's front matter and each of its
chunks, by the same id and with the same text `index.py` gives them. The first version of it left the
heading out of the text, and the check in the next section failed two of version 1's own cases on its
first run: "cannot be returned" is in the heading *Items that cannot be returned* and nowhere under it.
The assistant searches the heading too, so the set has to read it as well:

```python
"""docs.py: the shop's documents as the evaluation set sees them: front matter, and each chunk's text by id.

The ids and the text are the ones index.py gives: the document's name, a colon, and the heading in
lower case with dashes for spaces; and the heading kept with the text under it, because the assistant
searches both.
"""
import glob
import os


def load(folder="data/docs"):
    """{document: (front matter, {chunk id: text})} for every document in the folder."""
    docs = {}
    for path in sorted(glob.glob(os.path.join(folder, "*.md"))):
        head, body = open(path).read().split("---\n")[1:3]
        meta = dict(line.split(": ", 1) for line in head.strip().splitlines())
        doc = os.path.basename(path)[:-3]
        chunks = {}
        for part in body.split("\n## ")[1:]:
            heading, text = part.split("\n", 1)
            chunks[f"{doc}:{heading.lower().replace(' ', '-')}"] = f"{heading}\n{' '.join(text.split())}"
        docs[doc] = (meta, chunks)
    return docs
```

```
ana@dev:~/obs$ python buildset.py
{
 "set": "marginalia-help",
 "version": 2,
 "cases": 32,
 "sha256": "8763ed310b27473ff257e62183f344e732ebe41378cc25d3230976bc54810796",
 "parent": "00f7e3c48ddcc47924ba61629ff42baf8a1b90cdd405c4cd8088403e1b0b44dc",
 "splits": {
  "dev": 22,
  "held-out": 10
 },
 "documents": {
  "ebooks-and-audiobooks": "2026-02-11",
  "gift-cards": "2026-01-08",
  "payments-and-invoices": "2026-04-30",
  "returns-policy": "2026-03-02",
  "shipping-and-delivery": "2026-05-20"
 }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two versions of the evaluation set. Version 1 holds 24 cases written from the documents, sha256 00f7e3c4. Eight cases from the week's doubted questions are added. Version 2 holds 32 cases, 22 for development and 10 held out, sha256 8763ed31, with version 1's hash as its parent and the date of every document it was checked against.\"><rect x=\"20\" y=\"40\" width=\"200\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">version 1</text><text x=\"36\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">24 cases</text><text x=\"36\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written from the documents</text><text x=\"36\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256 00f7e3c4</text><rect x=\"260\" y=\"150\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">+ 8 cases</text><text x=\"276\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from the week's</text><text x=\"276\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">doubted questions</text><rect x=\"480\" y=\"40\" width=\"220\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"496\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">version 2</text><text x=\"496\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">32 cases: 22 dev, 10 held out</text><text x=\"496\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256 8763ed31</text><text x=\"496\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parent 00f7e3c4</text><text x=\"496\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">documents checked against</text><path d=\"M220 85 L472 85\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M466 80 L474 85 L466 90\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M440 185 L590 185 L590 158\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M585 164 L590 156 L595 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path></svg>", "caption": "A version is a fixed file and a hash. The parent hash makes the history a chain, and the document dates say when the set must be checked again."}
```

The manifest is short, and each field is there to answer a question that comes later:

- **`sha256`** is the hash of the set's exact bytes. A run that records it can be checked against the
  set it claims to have used, and a file edited by hand, by anybody, no longer matches.
- **`parent`** is the hash of version 1, so the history of the set is a chain that can be followed
  back, whatever the files are called.
- **`splits`** says how many cases each split holds, the subject of the last section.
- **`documents`** is the date every document a gold chunk points into was last updated, from the
  documents' own front matter. The set was checked against those, and a change to any of them is a
  reason to check it again.

## The rules a version keeps

**An id is never reused and never renumbered.** The eight new cases are e25 to e32, after the last
id in use. If e14 is ever retired, e14 stays retired, so that a result from version 2 that names e14
still means the question it meant then.

**A case is not edited in place.** If a case's meaning changes, because the shop changed the policy
behind it or the question was wrong, the old case is retired and a new one gets a new id. A wording
fixed without changing what is asked can keep its id; either way the set's version goes up, and the
hash moves with it.

**Every run records the set's version and hash** beside its results. Lesson 14 compares two runs and
refuses when the two were measured on different sets; lesson 15 fails a build when the set in the
repository is not the one its manifest pins.
