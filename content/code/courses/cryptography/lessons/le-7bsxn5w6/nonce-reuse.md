---
title: A nonce used twice
version: 1
---

**A nonce has one requirement: under a given key, it never appears twice. It does not have to be
secret or random, only unique. Break that once and AES-GCM loses both of the properties lesson 1
built it for.** The mistake is rarely a programmer typing the same number twice. It is a counter that
went backwards.

## What one repeat costs

Lesson 1 described GCM as counter mode plus a tag. Counter mode turns the key and the nonce into a
keystream and XORs it with the message, so two messages sealed with the same key and nonce were XORed
with the **same keystream**. Their ciphertexts, combined, cancel the keystream and leave the two
plaintexts combined with each other, and from that much of both can usually be read, especially when
the records follow a known format. The tag suffers too: a repeated nonce exposes the value GCM
computes its tags with, after which messages nobody sealed can pass the check.

That is why the response is never "decrypt and look". The key is treated as compromised for every file
sealed under it, and the course of action is the same however few files collided.

## How a counter goes back

Vereda's agenda export seals one file a day with `keys/aes-256.hex`, taking the nonce from a counter
kept in a small state file. On 8 June the export server was restored from the backup of 4 June after
a disk failure, state file included, and the counter carried on from 5 as if the last three days had
not happened. Nothing failed and nothing was logged. Every file opened correctly afterwards, because
opening a file never checks whether its nonce was used elsewhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Fourteen days of the agenda export, 1 to 14 June, each sealed with a nonce from a counter. Days 1 to 7 use nonces 1 to 7. On 8 June the server is restored from the backup of 4 June and the counter goes back to 5, so days 8, 9 and 10 use nonces 5, 6 and 7 again, drawn in red with lines to the earlier days that used them. Days 11 to 14 use nonces 8 to 11.\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">June</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nonce</text><text x=\"89\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"70\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"135\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"116\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><text x=\"181\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"162\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"181\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><text x=\"227\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"208\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"227\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"273\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"254\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"273\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"319\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"300\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"319\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"365\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><rect x=\"346\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"365\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><text x=\"411\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><rect x=\"392\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"411\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">5</text><text x=\"457\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9</text><rect x=\"438\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"457\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">6</text><text x=\"503\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><rect x=\"484\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"503\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">7</text><text x=\"549\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11</text><rect x=\"530\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"549\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><text x=\"595\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><rect x=\"576\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9</text><text x=\"641\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13</text><rect x=\"622\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"641\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><text x=\"687\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><rect x=\"668\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"687\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11</text><polyline points=\"273,134 273,150 411,150 411,134\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></polyline><polyline points=\"319,134 319,162 457,162 457,134\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></polyline><polyline points=\"365,134 365,174 503,174 503,134\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></polyline><polyline points=\"388,40 388,186\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><text x=\"396\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">8 June: restored from the 4 June backup</text></svg>", "caption": "One restore, three repeated nonces, and no error anywhere. Red: a nonce used for the second time."}
```

## Finding it

The nonce is stored in clear at the front of every sealed file, so detecting a repeat needs no key and
decrypts nothing. `vcrypt nonce-audit` reads the first twelve bytes of each file and reports any value
that appears more than once:

```
ana@lab:~/lab$ ls export | head -3; ls export | wc -l
agenda-06-01.gcm
agenda-06-02.gcm
agenda-06-03.gcm
14
ana@lab:~/lab$ vcrypt nonce-audit export/*.gcm; echo "exit status $?"
14 sealed files, 11 different nonces
nonce 000000000000000000000005 used 2 times: export/agenda-06-05.gcm export/agenda-06-08.gcm
nonce 000000000000000000000006 used 2 times: export/agenda-06-06.gcm export/agenda-06-09.gcm
nonce 000000000000000000000007 used 2 times: export/agenda-06-07.gcm export/agenda-06-10.gcm
3 nonces repeated: if these files share a key, rotate it and re-seal them
exit status 1
```

The exit status of 1 lets the audit run as a scheduled check that alerts. It found the three days the
restore repeated. The same check is worth running over any store of sealed records, and a
database column of nonces with a unique index on it does the same job continuously, and refuses the
second insert at the moment it happens.

## Fixing it

1. **Generate a new key**, and re-seal every file from the old one under it, with fresh nonces. The old
   key is then retired, because the repeated files were sealed with it.
2. **Stop keeping the nonce in state that a restore can rewind.** For a few files a day, the simplest
   sound choice is a random 96-bit nonce from the operating system for every message, which is what
   `os.urandom(12)` gave the example in the last section. Random 96-bit nonces are safe for up to about
   four billion messages per key, the limit NIST sets for GCM.
3. **Where that limit is too close**, use a construction made for it: XChaCha20-Poly1305, whose 192-bit
   nonce can be random for any realistic volume, or AES-GCM-SIV, which lesson 1 described as failing
   gently when a nonce repeats.

In the lab, the first step and an audit of the result:

```
ana@lab:~/lab$ openssl rand -hex 32 > keys/agenda-2.hex
ana@lab:~/lab$ for f in export/*.gcm; do vcrypt open --key keys/aes-256.hex $f | vcrypt seal --key keys/agenda-2.hex --nonce $(openssl rand -hex 12) - ${f%.gcm}.v2 >/dev/null; done
ana@lab:~/lab$ vcrypt nonce-audit export/*.v2
14 sealed files, 14 different nonces
no nonce repeated
```

The `--nonce` option of `vcrypt seal` exists so that the lab's files come out the same on every
machine. It is a teaching device, and an interface that asks its caller for a nonce is exactly the
kind of interface that produces this mistake. The library interfaces section 03 recommended either
pick the nonce themselves or make picking a fresh one the only easy path.
