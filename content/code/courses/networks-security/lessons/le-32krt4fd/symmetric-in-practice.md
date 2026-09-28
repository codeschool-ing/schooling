---
title: Symmetric encryption, and why it must be authenticated
version: 1
---

A file, a key made of 32 random bytes written as hexadecimal, and AES-256 in CBC mode through
`openssl enc`:

```
ana@laptop:~$ printf "Payroll for September: 42 people, BRL 318,450.00\n" > payroll.txt; wc -c payroll.txt
49 payroll.txt
ana@laptop:~$ openssl rand -hex 32 > key.hex; wc -c key.hex
65 key.hex
ana@laptop:~$ openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt -in payroll.txt -out payroll.enc -pass file:key.hex; wc -c payroll.enc; head -c 8 payroll.enc; echo
80 payroll.enc
Salted__
ana@laptop:~$ openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in payroll.enc -pass file:key.hex
Payroll for September: 42 people, BRL 318,450.00
```

The key file is 65 bytes: 64 hex digits and a newline. The encrypted file is **80 bytes for a 49-byte
message**: `openssl` writes the marker `Salted__` and an 8-byte salt at the start, and CBC pads the
message to a whole number of 16-byte blocks. `-pbkdf2 -iter 600000` turns the key file into the
actual key through 600,000 rounds of hashing, which matters when the "key" is a password somebody
typed and costs nothing here. With the same key, the message comes back.

**This works and has a flaw worth knowing by name**: CBC keeps the message secret and says nothing
about whether it was changed. Flip bits in the encrypted file and decryption produces a different
message, often garbled, sometimes plausibly altered, and nothing reports it.

## Authenticated encryption

Modern protocols use **authenticated encryption** (AEAD): the cipher produces the encrypted data
**and a tag**, a short value computed with the key over the whole message. Decryption recomputes the
tag and refuses to return anything if it differs. AES-GCM and ChaCha20-Poly1305 are the two in
everyday use. A short program with Python's `cryptography` library shows the refusal:

```schooling-example
{"language": "python", "file": "seal.py", "parts": [{"code": "from cryptography.hazmat.primitives.ciphers.aead import AESGCM", "note": "AES in GCM mode, from the `cryptography` library that Ubuntu packages as `python3-cryptography`."}, {"code": "key = AESGCM.generate_key(bit_length=256)\nnonce = b\"\\x00\" * 11 + b\"\\x01\"\nbox = AESGCM(key)", "note": "A fresh random 256-bit key, and a 12-byte **nonce**, a number used once. GCM's one hard rule is never to encrypt two messages with the same key and the same nonce; a real protocol counts up or draws them at random. This key lives for one run, so one fixed nonce is safe here."}, {"code": "sealed = box.encrypt(nonce, b\"pay 318,450.00 to account 4471\", None)\nprint(len(sealed), \"bytes sealed\")\nprint(box.decrypt(nonce, sealed, None).decode())", "note": "Encrypt and decrypt. The result is the message's 30 bytes plus a 16-byte tag."}, {"code": "tampered = bytearray(sealed)\ntampered[4] ^= 0x01\ntry:\n    box.decrypt(nonce, bytes(tampered), None)\nexcept Exception as e:\n    print(\"refused:\", type(e).__name__)", "note": "Flip one bit of one byte and try again. Decryption does not return a slightly different message: it returns nothing and raises `InvalidTag`."}], "output": "46 bytes sealed\npay 318,450.00 to account 4471\nrefused: InvalidTag"}
```

The program as it ran on `laptop`:

```
ana@laptop:~$ python3 seal.py
46 bytes sealed
pay 318,450.00 to account 4471
refused: InvalidTag
```

**46 bytes sealed** for a 30-byte instruction: the 16 extra are the tag. One changed bit and the
message is refused whole. That is the property a payment instruction needs, and the reason every
protocol in the rest of this course uses AEAD rather than a bare cipher.
