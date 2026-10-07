"""shop.py: Marginalia's data as plain functions, which every lesson wraps as tools.

Nothing here knows about models, tools or MCP. The help-centre search asks
Ollama for embeddings from all-minilm, the model embeddings-vectors uses.
"""
import json
import math
import sqlite3
import urllib.request
from datetime import date
from pathlib import Path

DATA = Path(__file__).resolve().parent / "data"
TODAY = date(2026, 10, 6)   # the shop's calendar stops here, so every date in the lessons holds


def _db(readonly=True):
    mode = "ro" if readonly else "rw"
    db = sqlite3.connect(f"file:{DATA / 'shop.db'}?mode={mode}", uri=True)
    db.row_factory = sqlite3.Row
    return db


def get_order(order_id):
    """The order, its lines and its refunds, as a dict. Amounts are in cents."""
    with _db() as db:
        o = db.execute("SELECT * FROM orders WHERE id = ?", (order_id,)).fetchone()
        if o is None:
            raise LookupError(f"no order {order_id}")
        lines = db.execute("SELECT book_id, quantity, cents FROM order_lines WHERE order_id = ?",
                           (order_id,)).fetchall()
        refunded = db.execute("SELECT coalesce(sum(cents), 0) FROM refunds WHERE order_id = ?",
                              (order_id,)).fetchone()[0]
    out = dict(o)
    out["lines"] = [dict(r) for r in lines]
    out["total"] = sum(r["quantity"] * r["cents"] for r in lines) + o["shipping"]
    out["refunded"] = refunded
    return out


def get_customer(customer_id):
    with _db() as db:
        c = db.execute("SELECT * FROM customers WHERE id = ?", (customer_id,)).fetchone()
    if c is None:
        raise LookupError(f"no customer {customer_id}")
    return dict(c)


def get_book(book_id):
    """A book from the catalogue, with its price and stock."""
    for line in open(DATA / "books.jsonl"):
        b = json.loads(line)
        if b["id"] == book_id:
            with _db() as db:
                p = db.execute("SELECT cents, stock FROM prices WHERE book_id = ?", (book_id,)).fetchone()
            b.update(dict(p))
            return b
    raise LookupError(f"no book {book_id}")


def _embed(texts):
    req = urllib.request.Request("http://127.0.0.1:11434/api/embed",
                                 json.dumps({"model": "all-minilm", "input": texts}).encode(),
                                 {"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.load(r)["embeddings"]   # each one already has length 1


def search_help(query, k=3):
    """The k help-centre articles closest in meaning to QUERY, by cosine similarity."""
    arts = [json.loads(line) for line in open(DATA / "help.jsonl")]
    cache = DATA / "help.vectors.json"
    if not cache.exists():
        cache.write_text(json.dumps(_embed([a["title"] + ". " + a["body"] for a in arts])))
    vecs = json.loads(cache.read_text())
    q = _embed([query])[0]
    scores = [math.sumprod(v, q) for v in vecs]
    best = sorted(range(len(arts)), key=lambda i: -scores[i])[:k]
    return [{"id": arts[i]["id"], "title": arts[i]["title"], "body": arts[i]["body"],
             "score": round(scores[i], 3)} for i in best]


def refund(order_id, cents, reason, approved_by):
    """Record a refund. It refuses more than is left to refund on the order."""
    order = get_order(order_id)
    left = order["total"] - order["refunded"]
    if cents <= 0 or cents > left:
        raise ValueError(f"cannot refund {cents} cents on {order_id}: {left} left to refund")
    with _db(readonly=False) as db:
        db.execute("INSERT INTO refunds (order_id, cents, reason, approved_by, at) VALUES (?, ?, ?, ?, ?)",
                   (order_id, cents, reason, approved_by, TODAY.isoformat()))
    return {"order_id": order_id, "refunded": cents, "left": left - cents}
