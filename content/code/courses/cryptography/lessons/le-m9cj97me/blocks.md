---
title: AES works on blocks of sixteen bytes
version: 1
---

**AES is a block cipher: it takes exactly 16 bytes and a key, and returns exactly 16 bytes.** It
cannot take 15 bytes or 17. Whatever the key size, 128, 192 or 256 bits, the block is always 128
bits. A larger key means more rounds of mixing inside the box (10, 12 or 14), not a larger block.

That has two consequences any user of AES meets: a message is cut into blocks, and the last block
is filled up to sixteen. The rest of this lesson follows from the first one.

## A file is a row of blocks

Vereda's appointment file was built for this lesson. Each slot of Monday's agenda in room 1 is one
fixed-width record of exactly sixteen bytes, so that each record is one AES block. `vcrypt blocks`
prints a file sixteen bytes at a time, in hexadecimal, and marks a block it has already seen. It is
the lab's first tool, and this is all of it:

```py
# ~/lab/tools/blocks.py
"""vcrypt blocks FILE: the file sixteen bytes at a time, in hex, marking a
block already seen. With --letters, one letter per block instead, the same
letter for the same block. FILE may be -, to read what a pipe sends."""
import sys

LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

args = sys.argv[1:]
letters = "--letters" in args
path = [a for a in args if a != "--letters"][0]
data = sys.stdin.buffer.read() if path == "-" else open(path, "rb").read()
blocks = [data[i:i + 16] for i in range(0, len(data), 16)]

seen = {}
if letters:
    row = []
    for b in blocks:
        seen.setdefault(b, LETTERS[len(seen)] if len(seen) < len(LETTERS) else "?")
        row.append(seen[b])
    print(" ".join("".join(row[i:i + 4]) for i in range(0, len(row), 4)))
    sys.exit()
for n, b in enumerate(blocks, 1):
    mark = f"  same as block {seen[b]}" if b in seen else ""
    seen.setdefault(b, n)
    print(f"{n:3}  {b.hex()}{mark}")
print(f"{len(data)} bytes, {len(blocks)} blocks, {len(seen)} different")
```

Saved as `~/lab/tools/blocks.py`, it runs as `vcrypt blocks`:

```
ana@lab:~/lab$ vcrypt blocks data/slots.dat | head -6
  1  726f6f6d31206672656520202020200a
  2  726f6f6d3120424f4f4b45442020200a
  3  726f6f6d31206672656520202020200a  same as block 1
  4  726f6f6d31206672656520202020200a  same as block 1
  5  726f6f6d3120424f4f4b45442020200a  same as block 2
  6  726f6f6d31206672656520202020200a  same as block 1
```

`726f6f6d31` is `room1` in ASCII. Block 1 is a free slot, block 2 a booked one, and from there on
the file is the same two blocks in a different order: 32 records, two different values. Real files
are like this more often than people expect. Fixed-width records, zeroed regions of a disk image
and repeated headers all produce identical blocks, and the next section shows what an encryption
mode does with them.

## The last block is padded, always

The referral letter is 170 bytes, which is ten full blocks and ten bytes over. Encrypted with CBC,
it became 176:

```
ana@lab:~/lab$ wc -c data/referral.txt referral.enc
170 data/referral.txt
176 referral.enc
346 total
```

The six bytes are **padding**, and the rule OpenSSL uses is PKCS#7: fill the last block with *n*
bytes each worth *n*. Six bytes short, six bytes of `06`. On decryption the last byte says how many
to strip, and a value that does not fit the rule is the `bad decrypt` of the previous section.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two files cut into 16-byte AES blocks. referral.txt is 170 bytes: ten full blocks, then an eleventh holding the last 10 bytes of the letter and 6 bytes of padding, each worth 06. slots.dat is 512 bytes, exactly 32 full blocks, and still gets a 33rd block of sixteen bytes worth 10.\"><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">referral.txt</text><text x=\"130\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">170 bytes = 10 × 16 + 10</text><rect x=\"20\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"64\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"84\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"108\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"128\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"152\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"172\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"196\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><rect x=\"240\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><rect x=\"284\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"304\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><rect x=\"328\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"348\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8</text><rect x=\"372\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"392\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><rect x=\"416\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"436\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"460\" y=\"40\" width=\"120\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">10 bytes</text><rect x=\"536\" y=\"44\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"556\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">06×6</text><text x=\"592\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→ 176 bytes</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">slots.dat</text><text x=\"130\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">512 bytes = 32 × 16, no remainder</text><rect x=\"20\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"64\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"84\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"108\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"128\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"152\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"172\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"196\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><rect x=\"240\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><text x=\"298\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">…</text><rect x=\"314\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"334\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">32</text><rect x=\"358\" y=\"128\" width=\"120\" height=\"34\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"418\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">10×16</text><text x=\"494\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→ 528 bytes</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Red: padding. Each byte says how many bytes to remove.</text></svg>", "caption": "PKCS#7 padding: the last block is always completed, even when the data already fills it."}
```

The rule has no exception, and that is what makes it unambiguous. A file whose length is already
a multiple of sixteen still gets padding, a whole block of sixteen bytes of `10` (sixteen, in
hexadecimal). Otherwise a file that happened to end in `01` could not be told from a padded one.
The appointment file is 512 bytes, exactly 32 blocks, and its ciphertext is 528:

```
ana@lab:~/lab$ openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | wc -c
528
```

Not every mode pads. **CTR and GCM turn AES into a stream** (the next section and the last one),
so their ciphertext is exactly as long as the plaintext. That is one reason modern protocols prefer
them: no padding means no padding error, and a padding error that a server reports differently
from other errors has been enough, more than once, to let an outsider learn about the plaintext.
The defence is the one this lesson ends with, a mode that checks the whole ciphertext before it
decrypts anything.

## What sixteen bytes means for the size of the data

AES encrypts sixteen bytes at a time, and the ciphertext is never shorter than the plaintext. CBC
adds up to sixteen bytes of padding, and every mode needs its vector or nonce stored beside the
ciphertext, which section 07 of this lesson explains. GCM adds a sixteen-byte tag. For a database
column holding a CPF, that overhead is larger than the data, and lesson 14 comes back to what it
costs to encrypt a column rather than a disk.
