---
title: Envelope encryption
version: 1
---

Transit is right for a CPF: a few bytes, sent and returned in one request. It is wrong for a
backup. Sending 1.8 MB through the service is slow, sending 180 GB is absurd, and the service
would see every byte of the data it was meant to never hold.

The answer every key-management service uses is **envelope encryption**: the service generates a
fresh **data key** for the job and returns it twice — once in clear, to encrypt the data locally,
and once **wrapped**, encrypted with a key that never leaves the service. The data is encrypted
with the plaintext data key, which is then thrown away; the wrapped copy is stored beside the
data. To read the data, the wrapped key goes back to the service, which unwraps it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l4-envelope\" aria-label=\"Envelope encryption of a backup. The key service generates a data key and returns it twice: in clear, and wrapped by the ipe-backup key. The clear data key encrypts the dump and is shredded. The encrypted dump and the wrapped key are stored together. To restore, the wrapped key goes back to the service, which unwraps it.\"><defs><marker id=\"dg-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"170.0\" height=\"200.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">key service</text><rect x=\"45.0\" y=\"72.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ipe-backup</text><text x=\"105.0\" y=\"152.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">generates a</text><text x=\"105.0\" y=\"167.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">data key</text><rect x=\"260.0\" y=\"40.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">data key, in clear</text><text x=\"345.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backup.key</text><rect x=\"260.0\" y=\"160.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">data key, wrapped</text><text x=\"345.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backup.key.wrapped</text><path d=\"M190.0 80.0 L258.0 65.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M190.0 180.0 L258.0 185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"40.0\" width=\"200.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">encrypts the dump,</text><text x=\"600.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">then shredded</text><path d=\"M430.0 65.0 L498.0 65.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><rect x=\"500.0\" y=\"140.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">stored together</text><rect x=\"515.0\" y=\"170.0\" width=\"170.0\" height=\"26.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">customers.sql.enc</text><rect x=\"515.0\" y=\"200.0\" width=\"170.0\" height=\"24.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">backup.key.wrapped</text><path d=\"M430.0 185.0 L498.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M600.0 90.0 L600.0 138.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path></svg>", "caption": "The data never goes to the key service, and the key that wraps it never comes out."}
```

A key for backups, and a data key from it:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-backup
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791350399]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-backup
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao write -f -format=json transit/datakey/plaintext/ipe-backup > datakey.json && python3 -c "import json; d = json.load(open('datakey.json'))['data']; print(sorted(d))"
['ciphertext', 'key_version', 'plaintext']
```

The response has three fields: `plaintext`, the data key in clear; `ciphertext`, the same key
wrapped by `ipe-backup`; and the version of `ipe-backup` that wrapped it.

## A backup in an envelope

```
ana@lab:~/gov$ python3 -c "import json; print(json.load(open('datakey.json'))['data']['ciphertext'])" > backup.key.wrapped
ana@lab:~/gov$ python3 -c "import json; print(json.load(open('datakey.json'))['data']['plaintext'])" > backup.key && rm datakey.json
ana@lab:~/gov$ sudo -u postgres pg_dump -d ipe -t sales.customers | openssl enc -aes-256-cbc -pbkdf2 -pass file:backup.key -out customers.sql.enc
ana@lab:~/gov$ shred -u backup.key && ls -l customers.sql.enc backup.key.wrapped
-rw-r--r-- 1 ana ana      90 Oct  7 02:19 backup.key.wrapped
-rw-r--r-- 1 ana ana 1847744 Oct  7 02:19 customers.sql.enc
ana@lab:~/gov$ grep -c paula.cavalcanti customers.sql.enc
0
```

The wrapped key is saved to a file; the plaintext key is used once, by `openssl`, to encrypt the
dump on its way to the disk, and then **`shred`** overwrites and removes it. What is left is
1,847,744 bytes of ciphertext and a 90-byte wrapped key, and `grep` finds Paula nowhere in the
backup — where lesson 3's dump had her on the first line.

The two files can travel together. The wrapped key is useless without OpenBao, and OpenBao is
useless without a token allowed to decrypt with `ipe-backup` — a policy the backup operator holds
and the people who store backups do not.

## And back

```
ana@lab:~/gov$ bao write -field=plaintext transit/decrypt/ipe-backup ciphertext=$(cat backup.key.wrapped) > backup.key
ana@lab:~/gov$ openssl enc -d -aes-256-cbc -pbkdf2 -pass file:backup.key -in customers.sql.enc | grep paula.cavalcanti | cut -f 1-4; shred -u backup.key
1	Paula Cavalcanti Silva	paula.cavalcanti@example.com	372.874.168-09
1097	Paula Cavalcanti Pereira	paula.cavalcanti2@example.com	037.846.602-00
5955	Paula Cavalcanti Cardoso	paula.cavalcanti2@example.org	859.266.865-44
```

The wrapped key goes to OpenBao and comes back as the plaintext data key, which decrypts the
backup and is shredded again. The rows come back — three customers called Paula Cavalcanti, the
first of whom is the one every lesson so far has shown.

**Every restore is a decryption in OpenBao's audit log**, with the token and the time. "Who
restored the customers' backup last month" becomes a question with an answer, which it was not
when a backup's key was a password in a script.
