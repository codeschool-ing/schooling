#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the machine, the SDKs, labllm
#   sudo bash captures.sh
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown in the
# lesson: the lab itself (lab.sh reset), and the files ana wrote (put below),
# whose contents the lesson shows in full.
#
# THE ANSWERS IN THIS LESSON WERE WRITTEN BY THE COURSE. They come from
# labllm's scripted-1, whose replies are in lab/scripted.json. The
# chunking, the embeddings (WordLlama), the searches, the prompt and the
# citation checker are real. The shop's handbook they search was written for
# the course, like the rest of the shop, and is put below.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@dev:~/shop$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
lab reset >/dev/null
put docs/handbook/returns.md <<'MD'
# Returns and refunds

A customer may return any item within 30 days of delivery, for any reason. The
item must be unused and in its original packaging. Mugs and glasses must also
be unbroken; a breakage in transit is a damaged delivery, not a return.

To start a return, the customer opens the order in their account and chooses
"Return an item". The shop emails a prepaid label within one working day.

The refund goes back to the original payment method once the item arrives at
the warehouse and is checked, which takes up to five working days. Shipping
costs are refunded only when the whole order is returned.

After 30 days the shop does not accept returns, but a faulty item is covered
by the warranty described in warranty.md.
MD
put docs/handbook/shipping.md <<'MD'
# Shipping

Orders ship within two working days from the warehouse in Campinas. Delivery
inside Brazil takes three to eight working days depending on the region.

Shipping costs a flat 15.00 per order. It is free when the order total after
any coupon is 200.00 or more; the threshold is checked after the discount, so a
coupon can bring an order back under it.

The shop ships only to addresses in Brazil. It does not ship abroad and does
not deliver to post office boxes.

A customer can follow the parcel with the tracking code in the shipping email.
A parcel with no tracking update for ten working days is reported as lost.
MD
put docs/handbook/coupons.md <<'MD'
# Coupons

Two coupons are active. WELCOME10 takes 10% off and has no end date.
FRIENDS15 takes 15% off and is valid until 31 October 2026, inclusive.

Only one coupon applies per order; entering a second one replaces the first.
Codes may be typed in any case. A coupon cannot be applied after the order is
placed, and it is never exchanged for cash.

The discount is taken from the items, not from shipping, and is rounded down
to a whole cent.
MD
put docs/handbook/payment-errors.md <<'MD'
# Payment errors at checkout

The checkout shows a code when a payment fails. Read the code before anything
else; most failures are on the card issuer's side.

E1001: the card was declined by the issuer. Ask the customer to contact their
bank or use another card. The shop cannot see the reason.

E1042: the payment timed out between the shop and the payment service. No
money was taken. The customer can simply try again after a minute; if it
happens three times in a row, escalate to the on-call developer.

E2003: the billing address does not match the card. The customer should check
the postcode, which is the usual mistake.
MD
put docs/handbook/warranty.md <<'MD'
# Warranty

Every item has a 90-day warranty against manufacturing faults, counted from
delivery. A fault is something that stops the item working as described: a
lamp that does not light, a handle that comes off a mug in normal use.

Damage from a fall, from a dishwasher on a product marked hand-wash only, or
from ordinary wear is not covered.

Under warranty the shop replaces the item, or refunds it if it is out of
stock. The customer sends a photo of the fault from their account; there is
no need to send the item back unless the shop asks for it.
MD
put docs/handbook/account.md <<'MD'
# Accounts and passwords

A customer can check out without an account, but needs one to follow orders,
start a return or use the warranty.

To reset a password, the customer chooses "Forgot password" on the sign-in
page and follows the link in the email, which is valid for one hour. Support
staff never ask for a password and cannot see one.

To close an account, the customer writes to support from the account's email
address. Orders from the last five years are kept for tax reasons; everything
else is deleted within 30 days.
MD
put docs/handbook/contact.md <<'MD'
# Contacting support

Support answers by email and chat from 9:00 to 18:00, Monday to Friday,
Brasília time, except public holidays. Messages that arrive outside those hours
are answered the next working day, in the order they arrived.

The target for a first reply is four working hours. Anything about a payment
taken twice, or a parcel reported as lost, goes to the front of the queue.
MD
put docs/handbook/products.md <<'MD'
# Products

The shop sells mugs, glasses, lamps and small furniture. Mugs and glasses are
ceramic or tempered glass; all mugs are dishwasher-safe except the hand-painted
line, which is marked hand-wash only on the box and on the product page.

Lamps take a standard E27 bulb, not included. Furniture arrives flat-packed,
with tools, and the instructions are also on the product page.

Prices on the site include taxes. A price shown in an email or an advert is
valid only if it is also the price on the product page at checkout.
MD
put lab/rag.py <<'PY'
"""Retrieval over the shop's handbook: chunk, embed, search, and check citations."""
import json
import logging
import math
import re
from collections import Counter
from pathlib import Path

import numpy as np
import tiktoken
from wordllama import WordLlama

ENC = tiktoken.get_encoding("o200k_base")
INDEX = Path(".rag")
logging.getLogger().setLevel(logging.WARNING)  # importing wordllama turns INFO logging on


def chunks(folder="docs/handbook"):
    """One chunk per paragraph, carrying its document's title, with an id that says where it is."""
    out = []
    for path in sorted(Path(folder).glob("*.md")):
        title, *paragraphs = path.read_text().split("\n\n")
        for n, p in enumerate(paragraphs, 1):
            out.append({"id": f"{path.name}#{n}", "text": title.lstrip("# ") + ". " + " ".join(p.split())})
    return out


def build():
    cs = chunks()
    vectors = WordLlama.load().embed([c["text"] for c in cs], norm=True)
    INDEX.mkdir(exist_ok=True)
    np.save(INDEX / "vectors.npy", vectors)
    (INDEX / "chunks.json").write_text(json.dumps(cs, indent=1))
    return cs, vectors


def load():
    return json.loads((INDEX / "chunks.json").read_text()), np.load(INDEX / "vectors.npy")


def vector_search(query, k=3):
    cs, vectors = load()
    scores = vectors @ WordLlama.load().embed([query], norm=True)[0]
    return [(cs[i], float(scores[i])) for i in np.argsort(-scores)[:k]]


def words(text):
    return re.findall(r"\w+", text.lower())


def keyword_search(query, k=3):
    """BM25: a word counts more when it is rare in the handbook and frequent in the chunk."""
    cs, _ = load()
    docs = [words(c["text"]) for c in cs]
    avg = sum(map(len, docs)) / len(docs)
    df = Counter(w for d in docs for w in set(d))
    scores = []
    for d in docs:
        tf = Counter(d)
        s = 0.0
        for w in set(words(query)):
            if w in tf:
                idf = math.log(1 + (len(docs) - df[w] + 0.5) / (df[w] + 0.5))
                s += idf * tf[w] * 2.2 / (tf[w] + 1.2 * (0.25 + 0.75 * len(d) / avg))
        scores.append(s)
    order = sorted(range(len(cs)), key=lambda i: -scores[i])[:k]
    return [(cs[i], scores[i]) for i in order]


def hybrid_search(query, k=3):
    """Reciprocal rank fusion: each list votes 1/(60 + rank) for each chunk it found."""
    votes = Counter()
    by_id = {}
    for found in (vector_search(query, 10), keyword_search(query, 10)):
        for rank, (c, _) in enumerate(found):
            votes[c["id"]] += 1 / (60 + rank)
            by_id[c["id"]] = c
    return [(by_id[i], v) for i, v in votes.most_common(k)]


def prompt(question, found):
    passages = "\n".join(f"[{c['id']}] {c['text']}" for c, _ in found)
    return ("Answer only from the passages below. Cite the passage id in square brackets after "
            "every sentence that uses it. If the passages do not contain the answer, say so.\n\n"
            f"{passages}\n\nQuestion: {question}")


def check_citations(answer, found):
    """Every cited id must be one that was retrieved, and every quoted phrase must be in it."""
    given = {c["id"]: c["text"] for c, _ in found}
    problems = []
    for cid in re.findall(r"\[([\w.-]+#\d+)\]", answer):
        if cid not in given:
            problems.append(f"cites {cid}, which was not among the passages")
    for sentence in re.split(r"(?<=\.)\s+", answer):
        cited = re.findall(r"\[([\w.-]+#\d+)\]", sentence)
        for quote in re.findall(r'"([^"]+)"', sentence):
            if cited and not any(quote.lower() in given.get(c, "").lower() for c in cited):
                problems.append(f'quotes "{quote}", which {", ".join(cited)} does not say')
    return problems
PY
put lab/search.py <<'PY'
import sys

from rag import hybrid_search, keyword_search, vector_search

mode, query = sys.argv[1], sys.argv[2]
search = {"vector": vector_search, "keyword": keyword_search, "hybrid": hybrid_search}[mode]
print(f"{mode}: {query}")
for c, score in search(query):
    print(f"  {score:7.3f}  {c['id']:<20} {c['text'][:62]}…")
PY
put lab/ask.py <<'PY'
import sys

import anthropic

from rag import check_citations, hybrid_search, prompt

question = sys.argv[1]
found = hybrid_search(question)
r = anthropic.Anthropic().messages.create(model="scripted-1", max_tokens=400,
                                          messages=[{"role": "user", "content": prompt(question, found)}])
answer = r.content[0].text
print("retrieved:", ", ".join(c["id"] for c, _ in found))
print(answer)
problems = check_citations(answer, found)
print("citations:", "; ".join(problems) if problems else "every citation checks out")
PY

block why-retrieve
on 'git add docs && git commit -qm "Support handbook" && ls docs/handbook && wc -w docs/handbook/*.md | tail -1'
on "python -c 'import tiktoken, pathlib; print(sum(len(tiktoken.get_encoding(\"o200k_base\").encode(p.read_text())) for p in pathlib.Path(\"docs/handbook\").glob(\"*.md\")), \"tokens in the handbook\")'"

block chunking
on "PYTHONPATH=lab python -c 'import rag; cs = rag.chunks(); n = [len(rag.ENC.encode(c[\"text\"])) for c in cs]; print(len(cs), \"chunks, from\", min(n), \"to\", max(n), \"tokens\"); [print(c[\"id\"], \"|\", c[\"text\"][:70]) for c in cs[:4]]'"

block embedding
on "time PYTHONPATH=lab python -c 'import rag; cs, v = rag.build(); print(len(cs), \"chunks,\", v.shape, v.dtype)'"
on 'ls -la .rag'

block searching
on 'python lab/search.py vector "Can I send back a mug I bought last week?"'
on 'python lab/search.py vector "How long does delivery take to Recife?"'

block when-search-misses
on 'python lab/search.py vector "checkout says E1042"'
on 'python lab/search.py keyword "checkout says E1042"'
on 'python lab/search.py keyword "my parcel never arrived"'
on 'python lab/search.py vector "my parcel never arrived"'
on 'python lab/search.py hybrid "checkout says E1042"'
on 'python lab/search.py hybrid "my parcel never arrived"'

block the-prompt
on "PYTHONPATH=lab python -c 'import rag; q = \"Do you deliver to Portugal?\"; print(rag.prompt(q, rag.hybrid_search(q)))'"
on 'python lab/ask.py "Do you deliver to Portugal?"'
on 'python lab/ask.py "Do you sell bicycles?"'

block citations
on 'python lab/ask.py "My lamp stopped working after two months. What can I do?"'
on 'python lab/ask.py "Can I return a mug I bought 40 days ago?"'
on 'python lab/ask.py "Is the WELCOME10 coupon still valid in December?"'

block evaluating-retrieval
put lab/eval_retrieval.py <<'PY'
"""Recall at 3: for each question, is the passage that answers it among the three retrieved?"""
from rag import hybrid_search, keyword_search, vector_search

CASES = [
    ("Can I send back a mug I bought last week?", "returns.md#1"),
    ("How long does delivery take to Recife?", "shipping.md#1"),
    ("checkout says E1042", "payment-errors.md#3"),
    ("card declined with E1001", "payment-errors.md#2"),
    ("my parcel never arrived", "shipping.md#4"),
    ("Do you deliver to Portugal?", "shipping.md#3"),
    ("Is shipping free if my order is 210 with a coupon?", "shipping.md#2"),
    ("Is the WELCOME10 coupon still valid in December?", "coupons.md#1"),
    ("Can I use two coupons on one order?", "coupons.md#2"),
    ("how do I change my password", "account.md#2"),
    ("is the hand-painted mug ok in the dishwasher", "products.md#1"),
    ("when is support open", "contact.md#1"),
]
for name, search in [("vector", vector_search), ("keyword", keyword_search), ("hybrid", hybrid_search)]:
    missed = [q for q, want in CASES if want not in [c["id"] for c, _ in search(q)]]
    print(f"{name:8} recall@3 = {len(CASES) - len(missed)}/{len(CASES)}")
    for q in missed:
        print(f"           missed: {q}")
PY
on 'python lab/eval_retrieval.py'
