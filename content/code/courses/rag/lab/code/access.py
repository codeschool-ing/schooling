"""Who may read what: the audiences each role opens, decided by the system and never by the question."""
import psycopg
from minilm import embed
from pgvector.psycopg import register_vector

ROLES = {
    "customer":  ["public"],
    "seller":    ["public", "sellers"],
    "developer": ["public", "developers"],
    "agent":     ["public", "staff"],
    "finance":   ["public", "staff", "finance"],
}


def audiences(role):
    """The audiences a role may read. A role nobody wrote down reads nothing."""
    return ROLES.get(role, [])


def connect():
    """The assistant's own connection: a role that can only SELECT, and only what the policy lets through."""
    conn = psycopg.connect(user="assistant", autocommit=True)
    register_vector(conn)
    return conn


def search(conn, role, question, k=3, only=None):
    """Lesson 6's search with the role's audiences in the WHERE, inside a transaction that also tells
    the database whose search it is, so its policy applies the same limit a second time. ONLY, a
    narrowing the reader asked for, is intersected with what the role allows and can never add to it."""
    allowed = [a for a in audiences(role) if only is None or a in only]
    q = embed(question)[0]
    with conn.transaction():
        conn.execute("SELECT set_config('rag.audiences', %s, true)", (",".join(allowed),))
        return conn.execute(
            "SELECT id, path, text, audience, 1 - (embedding <=> %s) FROM chunks"
            " WHERE status = 'current' AND audience = ANY(%s)"
            " ORDER BY embedding <=> %s LIMIT %s", (q, allowed, q, k)).fetchall()
