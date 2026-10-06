"""A customer's memory: every turn kept in a table, recalled by similarity, never across accounts,
and a state the program writes from what it knows for certain."""
import re

from minilm import embed
from search import conn

SCHEMA = """
CREATE TABLE IF NOT EXISTS memories (
    id           bigserial PRIMARY KEY,
    account      text NOT NULL,
    conversation text NOT NULL,
    turn         int NOT NULL,
    text         text NOT NULL,
    embedding    vector(384) NOT NULL,
    created      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS memories_account ON memories (account);
"""
ORDER = re.compile(r"\bMG-\d{8}\b")
conn.execute(SCHEMA)


def remember(account, conversation, turn, text):
    conn.execute("INSERT INTO memories (account, conversation, turn, text, embedding) VALUES (%s, %s, %s, %s, %s)",
                 (account, conversation, turn, text, embed(text)[0]))


def recall(account, question, k=2, before=None):
    """The K earlier turns of THIS account most similar to the question, oldest first."""
    q = embed(question)[0]
    found = conn.execute(
        "SELECT turn, text, 1 - (embedding <=> %s) FROM memories WHERE account = %s AND turn < %s"
        " ORDER BY embedding <=> %s LIMIT %s", (q, account, before or 2**31 - 1, q, k)).fetchall()
    return sorted(found)


def state(account, name):
    """What the program knows for certain, written as sentences a reply to the customer can quote."""
    said = " ".join(t for (t,) in conn.execute("SELECT text FROM memories WHERE account = %s ORDER BY turn",
                                               (account,)))
    orders = list(dict.fromkeys(ORDER.findall(said)))
    lines = [f"You are {name}."]
    if orders:
        lines.append(f"Your order number is {' and '.join(orders)}.")
    return " ".join(lines)


def forget(account):
    return conn.execute("DELETE FROM memories WHERE account = %s", (account,)).rowcount
