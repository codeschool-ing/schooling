---
title: Rolling your own
version: 1
---

**"Rolling your own" rarely means inventing a cipher. It means assembling sound primitives into a
scheme of one's own, and the scheme is where the mistakes live.** AES is not broken in the code
below. The code is.

## A contractor's encryption

Vereda's first booking system came from a contractor, who wrote a function to encrypt patient records
before storing them. It uses AES with a 256-bit key and runs without error. It was reviewed in the
lab against a library's authenticated mode:

```schooling-example
{
  "language": "python",
  "file": "homemade.py",
  "parts": [
    {
      "code": "import hashlib\nimport os\n\nfrom cryptography.exceptions import InvalidTag\nfrom cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes\nfrom cryptography.hazmat.primitives.ciphers.aead import AESGCM\n\nrecord = b\"patient 4471, Marina Duarte, lumbar pain, session 3 of 10\"",
      "note": "One record from the clinic's lab data, and two ways to encrypt it."
    },
    {
      "code": "def homemade(password, text):\n    key = hashlib.sha256(password.encode()).digest()\n    enc = Cipher(algorithms.AES(key), modes.CBC(bytes(16))).encryptor()\n    return enc.update(text + b\" \" * (-len(text) % 16)) + enc.finalize()",
      "note": "The contractor's function. Every line uses AES, and every line has a mistake an earlier lesson named: the key is a fast, unsalted hash of a password (lesson 5); the IV is sixteen zero bytes, every time (lesson 1); the padding is spaces, so a record that ended in a space loses it; and nothing detects a change (lesson 1 again)."
    },
    {
      "code": "a = homemade(\"vereda2026\", record)\nb = homemade(\"vereda2026\", record)\nprint(\"homemade, same record twice: \", \"identical\" if a == b else \"different\")",
      "note": "The fixed IV makes it deterministic: the same record, encrypted twice, gives the same bytes, so anybody who can see the stored values can tell which ones repeat."
    },
    {
      "code": "key = AESGCM.generate_key(bit_length=256)\n\ndef seal(text):\n    nonce = os.urandom(12)\n    return nonce + AESGCM(key).encrypt(nonce, text, None)\n\na, b = seal(record), seal(record)\nprint(\"AES-GCM, same record twice:  \", \"identical\" if a == b else \"different\")",
      "note": "The library's authenticated mode, used as its documentation says: a random key, a fresh 12-byte nonce from the operating system for every message, the nonce stored in front of the ciphertext."
    },
    {
      "code": "changed = bytearray(a)\nchanged[20] ^= 1\ntry:\n    AESGCM(key).decrypt(bytes(changed[:12]), bytes(changed[12:]), None)\nexcept InvalidTag:\n    print(\"AES-GCM, one byte changed:    refused\")",
      "note": "A changed byte is refused rather than decrypted, the property the last section of lesson 1 showed with `vcrypt open`."
    }
  ],
  "output": "homemade, same record twice:  identical\nAES-GCM, same record twice:   different\nAES-GCM, one byte changed:    refused"
}
```

```
ana@lab:~/lab$ python3 homemade.py
homemade, same record twice:  identical
AES-GCM, same record twice:   different
AES-GCM, one byte changed:    refused
```

None of those defects shows up in a test that encrypts, decrypts and compares. The function returns
the right record every time. **Every defect is about what the function does with somebody else's
input or over many calls.** Two records that start with the same sixteen bytes produce the same first
block. A guessable password gives the key away no matter how strong AES is. A change to the
stored bytes decrypts to something nobody notices.

## Why the test passed and the design failed

Cryptographic code has a property most code does not: **working and being secure are unrelated.** A
sorting function that returns the wrong order fails its tests. An encryption function with a fixed
IV, an unsalted key or no integrity returns exactly the right plaintext, and its weakness only shows
to somebody looking for it, usually later and usually with the stored data in hand.

That is why the professional rule is not "be careful" but **"do not assemble"**:

- Use a library's **high-level interface**, the one designed so that the safe use is the easy one: an
  AEAD such as AES-GCM or ChaCha20-Poly1305 with nonces handled as its documentation says, or a
  complete recipe such as `cryptography`'s Fernet, libsodium's `secretbox`, or age for files.
- Derive keys from passwords with a function made for it (Argon2id, lesson 5), never with a hash.
- Let TLS (lesson 10) protect data in transit, rather than encrypting a payload by hand and sending
  it over plain HTTP.
- Treat any module whose imports include `modes.CBC`, `modes.ECB` or a raw block cipher as code that
  needs a cryptographer's review, because a correct use of those is possible and rarely what is there.

## When something new is needed

Sometimes no existing recipe fits. The responsible path is then the one that gave the world AES and
TLS 1.3: a written design, published, analysed by people who did not write it, for years, before
anybody depends on it. A secret algorithm, or one only its author has examined, has none of that.
Kerckhoffs's principle, from 1883, puts it in one line: a system must stay secure when everything
about it except the key is public.
