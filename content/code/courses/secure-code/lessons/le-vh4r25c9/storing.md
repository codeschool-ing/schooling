---
title: Storing a password so a leak is worth little
version: 1
---

Every design decision about stored passwords starts from one assumption: **one day the table leaks.**
A backup left readable, a laptop with a copy of the database, a query in the console that returned
more columns than anybody meant. You do not plan for it to happen; you plan for what the copy is
worth when it does.

The wrong idea comes first, and it sounds responsible: *encrypt the passwords.* Encryption is
reversible by design. Whoever has the key reads every password back, and the key lives on the same
servers that hold the table, so it tends to leak with it. **A password is never stored in a form
anybody can turn back into the password**, including the portal itself. The portal does not need
the password back; it only needs to check, at sign-in, that the one typed now is the one chosen
then.

### Three tables, one leak

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l11-leak\" aria-label=\"The same two rows of the password table, as a leaked copy would show them, stored three ways. Plain text: lucia and rafael both show lilac river morning tea, readable at once. A fast hash without salt, SHA-256: both rows show the same hexadecimal string, so equal passwords are visible, and a graphics card tests billions of guesses a second. Argon2id with a salt: the two rows are different strings, each guess costs tens of milliseconds and 64 MiB of memory, and has to be repeated for each patient.\"><text x=\"126\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">plain text</text><rect x=\"20\" y=\"40\" width=\"212\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lucia</text><text x=\"32\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lilac river morning tea</text><text x=\"32\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rafael</text><text x=\"32\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lilac river morning tea</text><text x=\"126\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">readable at once</text><text x=\"358\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">SHA-256, no salt</text><rect x=\"252\" y=\"40\" width=\"212\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"264\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lucia</text><text x=\"264\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">e57256…fa0c</text><text x=\"264\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rafael</text><text x=\"264\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">e57256…fa0c</text><text x=\"358\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">billions of guesses a second</text><text x=\"590\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Argon2id, salted</text><rect x=\"484\" y=\"40\" width=\"212\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"496\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lucia</text><text x=\"496\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$argon2id$…$Qm3x…</text><text x=\"496\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rafael</text><text x=\"496\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$argon2id$…$Zr8k…</text><text x=\"590\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">each guess: ms and MiB, per patient</text><text x=\"358\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">equal rows: equal passwords</text></svg>", "caption": "What a leaked copy is worth depends only on how the column was written."}
```

**Plain text** is the obvious failure. The second is the one that ships, because it looks like the
fix: a **fast hash** such as SHA-256. It is one-way, and the hex string looks like nothing. But
an attacker with the table does not reverse it. They **guess**: hash a candidate, compare, next.
SHA-256 is designed to be fast, and a single graphics card computes billions of them a second, so
every password a person would choose falls in hours. Without a **salt**, it is worse: two patients
with the same password have the same hash, and one guess cracks both.

The third table is what this lesson builds. A **password hashing function** is built to be slow
and to use memory on purpose, and it mixes a random **salt**, different for each password, into
the hash:

- **The salt** makes every stored value unique. Equal passwords no longer show as equal rows, and
  a guess has to be computed again for each patient.
- **The cost** makes each guess expensive. Argon2id, the function this lesson uses, takes tens of
  milliseconds and 64 MiB of memory per hash with its default settings. A patient signing in never
  notices; somebody trying a billion candidates notices a great deal, and the memory requirement
  is what stops a graphics card from running thousands of guesses side by side.

Three functions are recommended for this today: **Argon2id**, **scrypt** and **bcrypt**, in the
order OWASP's Password Storage Cheat Sheet lists them. A fourth, PBKDF2, is the one to use where a
FIPS-140 validated implementation is required. MD5, SHA-1 and SHA-256 are hash functions, and good
ones, for other jobs; none of them is a password hashing function.

### What the hash does not do

A slow hash protects passwords **after** a leak. It does nothing for a password that was weak to
begin with, which the first guesses will find whatever the cost, and nothing for a password a
patient also used on another site that leaked. That half belongs to the policy, in the fourth
section. And it does not stop somebody guessing **online**, through the sign-in form: that is a
rate limit, a lockout that slows rather than blocks, and a second factor.
