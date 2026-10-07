"""Password storage, five ways, for lesson 5. Every salt here is derived from
a label (see drbg.py) so that the stores come out the same on every machine;
a real system draws each salt from os.urandom at the moment it stores the
password."""
import base64
import hashlib
import hmac

import bcrypt
from cryptography.hazmat.primitives.kdf.argon2 import Argon2id

from . import drbg

SCHEMES = ("sha256", "salted-sha256", "pbkdf2", "bcrypt", "argon2id")
POLICY = {"pbkdf2": 600_000, "bcrypt": 12, "argon2id": (19456, 2, 1)}
B64 = lambda b: base64.b64encode(b).decode().rstrip("=")
BCRYPT_ALPHABET = "./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"


def _salt(scheme, user, n=16):
    return drbg.stream(f"salt/{scheme}/{user}", n)


def _peppered(password, pepper):
    if pepper is None:
        return password.encode()
    return hmac.new(pepper, password.encode(), hashlib.sha256).hexdigest().encode()


def store(scheme, user, password, pepper=None, cost=None):
    pw = _peppered(password, pepper)
    if scheme == "sha256":
        return hashlib.sha256(pw).hexdigest()
    if scheme == "salted-sha256":
        s = _salt(scheme, user)
        return f"sha256${B64(s)}${hashlib.sha256(s + pw).hexdigest()}"
    if scheme == "pbkdf2":
        n = cost or POLICY["pbkdf2"]
        s = _salt(scheme, user)
        return f"pbkdf2-sha256${n}${B64(s)}${B64(hashlib.pbkdf2_hmac('sha256', pw, s, n))}"
    if scheme == "bcrypt":
        c = cost or POLICY["bcrypt"]
        raw = drbg.stream(f"salt/bcrypt/{user}", 22)
        s = "".join(BCRYPT_ALPHABET[x % 64] for x in raw[:21]) + "u"
        return bcrypt.hashpw(pw, f"$2b${c:02d}${s}".encode()).decode()
    if scheme == "argon2id":
        m, t, p = cost or POLICY["argon2id"]
        return Argon2id(salt=_salt(scheme, user), length=32, iterations=t, lanes=p,
                        memory_cost=m).derive_phc_encoded(pw)
    raise ValueError(scheme)


def verify(stored, password, pepper=None):
    """Returns (ok, why-a-rehash-is-needed or None)."""
    pw = _peppered(password, pepper)
    if stored.startswith("$argon2id$"):
        try:
            Argon2id.verify_phc_encoded(pw, stored)
            ok = True
        except Exception:
            ok = False
        params = dict(kv.split("=") for kv in stored.split("$")[3].split(","))
        m, t, p = POLICY["argon2id"]
        weak = int(params["m"]) < m or int(params["t"]) < t
        return ok, (f"stored m={params['m']},t={params['t']} is below the policy m={m},t={t}" if weak else None)
    if stored.startswith("$2b$"):
        ok = bcrypt.checkpw(pw, stored.encode())
        c = int(stored.split("$")[2])
        return ok, (f"stored cost {c} is below the policy {POLICY['bcrypt']}" if c < POLICY["bcrypt"] else None)
    if stored.startswith("pbkdf2-sha256$"):
        _, n, s, h = stored.split("$")
        s = base64.b64decode(s + "=" * (-len(s) % 4))
        calc = B64(hashlib.pbkdf2_hmac("sha256", pw, s, int(n)))
        ok = hmac.compare_digest(calc, h)
        return ok, (f"stored {n} iterations is below the policy {POLICY['pbkdf2']}" if int(n) < POLICY["pbkdf2"] else None)
    if stored.startswith("sha256$"):
        _, s, h = stored.split("$")
        s = base64.b64decode(s + "=" * (-len(s) % 4))
        return hmac.compare_digest(hashlib.sha256(s + pw).hexdigest(), h), "a fast hash is below every policy"
    return hmac.compare_digest(hashlib.sha256(pw).hexdigest(), stored), "a fast hash is below every policy"
