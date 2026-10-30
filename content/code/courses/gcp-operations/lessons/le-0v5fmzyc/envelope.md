---
title: Envelope encryption, on your own disk
version: 1
---

**Cloud KMS does not encrypt your data; it encrypts the keys that encrypt your data.** That arrangement is
**envelope encryption**. Each object is encrypted with its own data-encryption key (DEK), generated on the spot;
the DEK is then encrypted, "wrapped", with a key-encryption key (KEK) that lives in Cloud KMS, and the wrapped DEK
is stored beside the ciphertext. To read the object, a program asks Cloud KMS to unwrap the DEK, and decrypts
locally. The KEK never leaves Google, the plain DEK is never stored anywhere, and Cloud KMS sees a few bytes of key
per object rather than the gigabytes of data. **Cloud KMS has no emulator, so it is not used here.** What runs is
the pattern itself, with the KEK as files on your disk; every place where the program reads a KEK file is a place
where real code would make a call to Cloud KMS instead.

One package, into the course's environment:

```sh
cd ~/gcp && source venv/bin/activate
pip install -q 'cryptography==50.0.2'
```

Write the program into `~/gcp/envelope.py`:

```schooling-example
{"language": "python", "file": "envelope.py", "parts": [{"code": "\"\"\"envelope.py: envelope encryption, the pattern Cloud KMS is built for.\n\nA key-encryption key (KEK) wraps a fresh data-encryption key (DEK) for every\nobject. Here the KEK versions are files on your disk; in Cloud KMS they never\nleave Google, and wrapping and unwrapping are calls to it.\n\"\"\"\n", "note": "The docstring is the whole idea in four lines: a KEK wraps a new DEK for every object. Here the KEK is a file; in Cloud KMS it never leaves Google."}, {"code": "import json\nimport os\nimport pathlib\nimport sys\n\nfrom cryptography.hazmat.primitives.ciphers.aead import AESGCM\n\n", "note": "`AESGCM` from the `cryptography` package is authenticated encryption: it refuses to decrypt anything that was changed, rather than returning garbage."}, {"code": "KEYS = pathlib.Path(\"kek\")          # stands for a Cloud KMS key and its versions\n\n\ndef kek(version):\n    return (KEYS / f\"v{version}.bin\").read_bytes()\n\n\ndef primary():\n    return max(int(p.stem[1:]) for p in KEYS.glob(\"v*.bin\"))\n\n\n", "note": "The KEK's versions are files `kek/v1.bin`, `kek/v2.bin`, and the **primary** is the newest. Cloud KMS keeps exactly this: one key, numbered versions, one of them primary."}, {"code": "def rotate():\n    KEYS.mkdir(exist_ok=True)\n    v = primary() + 1 if any(KEYS.glob(\"v*.bin\")) else 1\n    (KEYS / f\"v{v}.bin\").write_bytes(AESGCM.generate_key(bit_length=256))\n    print(f\"key version {v} is now primary\")\n\n\n", "note": "Rotating adds a new version and makes it primary. Old versions stay, so everything they wrapped can still be read."}, {"code": "def encrypt(name, text):\n    dek = AESGCM.generate_key(bit_length=256)\n    n1, n2 = os.urandom(12), os.urandom(12)\n    v = primary()\n    wrapped = AESGCM(kek(v)).encrypt(n1, dek, None)\n    body = AESGCM(dek).encrypt(n2, text.encode(), None)\n    pathlib.Path(name).write_text(json.dumps({\n        \"kek_version\": v, \"wrapped_dek\": (n1 + wrapped).hex(),\n        \"ciphertext\": (n2 + body).hex()}))\n    print(f\"{name}: encrypted under key version {v}\")\n\n\n", "note": "Encrypting makes a fresh 256-bit DEK, encrypts the text with it, wraps the DEK with the primary KEK, and stores the wrapped DEK and the KEK's version **beside the ciphertext**. The DEK itself is never stored."}, {"code": "def decrypt(name):\n    doc = json.loads(pathlib.Path(name).read_text())\n    w = bytes.fromhex(doc[\"wrapped_dek\"])\n    dek = AESGCM(kek(doc[\"kek_version\"])).decrypt(w[:12], w[12:], None)\n    c = bytes.fromhex(doc[\"ciphertext\"])\n    print(f\"{name}: {AESGCM(dek).decrypt(c[:12], c[12:], None).decode()}\")\n\n\n", "note": "Decrypting reads which version wrapped the DEK, unwraps it with that version, and decrypts the text. In Cloud KMS the unwrap is one call to Google, and the KEK never reaches the program."}, {"code": "cmd = sys.argv[1]\nif cmd == \"rotate\":\n    rotate()\nelif cmd == \"encrypt\":\n    encrypt(sys.argv[2], sys.argv[3])\nelif cmd == \"decrypt\":\n    decrypt(sys.argv[2])\n", "note": "Three commands: `rotate`, `encrypt NAME TEXT` and `decrypt NAME`."}]}
```

## Two objects, two key versions

Create `~/gcp/vault`, work from inside it, and make the first key version; then encrypt an order with it:

```
ana@laptop:~/gcp/vault$ python3 ../envelope.py rotate
key version 1 is now primary
ana@laptop:~/gcp/vault$ python3 ../envelope.py encrypt order-1001.json 'card ending 4242, R$ 43.80'
order-1001.json: encrypted under key version 1
ana@laptop:~/gcp/vault$ jq -c '{kek_version, wrapped_dek: .wrapped_dek[:24], ciphertext: .ciphertext[:24]}' order-1001.json
{"kek_version":1,"wrapped_dek":"f38a234e4845963e0172c1e1","ciphertext":"c368dd5bd7a542f4c6b56eac"}
```

The file holds three things: which KEK version wrapped its DEK, the wrapped DEK, and the ciphertext (the `jq`
shows their first characters). Nothing in it can be read without version 1. Now rotate and encrypt a second order:

```
ana@laptop:~/gcp/vault$ python3 ../envelope.py rotate
key version 2 is now primary
ana@laptop:~/gcp/vault$ python3 ../envelope.py encrypt order-1002.json 'pix, R$ 18.90'
order-1002.json: encrypted under key version 2
ana@laptop:~/gcp/vault$ python3 ../envelope.py decrypt order-1001.json
order-1001.json: card ending 4242, R$ 43.80
ana@laptop:~/gcp/vault$ python3 ../envelope.py decrypt order-1002.json
order-1002.json: pix, R$ 18.90
ana@laptop:~/gcp/vault$ ls kek
v1.bin
v2.bin
```

**Rotation did not re-encrypt anything.** The first order is still wrapped by version 1, which still exists, so it
still decrypts; the second is wrapped by version 2, the new primary. That is exactly what Cloud KMS's automatic
rotation does: it adds a version and makes it primary, and old data stays readable through old versions. Rotating
limits how much data any single version protects; it does not change data already written.

## Destroying a version

Delete version 1, as destroying a key version in Cloud KMS would:

```
ana@laptop:~/gcp/vault$ rm kek/v1.bin
ana@laptop:~/gcp/vault$ python3 ../envelope.py decrypt order-1001.json 2>&1 | tail -1
FileNotFoundError: [Errno 2] No such file or directory: 'kek/v1.bin'
ana@laptop:~/gcp/vault$ python3 ../envelope.py decrypt order-1002.json
order-1002.json: pix, R$ 18.90
```

**The first order can no longer be read by anybody, ever**, and the second is untouched. Destroying a key version is
the one operation that makes data unrecoverable without touching the data: the ciphertext is still on disk, and it
is noise. That is useful on purpose (deleting every copy of a customer's data, backups included, by destroying the
one key that wrapped it) and catastrophic by accident. The next section is about the safeguards Cloud KMS puts in
front of it.
