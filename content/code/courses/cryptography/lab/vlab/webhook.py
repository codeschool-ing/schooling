"""Webhooks signed the way most payment gateways sign them: an HMAC-SHA256
over "<timestamp>.<body>", sent in a header as t=<timestamp>,v1=<hex>.
Lesson 6 verifies them."""
import hashlib
import hmac

TOLERANCE = 300  # seconds a delivery may be late before it is treated as a replay


def sign(key: bytes, timestamp: int, body: bytes) -> str:
    tag = hmac.new(key, str(timestamp).encode() + b"." + body, hashlib.sha256).hexdigest()
    return f"t={timestamp},v1={tag}"


def verify(key: bytes, header: str, body: bytes, now: int):
    """Returns (accepted, reason)."""
    try:
        fields = dict(part.split("=", 1) for part in header.strip().split(","))
        timestamp, received = int(fields["t"]), fields["v1"]
    except (ValueError, KeyError):
        return False, "no signature header in the expected form"
    expected = hmac.new(key, str(timestamp).encode() + b"." + body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, received):
        return False, "signature does not match the body"
    if abs(now - timestamp) > TOLERANCE:
        return False, f"signed {now - timestamp} s ago, outside the {TOLERANCE} s window"
    return True, "signature valid, timestamp within the window"
