---
title: The shop, its documents and the index
version: 1
---

The person at the keyboard in this course is ana, a developer at **Marginalia**, an online bookshop
that does not exist. The shop has a help assistant: customers type a question, and it answers from
the shop's own documents, citing them. In this course **it is in production**: customers type into
it, the support team uses it to summarise conversations, and nobody can say how well it is doing.
That last part is what the course is about.

`rag` built an assistant like this one, over a larger set of documents. This course builds a
smaller one of its own in this section and the next lessons, so that it needs nothing from another
course: seven short documents, an index, and the assistant itself in section 07. Everything lives
in `~/obs`.

## The documents

`make-obs.sh` writes the documents and one settings file into the directory you name. Save it as
`~/make-obs.sh`, in an editor or by pasting it between `cat > ~/make-obs.sh <<'SCRIPT'` and a line
with `SCRIPT` on its own:

```sh
# make-obs.sh: Marginalia's documents and the assistant's releases, in the directory named
set -euo pipefail
mkdir -p "$1/data/docs"
cd "$1"
cat > data/docs/returns-policy.md <<'DOC'
---
title: Returns and refunds
updated: 2026-03-02
status: current
audience: public
---

## The return window

You can return a printed book within 30 days from delivery, for any reason. The book has to come
back in the condition it left: no writing in it and no broken spine.

## How to start a return

Open the order in your account and choose "Return an item". Returns are free: we e-mail you a
prepaid label, and you drop the parcel at any post office.

## Refunds

We refund within three working days of the return arriving at our warehouse, to the card or
account you paid with. A gift card is refunded as a new gift card.

## Items that cannot be returned

Signed copies, books printed on demand, and e-books or audiobooks once they have been downloaded.

## The right of withdrawal

Under Brazil's Consumer Protection Code you may cancel any purchase made online within seven days
of delivery, with no reason given, and we refund the whole amount, delivery included.
DOC
cat > data/docs/returns-policy-2025.md <<'DOC'
---
title: Returns and refunds (2025)
updated: 2025-01-15
status: superseded
audience: public
---

## The return window

You can return a printed book within 14 days from delivery.

## How to start a return

Write to the support team with your order number. The return postage is paid by the customer.
DOC
cat > data/docs/shipping-and-delivery.md <<'DOC'
---
title: Shipping and delivery
updated: 2026-05-20
status: current
audience: public
---

## Standard delivery

Standard delivery takes three to six working days. It costs R$ 12.90, and it is free on orders
over R$ 40.

## Express delivery

Express delivery arrives on the next working day if you order before 2 pm. It costs R$ 29.90, and
it is not free at any order value.

## Lost parcels

A standard parcel is considered lost when its tracking has not changed for 10 working days. Tell
us, and we send a new copy or refund you, whichever you prefer.

## Pickup points

You can collect a parcel at one of our pickup points instead. It waits there for ten days, and
then it comes back to us and we refund you.
DOC
cat > data/docs/ebooks-and-audiobooks.md <<'DOC'
---
title: E-books and audiobooks
updated: 2026-02-11
status: current
audience: public
---

## Devices

An e-book you buy from us can be read on up to six devices at the same time, signed in to the
same account.

## Formats

Our e-books are EPUB files protected with Adobe DRM. They open in any reading app that supports
Adobe DRM; Kindle readers cannot open them.

## Audiobooks

Audiobooks play in our app, on a phone or in the browser, and you can download them to listen
offline.
DOC
cat > data/docs/gift-cards.md <<'DOC'
---
title: Gift cards
updated: 2026-01-08
status: current
audience: public
---

## Validity

A gift card is valid for two years from the day it was bought. It cannot be exchanged for cash.

## Using a gift card

Type the card's code at checkout. If the order costs more than the card holds, you pay the rest
with any other method; if it costs less, the balance stays on the card.
DOC
cat > data/docs/payments-and-invoices.md <<'DOC'
---
title: Payments and invoices
updated: 2026-04-30
status: current
audience: public
---

## How you can pay

We accept credit and debit cards, Pix and bank slips. A bank slip takes up to two working days to
clear, and the order ships after that.

## Instalments

On a credit card you can pay in up to three instalments with no interest, on orders over R$ 100.

## Invoices

Every order comes with an electronic invoice, sent to your e-mail address when the order ships.
DOC
cat > data/docs/finance-refund-controls.md <<'DOC'
---
title: Refund controls (finance team)
updated: 2026-06-03
status: current
audience: internal
---

## Approvals

A refund above R$ 500 needs the approval of two people from the finance team before it is paid.
A refund to a different card from the one used to pay is never made.
DOC
cat > releases.json <<'JSON'
{
  "2026.09.4": {"from": "2026-09-01T00:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.4},
  "2026.10.1": {"from": "2026-10-01T10:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.55}
}
JSON
```

Then run it:

```
ana@dev:~$ bash make-obs.sh ~/obs
ana@dev:~/obs$ ls -R
.:
data
releases.json

./data:
docs

./data/docs:
ebooks-and-audiobooks.md
finance-refund-controls.md
gift-cards.md
payments-and-invoices.md
returns-policy-2025.md
returns-policy.md
shipping-and-delivery.md
```

Each document starts with a few lines of **front matter**, between the two `---`: its title, when it
was last updated, whether it is still `current`, and who may read it. Five are public and current.
`returns-policy-2025.md` is last year's policy, `superseded`, and it says the opposite of this
year's about who pays for a return. `finance-refund-controls.md` is the finance team's, `internal`.
A customer must never be answered from either, and the assistant enforces that before the model
sees anything.

## Releases

`releases.json` is the assistant's settings, and every change to them is a **release** with the
moment it took effect. A release names the model, how many chunks to retrieve for a question
(`k`), and the similarity below which a retrieved chunk is not shown to the model at all
(`floor`). On 1 October somebody raised the floor from 0.4 to 0.55, and it is still the release in
force. Keep that in mind; lesson 5 finds out what it did.

## The index

The assistant finds the documents closest to a question by comparing numbers, not words. `index.py`
cuts every document into **chunks**, one for each `## ` section, asks `all-minilm` for each chunk's
384 numbers, and writes them all to `data/index.json`, with each chunk's front matter beside it:

```python
"""index.py: the shop's documents, cut into chunks and embedded, written to data/index.json.

    python index.py

A chunk is one `## ` section of a document, with the document's title in front of it.
Each keeps the document's front matter (when it was updated, whether it is current,
who may read it), because the assistant searches only what is current and public.
"""
import glob
import json
import os

from openai import OpenAI

EMBEDDER = "all-minilm"
client = OpenAI()


def chunks(path):
    head, body = open(path).read().split("---\n")[1:3]
    meta = dict(line.split(": ", 1) for line in head.strip().splitlines())
    doc = os.path.basename(path)[:-3]
    for part in body.split("\n## ")[1:]:
        heading, text = part.split("\n", 1)
        yield {"id": f"{doc}:{heading.lower().replace(' ', '-')}", "doc": doc,
               "text": f"{meta['title']}: {heading}\n{' '.join(text.split())}",
               "updated": meta["updated"], "status": meta["status"], "audience": meta["audience"]}


rows = [c for path in sorted(glob.glob("data/docs/*.md")) for c in chunks(path)]
vectors = client.embeddings.create(model=EMBEDDER, input=[r["text"] for r in rows]).data
for r, v in zip(rows, vectors):
    r["embedding"] = [round(x, 6) for x in v.embedding]
json.dump({"embedder": EMBEDDER, "chunks": rows}, open("data/index.json", "w"))
print(f"{len(rows)} chunks from {len({r['doc'] for r in rows})} documents, "
      f"{len(rows[0]['embedding'])} numbers each, in data/index.json")
```

```
ana@dev:~/obs$ python index.py
20 chunks from 7 documents, 384 numbers each, in data/index.json
```

Twenty chunks, one request. The assistant reads this file every time it starts; when a document
changes, run `index.py` again.

## Redaction, before anything is recorded

One more file, which the assistant imports and lesson 2 takes apart. `redact.py` replaces e-mail
addresses, telephone numbers, card numbers and order numbers with a word in brackets before a text
is written anywhere, and turns a user id into a keyed hash with the `PSEUDONYM_KEY` you set in the
previous section:

```python
"""redact.py: what is taken out of a text before it is recorded, and how a person is named instead.

    redact("write to joana.prado@example.com")  -> "write to [email]"
    pseudonym("u021")                            -> 16 hex characters, the same every time
"""
import hashlib
import hmac
import os
import re

PATTERNS = [
    ("email", re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")),
    ("phone", re.compile(r"\+\d{1,3}(?:[\s-]?\d){8,12}")),
    ("card", re.compile(r"\b(?:\d[ -]?){13,19}\b")),
    ("order", re.compile(r"\bMG-\d{8}\b")),
]


def redact(text):
    """TEXT with every match of PATTERNS replaced by its name in brackets."""
    for name, pattern in PATTERNS:
        text = pattern.sub(f"[{name}]", text)
    return text


def found(text):
    """{name: count} of what redact() would take out of TEXT."""
    return {name: len(p.findall(text)) for name, p in PATTERNS if p.search(text)}


KEY = os.environ.get("PSEUDONYM_KEY", "").encode()


def pseudonym(user):
    """A keyed hash of USER: the same person gets the same value, and without the key nobody can
    go from the value back to the person by trying every user id."""
    if not KEY:
        raise RuntimeError("PSEUDONYM_KEY is not set: refusing to record a user id unkeyed")
    return hmac.new(KEY, user.encode(), hashlib.sha256).hexdigest()[:16]
```

With these files, `~/obs` is ready for section 06.
