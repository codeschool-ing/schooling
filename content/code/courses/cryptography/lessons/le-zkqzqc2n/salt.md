---
title: A salt per account
version: 1
---

**A salt is a random value, different for every account, mixed into the password before hashing
and stored beside the result.** It is not secret. Its whole job is to make the same password give a
different stored value in every account, and in every system.

## The same store, salted

The eight accounts again, now stored as SHA-256 of a 16-byte salt followed by the password. Each
line carries the scheme, the salt in Base64, and the digest, separated by `$`:

```
ana@lab:~/lab$ vcrypt store salted-sha256 data/users.csv > store-salted.txt; head -3 store-salted.txt
ana.lima:sha256$0/nfYBQd1s+OH9g42kQLEg$cefd1b667bdaf806ce088a7a42ea0a13400e51d4bb2572239bc9ddadd5a3877c
bruno.reis:sha256$qEu3wpXcXcqDBA7Q2eSpmQ$da4cfbd05bd39f57f8564ab7168d6ab31a75a92c38068f7a2b5234cd398668d2
carla.souza:sha256$kQnk8qVcKObWWJG4rA4n3w$b6bb275d982eaac82714b707ee5a4656105871b6b3e1033ba3c5f5509218a389
```

Ana and Carla chose the same password, and their stored values have nothing in common. The audit
that found two groups in the previous section finds none:

```
ana@lab:~/lab$ vcrypt audit store-salted.txt
8 accounts, 8 different stored values
  no two accounts share a stored value
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Two panels. Without salt: one precomputed list of digests of common passwords matches Ana, Carla and Fabio at once, because their stored values are identical. With salt: each account&#x27;s value mixes in its own salt, so the same password gives three unrelated values, and no list computed in advance matches any of them; each account must be attacked on its own.\"><defs><marker id=\"salt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">without salt</text><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">with a salt per account</text><rect x=\"20\" y=\"36\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">precomputed list</text><text x=\"95\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">of common passwords</text><rect x=\"200\" y=\"120\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ana.lima: 9df1…</text><polyline points=\"170,80 198,135\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#salt-ah-amber)\"></polyline><rect x=\"200\" y=\"160\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">carla.souza: 9df1…</text><polyline points=\"170,80 198,175\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#salt-ah-amber)\"></polyline><rect x=\"200\" y=\"200\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fabio.nunes: 9df1…</text><polyline points=\"170,80 198,215\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#salt-ah-amber)\"></polyline><rect x=\"400\" y=\"120\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ana.lima: cefd…</text><text x=\"590\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">own salt</text><rect x=\"400\" y=\"160\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">carla.souza: b6bb…</text><text x=\"590\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">own salt</text><rect x=\"400\" y=\"200\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fabio.nunes: 0244…</text><text x=\"590\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">own salt</text><rect x=\"380\" y=\"36\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"455\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">precomputed list</text><text x=\"455\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">matches nothing</text><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">same password, same value: one lookup finds three accounts</text></svg>", "caption": "A salt turns one lookup against the whole store into separate work for every account."}
```

## What the salt defeats, and what it does not

The salt removes the first two problems of the previous section:

- **equal passwords are no longer visible**, because each account's salt differs;
- **precomputed lists stop working**, because a list would have to be computed for every possible
  salt, and with 16 random bytes there are 2¹²⁸ of them. An attacker must now start from zero for
  every account, with that account's salt.

It does nothing about the third. Salted SHA-256 is exactly as fast as plain SHA-256, so once an
attacker picks one account, they can still try billions of candidates a second against it. The salt
turns one attack on the whole store into eight separate attacks; it does not make any one of them
slower.

## How a salt is chosen

- **Random**, from the system's cryptographic generator, at the moment the password is stored. The
  lab derives its salts from labels so that the transcripts repeat; that is the same convenience as
  the fixed IVs of lesson 1, and the same thing a real system must never do.
- **New on every change of password**, not one per user forever. A salt reused across a user's
  passwords would show when somebody went back to an old one.
- **Long enough to be unique**: 16 bytes is the usual size, and every library default reaches it.
- **Stored beside the hash**, in the same field, as above. It is needed to verify, and hiding it
  adds nothing.

In practice you never handle a salt yourself. bcrypt and Argon2id, the subject of the next section,
generate one and write it into the stored string for you. A design that asks you to manage salts by
hand is a sign of an older scheme.
