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
