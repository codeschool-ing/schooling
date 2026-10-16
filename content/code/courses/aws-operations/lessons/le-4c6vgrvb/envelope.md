---
title: Envelope encryption, for anything larger
version: 1
---

The way AWS encrypts a terabyte with a key that only takes 4 KB is **envelope encryption**: KMS makes a
fresh **data key**, gives it to the program twice, once in plain and once encrypted under the KMS key,
and the program encrypts the data itself with the plain one, keeps the encrypted one beside the result,
and forgets the plain one. S3, EBS and RDS do exactly this on every object, volume and database, and a
program can too, in `~/aws/kms/envelope.py`:

```schooling-example
{"language": "python", "file": "envelope.py", "parts": [{"code": "# envelope.py: encrypt a file with a data key from KMS, and keep only the key's ciphertext\n#   python3 envelope.py seal FILE      writes FILE.sealed\n#   python3 envelope.py open FILE.sealed  prints what was sealed\nimport base64\nimport json\nimport os\nimport sys\n\nimport boto3\nfrom cryptography.hazmat.primitives.ciphers.aead import AESGCM\n\nkms = boto3.client(\"kms\")\n\n\n", "note": "Two libraries beyond the standard one: `boto3` to ask KMS, and `cryptography` to encrypt locally. Both are already in `~/aws/venv`, because moto needs them too."}, {"code": "def seal(path):\n    key = kms.generate_data_key(KeyId=\"alias/shop-orders\", KeySpec=\"AES_256\")\n", "note": "**One request to KMS per file, whatever its size.** The answer holds the same 256-bit data key twice: `Plaintext`, to use now, and `CiphertextBlob`, that key encrypted under `alias/shop-orders`, to keep."}, {"code": "    nonce = os.urandom(12)\n    with open(path, \"rb\") as f:\n        data = AESGCM(key[\"Plaintext\"]).encrypt(nonce, f.read(), None)\n", "note": "The file is encrypted here, on this computer, with AES-GCM, which also detects any change to the result. A nonce is never reused with the same key, and a fresh key per file makes that easy."}, {"code": "    sealed = {\n        \"key\": base64.b64encode(key[\"CiphertextBlob\"]).decode(),\n        \"nonce\": base64.b64encode(nonce).decode(),\n        \"data\": base64.b64encode(data).decode(),\n    }\n    with open(path + \".sealed\", \"w\") as f:\n        json.dump(sealed, f)\n\n\n", "note": "**The envelope**: the encrypted data, and beside it the encrypted data key. The plaintext data key is written nowhere and is gone when the function returns."}, {"code": "def unseal(path):\n    with open(path) as f:\n        sealed = json.load(f)\n    key = kms.decrypt(CiphertextBlob=base64.b64decode(sealed[\"key\"]))[\"Plaintext\"]\n    nonce, data = base64.b64decode(sealed[\"nonce\"]), base64.b64decode(sealed[\"data\"])\n    return AESGCM(key).decrypt(nonce, data, None)\n\n\n", "note": "Opening reverses it: KMS decrypts the small data key, which needs permission on `alias/shop-orders`, and the data is decrypted locally. Whoever cannot call `kms:Decrypt` holds a file of noise."}, {"code": "if sys.argv[1] == \"seal\":\n    seal(sys.argv[2])\nelse:\n    sys.stdout.write(unseal(sys.argv[2]).decode())\n", "note": "`seal` writes the envelope; `open` prints what it held, as text, which suits the small file this section seals."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Inside KMS, the key alias/shop-orders, which never leaves. GenerateDataKey returns a data key twice: in plain, and encrypted under the KMS key. The plain data key and orders.csv go into AES-GCM, which produces the encrypted data. The sealed file, orders.csv.sealed, holds the encrypted data and the encrypted data key. The plain data key is used once, then forgotten.\"><defs><marker id=\"env-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"170\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"105\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">inside KMS</text><rect x=\"30\" y=\"60\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">KMS key</text><text x=\"105.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alias/shop-orders</text><text x=\"105\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never leaves</text><path d=\"M192 82 L268 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><text x=\"196\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">GenerateDataKey</text><rect x=\"270\" y=\"40\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">data key, plain</text><rect x=\"270\" y=\"100\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">data key, encrypted</text><path d=\"M192 92 L268 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><rect x=\"270\" y=\"200\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders.csv</text><rect x=\"480\" y=\"120\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"540.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">AES-GCM</text><path d=\"M442 64 L520 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><path d=\"M442 218 L520 162\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><rect x=\"470\" y=\"190\" width=\"230\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">orders.csv.sealed</text><rect x=\"484\" y=\"200\" width=\"202\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encrypted data</text><rect x=\"484\" y=\"232\" width=\"202\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encrypted data key</text><path d=\"M540 162 L540 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><path d=\"M442 128 L456 128 L456 245 L482 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><text x=\"355\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">used once, then forgotten</text></svg>", "caption": "The KMS key encrypts only the data key. The data is encrypted on the computer, and the envelope carries the encrypted key beside it."}
```

## Sealing the orders

A small file of made-up orders, with card digits from the ranges card networks publish for testing:

```
ana@laptop:~/aws/kms$ printf 'order,card_last4,total\n1001,4242,129.90\n1002,1881,59.00\n' > orders.csv
ana@laptop:~/aws/kms$ python3 envelope.py seal orders.csv
ana@laptop:~/aws/kms$ jq "keys" orders.csv.sealed
[
  "data",
  "key",
  "nonce"
]
ana@laptop:~/aws/kms$ jq -r .key orders.csv.sealed | base64 -d | wc -c
96
ana@laptop:~/aws/kms$ rm orders.csv && python3 envelope.py open orders.csv.sealed
order,card_last4,total
1001,4242,129.90
1002,1881,59.00
```

The envelope holds three fields and no key anybody can use: the data key it carries is **96 bytes of
ciphertext** here, a little more on AWS, readable only by asking KMS. With `orders.csv` deleted, the only way back to it is through
`kms:Decrypt` on `alias/shop-orders`, which is a permission, which is a policy, which is the point.

## The size does not matter to KMS

```
ana@laptop:~/aws/kms$ head -c 5000000 /dev/urandom > photos.tar && python3 envelope.py seal photos.tar && wc -c photos.tar photos.tar.sealed
 5000000 photos.tar
 6666868 photos.tar.sealed
11666868 total
```

Five megabytes took **the same single request** to KMS as the three lines did; the work is AES on this
computer. The sealed file is larger by a third, because the program stores it as base64 inside JSON to
stay readable; a real format stores the bytes. Envelope encryption is also why rotating a KMS key, in
the next section, never re-encrypts data: only data keys are ever encrypted under it.
