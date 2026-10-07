---
title: Real systems combine both kinds of key
version: 1
---

**Every practical system encrypts data with a symmetric key and uses asymmetric cryptography only
to get that key to the right place.** RSA cannot encrypt more than a few hundred bytes and is slow;
AES encrypts anything quickly but needs both sides to hold the same key. Together they cover each
other's gap, and the combination is called **hybrid encryption**.

## Sending the appointment file to the records service

The appointment file is too large for RSA, as the first section of this lesson showed. Ana sends it
anyway, in three steps.

**First, encrypt the data with a fresh symmetric key.** The lab's `aes-256-b.hex` plays the part
of a key generated for this one message, the *session key*:

```
ana@lab:~/lab$ vcrypt seal --key keys/aes-256-b.hex --nonce 0000000000000000000000a1 data/slots.dat slots.gcm
sealed data/slots.dat: 12-byte nonce + 512 bytes of ciphertext + 16-byte tag -> slots.gcm
```

**Second, encrypt the session key with the recipient's public key.** The key is 32 bytes, well
under RSA's limit:

```
ana@lab:~/lab$ xxd -r -p keys/aes-256-b.hex > session.key; wc -c session.key
32 session.key
ana@lab:~/lab$ openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in session.key -out session.rsa; rm session.key
```

The plaintext copy of the key is deleted. What travels is two files:

```
ana@lab:~/lab$ wc -c slots.gcm session.rsa
540 slots.gcm
384 session.rsa
924 total
```

540 bytes of data encrypted with AES-GCM, and 384 bytes of RSA protecting the 32-byte key that
opens it. A 5-gigabyte file would still travel with the same 384 bytes of RSA beside it.

**Third, the recipient reverses it.** The service decrypts the session key with its private key,
then opens the data with the session key:

```
ana@lab:~/lab$ openssl pkeyutl -decrypt -inkey keys/rsa-3072.key -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in session.rsa | xxd -p -c 32 > recovered.hex
ana@lab:~/lab$ vcrypt open --key recovered.hex slots.gcm | head -2
room1 free     
room1 BOOKED   
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Hybrid encryption in three steps. Ana encrypts the 512-byte appointment file with a fresh 32-byte session key using AES-GCM, giving 540 bytes. She encrypts the session key with the records service&#x27;s RSA public key, giving 384 bytes. Both travel. The service decrypts the session key with its private key and then opens the file with it.\"><defs><marker id=\"hyb-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hyb-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"hyb-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ana</text><text x=\"560\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">records service</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">slots.dat, 512</text><rect x=\"20\" y=\"140\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">session key, 32</text><polyline points=\"170,60 268,60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#hyb-ah-wire)\"></polyline><text x=\"220\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AES-GCM</text><polyline points=\"95,140 95,92 268,70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#hyb-ah-amber)\"></polyline><polyline points=\"170,160 268,160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hyb-ah-phosphor)\"></polyline><text x=\"220\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">RSA pub</text><rect x=\"270\" y=\"40\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">slots.gcm, 540</text><rect x=\"270\" y=\"140\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">session.rsa, 384</text><polyline points=\"440,160 538,160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hyb-ah-phosphor)\"></polyline><text x=\"490\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">RSA priv</text><rect x=\"540\" y=\"140\" width=\"160\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">session key</text><polyline points=\"620,140 620,92\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#hyb-ah-amber)\"></polyline><polyline points=\"440,60 538,60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#hyb-ah-wire)\"></polyline><rect x=\"540\" y=\"40\" width=\"160\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">slots.dat</text><text x=\"360\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">only the two middle boxes cross the network</text></svg>", "caption": "AES carries the data; RSA carries only the key."}
```

## Where you meet this

This is not a lab curiosity. It is the structure of nearly everything this course covers:

- **S/MIME and OpenPGP e-mail** encrypt the message with a session key and attach that key
  encrypted to each recipient's public key, once per recipient (lesson 13);
- **encrypted backups and disk images** with a recovery key do the same, so that the data key can be
  unwrapped by a key held elsewhere (lesson 14);
- **TLS** gets its session key differently, by an exchange rather than by encrypting it to the
  server's key, for a reason lesson 7 explains. But the outcome is the same: asymmetric
  cryptography to agree, AES or ChaCha20 to carry the data.

## Signing goes in as well

The hybrid scheme gives confidentiality. Nothing in it says the file came from Ana: anybody can
encrypt a session key to the service's public key. When both properties matter, Ana also **signs**
the data with her own private key, and the recipient checks that signature after decrypting. Most
formats that do both sign first and encrypt second, so that the signature is hidden along with
the content and an observer cannot tell who signed it.
