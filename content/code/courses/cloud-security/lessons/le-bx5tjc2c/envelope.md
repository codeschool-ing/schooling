---
title: Envelope encryption, or why KMS never sees your data
version: 1
---

**KMS does not encrypt your files. It encrypts small keys, and those keys encrypt your files.** The
pattern is called *envelope encryption*: the data is locked with a data key, the data key is locked
with the KMS key, and the locked data key is stored beside the data, like a letter in an envelope.
S3, EBS and every other AWS service that uses KMS work this way.

The wrong picture is that S3 sends each object to KMS to be encrypted. It could not: **KMS takes at
most 4096 bytes of plain text in one request.** Start moto empty, with its checking off, and recreate
the clinic's key under the same alias as before:

```
ana@laptop:~/aws$ k=$(aws kms create-key --description "clinic records" --query KeyMetadata.KeyId --output text)
ana@laptop:~/aws$ aws kms create-alias --alias-name alias/clinic-records --target-key-id "$k"
```

Your lab enforces the same limit as AWS:

```
ana@laptop:~/aws$ head -c 5000 /dev/zero > big.bin && aws kms encrypt --key-id alias/clinic-records --plaintext fileb://big.bin --query KeyId --output text

aws: [ERROR]: An error occurred (ValidationException) when calling the Encrypt operation: 1 validation error detected: Value at 'plaintext' failed to satisfy constraint: Member must have length less than or equal to 4096
```

Four kilobytes is enough for a password or a key, and nowhere near enough for a scanned exam. The
`cryptography` course's lesson 1 described the cipher that does the real work, AES; envelope
encryption is how a cloud hands AES a key without ever handing out the key that protects all the
others.

## Encrypting something small

A short secret can go to KMS directly. Encrypt a note, keep the ciphertext in a file, and ask for
it back:

```
ana@laptop:~/aws$ printf 'door code: 4471' > note.txt && aws kms encrypt --key-id alias/clinic-records --plaintext fileb://note.txt --query CiphertextBlob --output text | base64 -d > note.enc
ana@laptop:~/aws$ aws kms decrypt --ciphertext-blob fileb://note.enc --query KeyId --output text
arn:aws:kms:sa-east-1:123456789012:key/3dc44faa-5788-45db-b010-8787db7bf058
ana@laptop:~/aws$ aws kms decrypt --ciphertext-blob fileb://note.enc --query Plaintext --output text | base64 -d; echo
door code: 4471
```

**The decrypt request did not name a key.** A ciphertext from a symmetric KMS key carries a
reference to the key that made it, and KMS reads it from there, which is why the answer names the
key's ARN. The plain text comes back base64-encoded, and `base64 -d` turns it into the note again.
moto writes that reference as the key id in clear at the start of its ciphertext; AWS's ciphertext
has a format of its own, which is not meant to be read.

## A data key, for anything larger

`generate-data-key` asks KMS for a fresh 256-bit key, returned twice: once in plain text, to use now,
and once encrypted under the KMS key, to keep.

```
ana@laptop:~/aws$ aws kms generate-data-key --key-id alias/clinic-records --key-spec AES_256 --query "[KeyId,length(Plaintext),length(CiphertextBlob)]" --output text
arn:aws:kms:sa-east-1:123456789012:key/3dc44faa-5788-45db-b010-8787db7bf058	44	128
```

The plain key is 44 characters of base64, which is 32 bytes, which is 256 bits. The encrypted copy is
longer: besides the 32 bytes, it carries what KMS needs to decrypt it, the reference to its key
among them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l11-envelope\" aria-label=\"Envelope encryption. On the left, inside KMS, the KMS key, which never leaves. KMS generates a data key and returns it twice: in plain text, and encrypted under the KMS key. In the middle, the service encrypts the data with the plain data key, using AES, and then erases the plain key. On the right, what is stored: the encrypted data with the encrypted data key beside it, like a letter in its envelope. To read it back, only the encrypted data key goes to KMS, which checks the caller's permission before returning the plain key.\"><defs><marker id=\"l11-envelope-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-envelope-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"180.0\" height=\"240.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"110.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">KMS</text><rect x=\"40.0\" y=\"90.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">KMS key</text><text x=\"110.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">never leaves</text><text x=\"110.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">generates a</text><text x=\"110.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data key and</text><text x=\"110.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">returns it twice</text><rect x=\"250.0\" y=\"40.0\" width=\"210.0\" height=\"240.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the service</text><rect x=\"270.0\" y=\"82.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">plain data key</text><rect x=\"270.0\" y=\"128.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encrypted data key</text><text x=\"355.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AES with the plain key</text><text x=\"355.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encrypts the data</text><text x=\"355.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">then erases the plain key</text><path d=\"M200.0 105.0 L268.0 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-envelope-af-ah-paper-dim)\"></path><path d=\"M200.0 125.0 L268.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-envelope-af-ah-paper-dim)\"></path><rect x=\"510.0\" y=\"40.0\" width=\"190.0\" height=\"240.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">what is stored</text><rect x=\"530.0\" y=\"90.0\" width=\"150.0\" height=\"100.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">encrypted data</text><rect x=\"530.0\" y=\"202.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encrypted data key</text><path d=\"M460.0 145.0 L528.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-envelope-af-ah-paper-dim)\"></path><path d=\"M460.0 150.0 L528.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-envelope-af-ah-paper-dim)\"></path><path d=\"M605 282 L605 306 L110 306 L110 282\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l11-envelope-af-ah-phosphor)\"></path><text x=\"357.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">to read: only the encrypted data key goes back to KMS, which checks the caller</text></svg>", "caption": "KMS holds one key and never sees the data; each object carries its own data key, locked under it. Every read asks KMS again, with the caller's identity on the request."}
```

What a service does with the pair, in four steps:

1. encrypt the data locally, with AES and the plain data key;
2. **erase the plain data key from memory**;
3. store the encrypted data key beside the encrypted data;
4. to read it back, send only the encrypted data key to KMS, receive the plain one, decrypt, erase
   it again.

**Every read is a `Decrypt` call to KMS, with the caller's identity on it.** That is why the second
lock of the last section works: KMS is asked every time, and it can say no. It is also what a
`BucketKeyEnabled` setting changes: S3 keeps one intermediate key per bucket for a while instead of
asking KMS for each object, which AWS documents as cutting the number of KMS requests, and their
cost, by a large factor. The `cryptography` course's lesson 14 met the same envelope in disk and
database encryption, where the data key encrypts a whole volume.
