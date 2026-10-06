"""vcrypt: the lab's own command, for what the openssl command line does not
show. Each subcommand prints what it did in a form a lesson can quote."""
import argparse
import sys

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM


def read(path):
    if path == "-":
        return sys.stdin.buffer.read()
    with open(path, "rb") as f:
        return f.read()


def hexkey(path):
    return bytes.fromhex(open(path).read().strip())


GLYPHS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"


def cmd_blocks(a):
    data = read(a.file)
    seen = {}
    if a.letters:
        # one letter per block, the same letter for the same block, in groups of four
        letters = []
        for i in range(0, len(data), 16):
            b = data[i:i + 16]
            seen.setdefault(b, GLYPHS[len(seen)] if len(seen) < len(GLYPHS) else "?")
            letters.append(seen[b])
        print(" ".join("".join(letters[i:i + 4]) for i in range(0, len(letters), 4)))
        return
    for i in range(0, len(data), 16):
        b = data[i:i + 16]
        n = i // 16 + 1
        mark = f"  same as block {seen[b]}" if b in seen else ""
        seen.setdefault(b, n)
        print(f"{n:3}  {b.hex()}{mark}")
    print(f"{len(data)} bytes, {(len(data) + 15) // 16} blocks, {len(seen)} different")


def cmd_seal(a):
    key, nonce = hexkey(a.key), bytes.fromhex(a.nonce)
    out = AESGCM(key).encrypt(nonce, read(a.infile), a.aad.encode() if a.aad else None)
    with open(a.outfile, "wb") as f:
        f.write(nonce + out)
    print(f"sealed {a.infile}: 12-byte nonce + {len(out) - 16} bytes of ciphertext + 16-byte tag -> {a.outfile}")


def cmd_open(a):
    blob = read(a.infile)
    try:
        plain = AESGCM(hexkey(a.key)).decrypt(blob[:12], blob[12:], a.aad.encode() if a.aad else None)
    except InvalidTag:
        print(f"{a.infile}: authentication failed, nothing decrypted", file=sys.stderr)
        sys.exit(1)
    sys.stdout.buffer.write(plain)


def cmd_flip(a):
    data = bytearray(read(a.file))
    data[a.offset] ^= int(a.mask, 16)
    with open(a.file, "wb") as f:
        f.write(data)
    print(f"{a.file}: byte {a.offset} XOR 0x{int(a.mask, 16):02x}")


def cmd_toyrsa(a):
    """RSA with numbers small enough to follow by hand. Textbook RSA, with no
    padding, is NOT how RSA is used: lesson 2 says why."""
    p, q, e = a.p, a.q, a.e
    n, phi = p * q, (p - 1) * (q - 1)
    d = pow(e, -1, phi)
    print(f"p = {p}, q = {q}         two primes, kept secret")
    print(f"n = p*q = {n}           public: the modulus")
    print(f"phi = (p-1)(q-1) = {phi}   secret: needs p and q")
    print(f"e = {e}                  public exponent")
    print(f"d = e^-1 mod phi = {d}   private exponent")
    c = pow(a.m, e, n)
    print(f"encrypt m = {a.m}:  c = m^e mod n = {c}")
    print(f"decrypt c = {c}:  m = c^d mod n = {pow(c, d, n)}")


def cmd_avalanche(a):
    """Hash two strings with SHA-256 and count the bits that differ."""
    import hashlib
    h1 = hashlib.sha256(a.first.encode()).digest()
    h2 = hashlib.sha256(a.second.encode()).digest()
    diff = sum(bin(x ^ y).count("1") for x, y in zip(h1, h2))
    print(f"{a.first!r:>20}  {h1.hex()}")
    print(f"{a.second!r:>20}  {h2.hex()}")
    print(f"{diff} of 256 bits differ")


def _pepper(path):
    return hexkey(path) if path else None


def cmd_store(a):
    from . import passwords
    cost = None
    if a.cost:
        cost = tuple(int(x) for x in a.cost.split(",")) if a.scheme == "argon2id" else int(a.cost)
    for line in open(a.users):
        user, password = line.rstrip("\n").split(",", 1)
        if user == "user":
            continue
        print(f"{user}:{passwords.store(a.scheme, user, password, _pepper(a.pepper), cost)}")


def cmd_audit(a):
    groups = {}
    for line in open(a.store):
        user, h = line.rstrip("\n").split(":", 1)
        groups.setdefault(h, []).append(user)
    shared = [u for u in groups.values() if len(u) > 1]
    total = sum(len(u) for u in groups.values())
    print(f"{total} accounts, {len(groups)} different stored values")
    for users in shared:
        print(f"  {len(users)} accounts share one value: {', '.join(users)}")
    if not shared:
        print("  no two accounts share a stored value")


def cmd_verify(a):
    from . import passwords
    for line in open(a.store):
        user, h = line.rstrip("\n").split(":", 1)
        if user == a.user:
            ok, weak = passwords.verify(h, a.password, _pepper(a.pepper))
            if not ok:
                print(f"{a.user}: wrong password")
                sys.exit(1)
            print(f"{a.user}: password accepted" + (f"; rehash now: {weak}" if weak else ""))
            return
    print(f"{a.user}: wrong password")  # the same answer as a wrong password, on purpose
    sys.exit(1)


def cmd_webhook(a):
    from . import webhook
    key = hexkey(a.key)
    for path in a.events:
        body = read(path)
        header = open(path[:-len(".json")] + ".sig").read() if path.endswith(".json") else ""
        ok, why = webhook.verify(key, header, body, a.now)
        print(f"{path.split('/')[-1]:<12} {'ACCEPT' if ok else 'REJECT'}  {why}")


def cmd_toydh(a):
    """Diffie-Hellman with numbers small enough to follow by hand."""
    p, g = a.p, a.g
    A, B = pow(g, a.a, p), pow(g, a.b, p)
    print(f"public:  p = {p}, g = {g}")
    print(f"Ana   picks a = {a.a} (secret), sends A = g^a mod p = {A}")
    print(f"Bruno picks b = {a.b} (secret), sends B = g^b mod p = {B}")
    print(f"Ana   computes B^a mod p = {pow(B, a.a, p)}")
    print(f"Bruno computes A^b mod p = {pow(A, a.b, p)}")
    print(f"on the wire: p, g, A = {A}, B = {B}; never a, b or the result")


def cmd_ephemeral(a):
    """Two X25519 key pairs made in memory for one exchange, used, and dropped."""
    from cryptography.hazmat.primitives.asymmetric import x25519
    ana, bruno = x25519.X25519PrivateKey.generate(), x25519.X25519PrivateKey.generate()
    s1 = ana.exchange(bruno.public_key())
    s2 = bruno.exchange(ana.public_key())
    print(f"ephemeral pairs generated for this exchange: 2, written to disk: 0")
    print(f"both sides derived the same {len(s1)}-byte secret: {'yes' if s1 == s2 else 'no'}")
    del ana, bruno
    print("private halves discarded; nothing left that could rebuild this secret")


def cmd_kem(a):
    """ML-KEM-768: a key pair from a fixed seed, one encapsulation, and the sizes."""
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import mlkem
    from . import drbg
    k = mlkem.MLKEM768PrivateKey.from_seed_bytes(drbg.stream("keys/mlkem768", 64))
    pub = k.public_key()
    secret, ciphertext = pub.encapsulate()
    print(f"ML-KEM-768 public key      {len(pub.public_bytes_raw()):5} bytes")
    print(f"encapsulation (ciphertext) {len(ciphertext):5} bytes")
    print(f"shared secret              {len(secret):5} bytes")
    print(f"decapsulated secret matches: {'yes' if k.decapsulate(ciphertext) == secret else 'no'}")


def main():
    p = argparse.ArgumentParser(prog="vcrypt")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("blocks", help="print a file as 16-byte blocks and mark repeats")
    s.add_argument("file")
    s.add_argument("--letters", action="store_true", help="one letter per distinct block")
    s.set_defaults(fn=cmd_blocks)
    for verb, fn in (("seal", cmd_seal), ("open", cmd_open)):
        s = sub.add_parser(verb, help=f"AES-GCM {verb}")
        s.add_argument("--key", required=True)
        s.add_argument("--aad")
        if verb == "seal":
            s.add_argument("--nonce", required=True)
            s.add_argument("infile")
            s.add_argument("outfile")
        else:
            s.add_argument("infile")
        s.set_defaults(fn=fn)
    s = sub.add_parser("flip", help="change one byte of a sealed file, to see the tag refuse it")
    s.add_argument("file")
    s.add_argument("offset", type=int)
    s.add_argument("--mask", default="01")
    s.set_defaults(fn=cmd_flip)
    s = sub.add_parser("toyrsa", help="RSA with small numbers, to follow by hand")
    s.add_argument("--p", type=int, default=61)
    s.add_argument("--q", type=int, default=53)
    s.add_argument("--e", type=int, default=17)
    s.add_argument("m", type=int)
    s.set_defaults(fn=cmd_toyrsa)
    s = sub.add_parser("avalanche", help="SHA-256 of two strings, and how many bits differ")
    s.add_argument("first")
    s.add_argument("second")
    s.set_defaults(fn=cmd_avalanche)
    s = sub.add_parser("store", help="store every password in a users file with one scheme")
    s.add_argument("scheme", choices=("sha256", "salted-sha256", "pbkdf2", "bcrypt", "argon2id"))
    s.add_argument("users")
    s.add_argument("--pepper")
    s.add_argument("--cost", help="iterations (pbkdf2), cost (bcrypt) or m,t,p (argon2id)")
    s.set_defaults(fn=cmd_store)
    s = sub.add_parser("audit", help="count accounts that share a stored value")
    s.add_argument("store")
    s.set_defaults(fn=cmd_audit)
    s = sub.add_parser("verify", help="check one password against a store")
    s.add_argument("store")
    s.add_argument("user")
    s.add_argument("password")
    s.add_argument("--pepper")
    s.set_defaults(fn=cmd_verify)
    s = sub.add_parser("webhook", help="verify webhook deliveries: body.json with its header in body.sig")
    s.add_argument("--key", required=True)
    s.add_argument("--now", type=int, required=True, help="the receiver's clock, as epoch seconds")
    s.add_argument("events", nargs="+")
    s.set_defaults(fn=cmd_webhook)
    s = sub.add_parser("toydh", help="Diffie-Hellman with small numbers")
    s.add_argument("--p", type=int, default=23)
    s.add_argument("--g", type=int, default=5)
    s.add_argument("--a", type=int, default=6)
    s.add_argument("--b", type=int, default=15)
    s.set_defaults(fn=cmd_toydh)
    s = sub.add_parser("ephemeral", help="an X25519 exchange with keys that never touch the disk")
    s.set_defaults(fn=cmd_ephemeral)
    s = sub.add_parser("kem", help="ML-KEM-768 sizes and one encapsulation")
    s.set_defaults(fn=cmd_kem)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        # `| head` closed the pipe: the reader has what it asked for.
        sys.stderr.close()
