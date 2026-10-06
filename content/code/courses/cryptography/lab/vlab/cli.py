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
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        # `| head` closed the pipe: the reader has what it asked for.
        sys.stderr.close()
