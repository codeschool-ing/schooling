---
title: Encrypting the data with a key the app never holds
version: 1
---

**The app's own encryption uses two keys, and the one that matters never leaves the hardware.** A
single key stored beside the data it protects is a lock with the key taped to it, which is the
design people reach for first: generate a key, save it in a file, encrypt the database with it. A
backup that copies the database copies the key with it.

The design that works is called **envelope encryption**:

- a **data key**, random, encrypts the planner's data. It is stored on the disk, but only
  **wrapped**: encrypted itself.
- a **key-encryption key** wraps the data key. It lives in the Android Keystore or the iOS Keychain,
  which the last section showed, and never leaves it.

To read, the app asks the hardware to unwrap the data key, decrypts, and lets the data key go. The
split has a second use: changing the key-encryption key, after a biometric change for instance,
means wrapping 32 bytes again rather than re-encrypting the whole database.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l19-envelope\" aria-label=\"Envelope encryption. Inside the phone's hardware, the Keystore or Keychain, sits the key-encryption key, which never leaves it. On the disk sit the wrapped data key, dek.wrapped, and the sealed data, sessions.enc. To read, the hardware unwraps the data key, the data key opens the sessions, and the data key is then let go.\"><defs><marker id=\"l19-envelope-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-envelope-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the hardware: Keystore or Keychain</text><rect x=\"40\" y=\"100\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">key-encryption key</text><text x=\"130\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">never leaves</text><rect x=\"300\" y=\"20\" width=\"400\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">the disk, in the sandbox</text><rect x=\"330\" y=\"70\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"88.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the data key, wrapped</text><text x=\"415.0\" y=\"101.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dek.wrapped</text><rect x=\"510\" y=\"150\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the sessions, sealed</text><text x=\"595.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sessions.enc</text><path d=\"M220 125 L328 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-envelope-ah-phosphor)\"></path><text x=\"274\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">unwraps</text><path d=\"M500 110 L560 148\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-envelope-ah-amber)\"></path><text x=\"538\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">opens</text></svg>", "caption": "Two keys. The one stored beside the data is useless without the one that never leaves the hardware."}
```

## Built in Node, with `node:crypto`

Node has no Keystore, so `kek.bin`, a file, stands in for it here; that one line is what a phone
does differently. Everything else is what an app does. Save this in `~/planner/crypt` as
`crypt.ts`:

```schooling-example
{"language": "typescript", "file": "crypt.ts", "parts": [{"code": "// crypt.ts: the planner's sessions encrypted at rest, with a data key wrapped by a key-encryption key.\n// usage: node crypt.ts init | node crypt.ts seal | node crypt.ts open\nimport { randomBytes, createCipheriv, createDecipheriv } from \"node:crypto\";\nimport { readFileSync, writeFileSync, existsSync } from \"node:fs\";\nimport { sessions } from \"../data.ts\";\n", "note": "The program has three commands, and imports the six sessions of lesson 1 to have something to protect."}, {"code": "// AES-256-GCM: a 12-byte nonce that is never used twice with one key, and a 16-byte tag\n// that fails the decryption if a single bit of the file changed.\nfunction seal(key: Buffer, plain: Buffer): Buffer {\n  const nonce = randomBytes(12);\n  const c = createCipheriv(\"aes-256-gcm\", key, nonce);\n  const body = Buffer.concat([c.update(plain), c.final()]);\n  return Buffer.concat([nonce, c.getAuthTag(), body]);\n}", "note": "Sealing draws a fresh 12-byte nonce every time and writes it in front of the tag and the ciphertext, so the file carries everything opening needs except the key."}, {"code": "function open(key: Buffer, sealed: Buffer): Buffer {\n  const d = createDecipheriv(\"aes-256-gcm\", key, sealed.subarray(0, 12));\n  d.setAuthTag(sealed.subarray(12, 28));\n  return Buffer.concat([d.update(sealed.subarray(28)), d.final()]);\n}\n", "note": "Opening reads the three pieces back. `final()` throws if the tag does not match, which is the refusal the tampered run shows."}, {"code": "// kek.bin stands in for the key a phone keeps in its Keystore or Keychain, which never leaves\n// the hardware. Only the data key, wrapped by it, is stored beside the data.\nconst kek = () => readFileSync(\"kek.bin\");\nconst dataKey = () => open(kek(), readFileSync(\"dek.wrapped\"));\n", "note": "The two keys. On a phone `kek()` is a call to the Keystore or the Keychain, and the data key exists only for as long as one seal or one open takes."}, {"code": "const cmd = process.argv[2];\nif (cmd === \"init\") {\n  writeFileSync(\"kek.bin\", randomBytes(32));\n  writeFileSync(\"dek.wrapped\", seal(kek(), randomBytes(32)));\n  console.log(\"made a key-encryption key and a wrapped data key\");", "note": "`init` makes both keys once. The data key is written to the disk already wrapped; its plain form is never saved."}, {"code": "} else if (cmd === \"seal\") {\n  const before = existsSync(\"sessions.enc\") ? readFileSync(\"sessions.enc\") : undefined;\n  const out = seal(dataKey(), Buffer.from(JSON.stringify(sessions)));\n  writeFileSync(\"sessions.enc\", out);\n  console.log(`sealed ${sessions.length} sessions into ${out.length} bytes` +\n    (before ? `; same bytes as the last seal: ${before.equals(out) ? \"yes\" : \"no\"}` : \"\"));", "note": "`seal` encrypts the sessions and compares the result with the last seal, to show that the same data never gives the same bytes."}, {"code": "} else if (cmd === \"open\") {\n  try {\n    const list = JSON.parse(open(dataKey(), readFileSync(\"sessions.enc\")).toString()) as typeof sessions;\n    console.log(`opened ${list.length} sessions; the first is ${list[0].id}, ${list[0].course}, ${list[0].date}`);\n  } catch (e) {\n    console.log(`refused: ${(e as Error).message}`);\n    process.exitCode = 1;\n  }\n}", "note": "`open` decrypts, or says why it refused. A refusal sets a failing exit code rather than printing nothing."}]}
```

Make the keys, seal the sessions twice, open them, and look for a course id in the sealed file:

```
ana@dev:~/planner/crypt$ node crypt.ts init
made a key-encryption key and a wrapped data key
ana@dev:~/planner/crypt$ node crypt.ts seal
sealed 6 sessions into 493 bytes
ana@dev:~/planner/crypt$ node crypt.ts seal
sealed 6 sessions into 493 bytes; same bytes as the last seal: no
ana@dev:~/planner/crypt$ node crypt.ts open
opened 6 sessions; the first is s1, spanish, 2026-10-19
ana@dev:~/planner/crypt$ grep -c spanish ../data.ts sessions.enc
../data.ts:3
sessions.enc:0
```

**Two seals of the same six sessions gave different bytes**, because each one drew a fresh nonce.
That is the rule GCM cannot survive breaking: two messages sealed with one key and one nonce leak
the difference between them, and let somebody forge a tag. A random 12-byte nonce per seal keeps
the chance of a repeat negligible for any number of writes a phone will make. And `grep` found
`spanish` on three lines of `data.ts` and on none of `sessions.enc`.

Now change one bit of the sealed file, seal a good copy again, then take away the key-encryption
key:

```
ana@dev:~/planner/crypt$ node -e "const fs = require('fs'); const b = fs.readFileSync('sessions.enc'); b[40] ^= 1; fs.writeFileSync('sessions.enc', b)"
ana@dev:~/planner/crypt$ node crypt.ts open
refused: Unsupported state or unable to authenticate data
ana@dev:~/planner/crypt$ node crypt.ts seal
sealed 6 sessions into 493 bytes; same bytes as the last seal: no
ana@dev:~/planner/crypt$ mv kek.bin kek.away
ana@dev:~/planner/crypt$ node crypt.ts open
refused: ENOENT: no such file or directory, open 'kek.bin'
ana@dev:~/planner/crypt$ mv kek.away kek.bin
ana@dev:~/planner/crypt$ node crypt.ts open
opened 6 sessions; the first is s1, spanish, 2026-10-19
```

**One bit, and the whole file was refused.** GCM's tag covers every byte, so a file corrupted by a
bad sector and a file altered on purpose fail the same way, and neither is ever decrypted into
something plausible and wrong. Without the key-encryption key nothing opens at all, which is what
happens after a phone is reset, and after a backup restored to another phone when the key was
`ThisDeviceOnly`. **The planner must expect that**: a data file it cannot open is treated as no
data, and the full resync of lesson 12 brings the sessions back from the server. A session that was
only on the old phone is gone, which is the outbox's argument for sending it soon.

## A whole database: SQLCipher

Sealing one JSON file is right for a small secret. For the planner's whole database, apps use
**SQLCipher**, a build of SQLite that encrypts every page with AES-256, opened with a key the app
unwraps exactly as above. Android uses it through `net.zetetic:sqlcipher-android`, iOS through
SQLCipher's package, React Native through `op-sqlite` with its SQLCipher option. *None of those was
run for this course; they are named from their own documentation.*
