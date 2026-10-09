---
title: Encryption that notices a change
version: 1
---

**Encrypting data hides it; it does not protect it from being changed.** CBC and CTR will decrypt
any sequence of bytes they are given, including one that somebody altered in transit or on disk,
and they hand back the result without a word. The modes that refuse are called **authenticated
encryption**, and GCM is the one this section uses.

## What the plain modes cannot tell you

Section 04 already showed the symptom from the other side: a cipher turns any input into some
output, and the `bad decrypt` you saw was the padding failing to fit, not the cipher detecting
anything. In CTR, which has no padding, there is not even that. A byte changed in a CTR ciphertext
changes the same byte of the plaintext and nothing else, and decryption succeeds. In CBC a change
garbles one block and alters the next one, and decryption usually succeeds as well.

So a program that decrypts with a plain mode and then trusts what it read is trusting the
storage and the network not to have changed anything. **Confidentiality and integrity are two
properties, and the plain modes give only the first.** Before authenticated modes were common,
the fix was to add a separate check over the ciphertext, a MAC, which lesson 6 builds. Getting the
order of the two wrong was a long-running source of bugs, which is why the combined modes won.

## GCM: a mode with a tag

GCM, *Galois/Counter Mode*, is CTR for the encryption plus a **tag**, sixteen bytes computed over
the whole ciphertext with the same key. Decryption recomputes the tag first and refuses to return
anything if it differs. Python's `cryptography` library has it as `AESGCM`, and two short tools
put it on the command line. `vcrypt seal` encrypts a file and writes the nonce in front of the
result, so that the file carries what decryption needs:

```py
# ~/lab/tools/seal.py
"""vcrypt seal --key KEYFILE --nonce HEX [--aad TEXT] IN OUT: encrypt IN with
AES-256-GCM and write OUT as nonce + ciphertext + tag. IN may be -."""
import argparse
import sys

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

p = argparse.ArgumentParser(prog="vcrypt seal")
p.add_argument("--key", required=True, help="a file holding the key in hex")
p.add_argument("--nonce", required=True, help="12 bytes in hex, never used twice with one key")
p.add_argument("--aad", help="associated data: checked by the tag, not encrypted, not stored")
p.add_argument("infile")
p.add_argument("outfile")
a = p.parse_args()

key = bytes.fromhex(open(a.key).read().strip())
nonce = bytes.fromhex(a.nonce)
data = sys.stdin.buffer.read() if a.infile == "-" else open(a.infile, "rb").read()
out = AESGCM(key).encrypt(nonce, data, a.aad.encode() if a.aad else None)
with open(a.outfile, "wb") as f:
    f.write(nonce + out)
print(f"sealed {a.infile}: 12-byte nonce + {len(out) - 16} bytes of ciphertext + 16-byte tag -> {a.outfile}")
```

`vcrypt open` reads the nonce back, and either gets the plaintext or an exception, never both:

```py
# ~/lab/tools/open.py
"""vcrypt open --key KEYFILE [--aad TEXT] IN: check the tag of a file seal
wrote and, only if it holds, print the plaintext."""
import argparse
import sys

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

p = argparse.ArgumentParser(prog="vcrypt open")
p.add_argument("--key", required=True)
p.add_argument("--aad")
p.add_argument("infile")
a = p.parse_args()

key = bytes.fromhex(open(a.key).read().strip())
blob = sys.stdin.buffer.read() if a.infile == "-" else open(a.infile, "rb").read()
try:
    plain = AESGCM(key).decrypt(blob[:12], blob[12:], a.aad.encode() if a.aad else None)
except InvalidTag:
    print(f"{a.infile}: authentication failed, nothing decrypted", file=sys.stderr)
    sys.exit(1)
sys.stdout.buffer.write(plain)
```

`AESGCM` checks the tag inside `decrypt`, before it returns a single byte. Here they are on the
appointment file, with AES-256-GCM:

```
ana@lab:~/lab$ vcrypt seal --key keys/aes-256.hex --nonce 000000000000000000000001 data/slots.dat slots.gcm
sealed data/slots.dat: 12-byte nonce + 512 bytes of ciphertext + 16-byte tag -> slots.gcm
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex slots.gcm | head -3
room1 free     
room1 BOOKED   
room1 free     
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"The file vcrypt seal writes: a 12-byte nonce, then 512 bytes of ciphertext, then a 16-byte tag. A bracket shows that the tag is computed over the nonce, the ciphertext and any associated data, which is checked but not stored in the file.\"><rect x=\"20\" y=\"60\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nonce</text><text x=\"65\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><rect x=\"110\" y=\"60\" width=\"470\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"345\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ciphertext (AES in counter mode)</text><text x=\"345\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">512</text><rect x=\"580\" y=\"60\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"615\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tag</text><text x=\"615\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><polyline points=\"20,120 20,130 580,130 580,120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"300\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">covered by the tag, with the associated data (--aad)</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">One changed bit anywhere here, and open refuses the whole file.</text></svg>", "caption": "slots.gcm, byte by byte: the tag at the end vouches for everything before it."}
```

Now one bit of the ciphertext is changed, the kind of change a faulty disk or a hostile network
could make. A third tool does it:

```py
# ~/lab/tools/flip.py
"""vcrypt flip FILE OFFSET: change one bit of one byte of FILE, in place."""
import sys

path, offset = sys.argv[1], int(sys.argv[2])
data = bytearray(open(path, "rb").read())
data[offset] ^= 0x01
open(path, "wb").write(data)
print(f"{path}: byte {offset} XOR 0x01")
```

And the file is opened again with the right key:

```
ana@lab:~/lab$ vcrypt flip slots.gcm 18
slots.gcm: byte 18 XOR 0x01
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex slots.gcm | head -3; echo "exit status ${PIPESTATUS[0]}"
slots.gcm: authentication failed, nothing decrypted
exit status 1
```

**Nothing is returned.** Not a garbled block, not the first slots and an error later: the tag did
not match, so the whole file is refused and the exit status says so. Byte 18 is in the
ciphertext, but a change to the nonce or to the tag itself fails the same way, because the tag
covers everything that decryption uses.

That refusal is the behaviour to build on. Code that receives an authentication failure treats the
data as absent: it does not retry with another key until something decrypts, does not show the
part that came back, and logs the failure as an event worth looking at.

## Data that is checked but not encrypted

GCM can also cover bytes it does not encrypt, called **additional authenticated data**. A record's
identifier, the patient id it belongs to, the version of the format: these must stay readable so
that the system can find and route the record, yet nobody should be able to move a ciphertext from
one patient's row to another's. Passing the patient id as associated data binds the two. The
ciphertext copied into another row fails to open, because the tag was computed with the original
id:

```
ana@lab:~/lab$ vcrypt seal --key keys/aes-256.hex --nonce 000000000000000000000002 --aad patient=4471 data/referral.txt referral.gcm
sealed data/referral.txt: 12-byte nonce + 170 bytes of ciphertext + 16-byte tag -> referral.gcm
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex --aad patient=4471 referral.gcm | head -1
Referral 2026-0417. Patient: Marina Duarte, 41.
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex --aad patient=5120 referral.gcm; echo "exit status $?"
referral.gcm: authentication failed, nothing decrypted
exit status 1
```

## What GCM asks in return

GCM's one demand is the nonce rule of the previous section, and it is stricter here than for CTR. A
repeated nonce under the same key exposes the keystream, as in CTR, and also weakens the tag, so
that the check this section relies on can no longer be trusted for that key. Where a nonce cannot
be guaranteed unique, for example across many machines encrypting with one key and no shared
counter, **AES-GCM-SIV** is designed to fail gently: a repeated nonce reveals only that two
messages were identical. Lesson 17 comes back to nonce reuse as one of the three classic mistakes.

The summary of the lesson fits in one line: **AES with a 128- or 256-bit key, in GCM, with a nonce
that never repeats, and every failure to open treated as an attack.**
