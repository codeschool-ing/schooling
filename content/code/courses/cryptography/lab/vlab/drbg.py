"""Deterministic bytes for the lab, and NOTHING ELSE.

Every key in ~/lab is derived from a label through HMAC-SHA256 in counter
mode, so that `lab.sh reset` builds the same keys on every machine and the
transcripts in the lessons repeat byte for byte. That is the property a
course needs and exactly the property a real key must not have: anybody who
reads this file can rebuild every key in the lab. Lesson 17 says why a key
derived from something public is no key at all; this file is that mistake,
made on purpose, where it costs nothing.
"""
import hashlib
import hmac

SEED = b"cryptography course lab, not a secret"


def stream(label: str, n: int) -> bytes:
    out, counter = b"", 0
    while len(out) < n:
        out += hmac.new(SEED, label.encode() + counter.to_bytes(4, "big"), hashlib.sha256).digest()
        counter += 1
    return out[:n]


def integer(label: str, bits: int) -> int:
    return int.from_bytes(stream(label, (bits + 7) // 8), "big") >> ((-bits) % 8)
