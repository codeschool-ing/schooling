---
title: Forward secrecy, or what a stolen key opens
version: 1
---

**Forward secrecy means that stealing a server's long-term private key today does not decrypt the
traffic it exchanged yesterday.** It comes from agreeing every session key with a fresh exchange
whose secrets are thrown away when the session ends. It is the reason TLS 1.3 removed the other way
of getting a key to a server.

## The other way, and its long memory

Lesson 3 delivered a session key by encrypting it with the recipient's RSA public key. TLS 1.2
allowed exactly that, as *RSA key transport*: the browser chose the session key and sent it
encrypted to the server's certificate key. Here it is in the lab: a session key is wrapped for the
records service, and a letter is encrypted with it. Both files are what somebody recording the
network would have kept:

```
ana@lab:~/lab$ xxd -r -p keys/aes-256-b.hex | openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -out recorded.rsa; vcrypt seal --key keys/aes-256-b.hex --nonce 0000000000000000000000c7 data/referral.txt recorded.gcm
sealed data/referral.txt: 12-byte nonce + 170 bytes of ciphertext + 16-byte tag -> recorded.gcm
```

A year later, the service's private key leaks, from a backup, a decommissioned disk or a breach.
Whoever kept the recording now unwraps the session key and reads the letter:

```
ana@lab:~/lab$ openssl pkeyutl -decrypt -inkey keys/rsa-3072.key -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in recorded.rsa | xxd -p -c 32 > leaked.hex; vcrypt open --key leaked.hex recorded.gcm | head -1
Referral 2026-0417. Patient: Marina Duarte, 41.
```

Nothing about the recording had to be broken. **Every session that ever used that key is readable by
whoever holds it**, for as long as the recordings exist. Organisations and intelligence services do
record encrypted traffic they cannot read yet, which is why this matters even when no key has leaked.

## The fresh exchange

With an **ephemeral** exchange, both sides generate a new X25519 pair for this session only, agree a
secret, derive keys, and discard the private halves. `vcrypt ephemeral` does exactly that, with
fresh random keys rather than labels, so it prints only what is the same on every run:

```py
# ~/lab/tools/ephemeral.py
"""vcrypt ephemeral: two X25519 key pairs made in memory for one exchange,
used once, and dropped. Fresh random keys every run, so it prints only what
does not change."""
from cryptography.hazmat.primitives.asymmetric import x25519

ana, bruno = x25519.X25519PrivateKey.generate(), x25519.X25519PrivateKey.generate()
s1 = ana.exchange(bruno.public_key())
s2 = bruno.exchange(ana.public_key())
print("ephemeral pairs generated for this exchange: 2, written to disk: 0")
print(f"both sides derived the same {len(s1)}-byte secret: {'yes' if s1 == s2 else 'no'}")
del ana, bruno
print("private halves discarded; nothing left that could rebuild this secret")
```


```
ana@lab:~/lab$ vcrypt ephemeral
ephemeral pairs generated for this exchange: 2, written to disk: 0
both sides derived the same 32-byte secret: yes
private halves discarded; nothing left that could rebuild this secret
```

The server's long-term key still has a job, which section 05 explains: it **signs** the exchange to
prove who the server is. But it never encrypts the session key and is never needed to recover it.
Leak it a year later and the recording holds two public values whose private halves no longer exist
anywhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two rows over a timeline: the session in 2026, then the server&#x27;s key leaking in 2027. Top row, RSA key transport: the session key was encrypted to the server&#x27;s long-term key, so the 2027 leak opens the recorded session. Bottom row, ephemeral exchange: the session key came from X25519 pairs deleted at the end of the session, so the 2027 leak opens nothing.\"><defs><marker id=\"fs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"fs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"140\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2026: the session, recorded</text><text x=\"520\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2027: the server&#x27;s key leaks</text><rect x=\"20\" y=\"40\" width=\"240\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">RSA key transport</text><text x=\"36\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">session key encrypted to the server key</text><rect x=\"400\" y=\"40\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">recording opened</text><text x=\"416\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">leaked key unwraps the session key</text><polyline points=\"262,75 398,75\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#fs-ah-amber)\"></polyline><rect x=\"20\" y=\"130\" width=\"240\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ephemeral X25519</text><text x=\"36\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exchange keys deleted after use</text><rect x=\"400\" y=\"130\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">recording stays closed</text><text x=\"416\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the leaked key only ever signed</text><polyline points=\"262,165 398,165\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#fs-ah-wire)\"></polyline></svg>", "caption": "The same leak, a year later, against the two ways of getting a session key."}
```

## In the protocols

- **TLS 1.3** offers only ephemeral exchanges (ECDHE or DHE). RSA key transport was removed, and so
  forward secrecy is no longer a configuration choice.
- **TLS 1.2** still allows RSA key transport. A server that still accepts TLS 1.2 should offer only
  the `ECDHE` cipher suites, the ones whose names begin `TLS_ECDHE_`; lesson 10 checks a server for
  this.
- **SSH** has always used an ephemeral exchange for each connection.
- **Signal** goes further and runs a new exchange for nearly every message, so that even a phone
  seized mid-conversation does not open past messages.

Forward secrecy protects the past, not the present: whoever holds the server's key **now** can
impersonate the server to new visitors. That is what revocation, in lesson 9, is for.
