"""Marginalia's data as plain functions: what the agents in this course are given to call.

Nothing here knows about models, tools or MCP. Each lesson wraps these
functions in whatever a model needs (a schema, a decorator, an MCP server),
and the functions stay the same underneath.
"""
import json
import os
import sqlite3
from datetime import date
from pathlib import Path

DATA = Path(__file__).resolve().parent / "data"
TODAY = date.fromisoformat(os.environ.get("LAB_TODAY", "2026-10-06"))


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
    """A book from the catalogue, with its price and stock where Marginalia sells it."""
    for line in open(DATA / "books.jsonl"):
        b = json.loads(line)
        if b["id"] == book_id:
            with _db() as db:
                p = db.execute("SELECT cents, stock FROM prices WHERE book_id = ?", (book_id,)).fetchone()
            b.update(dict(p) if p else {"cents": None, "stock": 0})
            return b
    raise LookupError(f"no book {book_id}")


_help = None


def search_help(query, k=3):
    """The k help-centre articles closest in meaning to QUERY, by cosine similarity."""
    global _help
    import numpy as np
    from minilm import embed
    if _help is None:
        arts = [json.loads(line) for line in open(DATA / "help.jsonl")]
        cache = DATA / "help.npy"
        if cache.exists():
            vecs = np.load(cache)
        else:
            vecs = embed([a["title"] + ". " + a["body"] for a in arts])
            np.save(cache, vecs)
        _help = (arts, vecs)
    arts, vecs = _help
    scores = vecs @ embed(query)[0]
    best = scores.argsort()[::-1][:k]
    return [{"id": arts[i]["id"], "title": arts[i]["title"], "body": arts[i]["body"],
             "score": round(float(scores[i]), 3)} for i in best]


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
