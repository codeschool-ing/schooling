"""The lab's keys, rebuilt from labels (see drbg.py for why that is only
acceptable in a lab)."""
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec, ed25519, rsa, x25519

from . import drbg

SMALL_PRIMES = [p for p in range(3, 2000) if all(p % d for d in range(2, int(p ** 0.5) + 1))]


def _probable_prime(n: int, label: str) -> bool:
    if n < 2:
        return False
    for p in SMALL_PRIMES:
        if n % p == 0:
            return n == p
    d, s = n - 1, 0
    while d % 2 == 0:
        d, s = d // 2, s + 1
    for i in range(40):
        a = 2 + drbg.integer(f"{label}/witness/{i}", n.bit_length()) % (n - 3)
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False
    return True


def _prime(label: str, bits: int, e: int = 65537) -> int:
    i = 0
    while True:
        c = drbg.integer(f"{label}/{i}", bits) | (3 << (bits - 2)) | 1
        if (c - 1) % e and _probable_prime(c, f"{label}/{i}"):
            return c
        i += 1


def rsa_key(label: str, bits: int) -> rsa.RSAPrivateKey:
    e = 65537
    p = _prime(label + "/p", bits // 2)
    q = _prime(label + "/q", bits // 2)
    if p < q:
        p, q = q, p
    n = p * q
    d = pow(e, -1, (p - 1) * (q - 1))
    numbers = rsa.RSAPrivateNumbers(
        p=p, q=q, d=d, dmp1=d % (p - 1), dmq1=d % (q - 1), iqmp=pow(q, -1, p),
        public_numbers=rsa.RSAPublicNumbers(e, n))
    return numbers.private_key()


P256_ORDER = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551


def ec_key(label: str) -> ec.EllipticCurvePrivateKey:
    return ec.derive_private_key(1 + drbg.integer(label, 256) % (P256_ORDER - 1), ec.SECP256R1())


def ed25519_key(label: str) -> ed25519.Ed25519PrivateKey:
    return ed25519.Ed25519PrivateKey.from_private_bytes(drbg.stream(label, 32))


def x25519_key(label: str) -> x25519.X25519PrivateKey:
    return x25519.X25519PrivateKey.from_private_bytes(drbg.stream(label, 32))


def write_private(key, path):
    with open(path, "wb") as f:
        f.write(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                  serialization.NoEncryption()))


def write_public(key, path):
    with open(path, "wb") as f:
        f.write(key.public_key().public_bytes(serialization.Encoding.PEM,
                                              serialization.PublicFormat.SubjectPublicKeyInfo))
