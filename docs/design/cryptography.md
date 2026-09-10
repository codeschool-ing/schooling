---
format: 5
course: cryptography
---

# cryptography

**Applied Cryptography** · `co-kpvxd800` · 50 h declared · intermediate · 17 lessons · `security` · paid

## Reach

In **3 tracks** — `dba`(13), `devsecops`(6), `security`(5).

**Depends on it:** `attacks-threats`

## Assumes, and leaves ready

**Assumes:** `security-fundamentals` — risk, confidentiality and integrity as ideas, before the mathematics that delivers them.

**Leaves ready:** keys, hashes, certificates and TLS, for `attacks-threats`. **The only prerequisite edge out of it, and the whole category is downstream of that one edge.**

## Shape

| | |
|---|---|
| declared hours | 50 h |
| lessons | 17 |
| **hours per lesson** | **2.94** |
| section budget | ~107, about 6.3 a lesson |
| exercises | ~500, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a language with a crypto library** — light, and the course works degraded without it |
| browser · database | no · no |
| exercises **blocked** | **~150 (30%)** — the lowest in the category |
| exercises that would **improve** | ~200 |
| diagrams to draw | ~65 — a block cipher mode, the Diffie-Hellman exchange, a certificate chain, the TLS handshake drawn message by message, a salt defeating a rainbow table |

## Ageing

**Low, with a slow clock underneath.** Lesson 4 is why MD5 and SHA-1 fell, which is history; the algorithms currently recommended will themselves be superseded, and post-quantum is the change this course will need and does not yet name.

## Flags

**1 ·** **The most gradeable course in the category, and it is not obvious from the subject.** Which key encrypts and which verifies, ordering the TLS handshake, matching an algorithm to its weakness, computing a key size — `quiz`, `matching`, `ordering` and `numeric` on their natural material. Lesson 11 (*"why neither obfuscation nor encoding is encryption"*) is a `quiz` that catches a real misconception.

**2 ·** **Lesson 17 is the course's point and comes last.** Keys in the code, rolling your own algorithm, nonce reuse — the three mistakes that actually happen, after sixteen lessons of the theory that explains why they are fatal. **The design instruction is not to move it earlier**: it only lands once the reader knows what a nonce is for.

**3 ·** **It does not yet name post-quantum, and that is the one gap worth recording now.** NIST selected its first standards in 2024 and migration is a live programme in exactly the organisations this course serves. Adding it later is a minor release under `C-22`; noticing it now costs nothing.
