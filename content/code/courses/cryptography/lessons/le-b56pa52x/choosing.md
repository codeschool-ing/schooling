---
title: Using a hash for the job it does
version: 1
---

**A hash answers one question well: is this the same bytes as that?** Used for that, it is one of
the most reliable tools in the course. The mistakes come from asking it other questions, such as
"who sent this?" or "is this password right?", that it was never built to answer.

## Checking a download

Vereda's portal release ships with a `SHA256SUMS` file, the convention most Linux distributions and
open-source projects follow: one line per file, the digest and the name.

```
ana@lab:~/lab$ cd data/release && cat SHA256SUMS
d166d210e0c958cff1ac86e2119274eced40fe304a2cc7762953ad0058e54d7e  NOTES.txt
7a3cfae88053ea853e98e2211769a0cf9f605d6f761aff2878059628177a6a3f  portal-2.4.1.tar
ana@lab:~/lab$ cd data/release && sha256sum -c SHA256SUMS
NOTES.txt: OK
portal-2.4.1.tar: OK
```

`sha256sum -c` recomputes each digest and compares. Now one byte is appended to the archive, the
size of a transfer that went wrong or a file somebody tampered with:

```
ana@lab:~/lab$ cd data/release && printf x >> portal-2.4.1.tar && sha256sum -c SHA256SUMS; echo "exit status $?"
NOTES.txt: OK
portal-2.4.1.tar: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
exit status 1
```

The exit status is 1, which is what a script or a deployment pipeline checks. A pipeline that
downloads something and installs it should refuse at this line, not log a warning and carry on.

## What the check proves, and what it does not

A matching digest proves the file is **the same bytes as the file the digest was computed from**.
It proves nothing about who computed the digest. If an attacker controls the server that hosts
both the archive and `SHA256SUMS`, they replace both, and the check passes. So:

- a digest **on the same server** as the file catches corruption and nothing else;
- a digest obtained **through a different channel**, such as a release announcement, a package
  manager's signed index or a colleague reading it out, catches tampering on the download server;
- a digest **signed** by the publisher's key (`SHA256SUMS.asc` with OpenPGP, or a Sigstore bundle)
  proves who vouches for the file, which is lesson 3's signature applied to lesson 4's fingerprint.

## Naming things by their content

A digest is a name that cannot lie about its content, and several systems use it that way:

- **Git** names every commit, tree and file by its hash. A commit id identifies the exact content of
  the whole history behind it;
- **container images** are pulled by tag, `portal:2.4.1`, which the registry may move, or by digest,
  `portal@sha256:…`, which nobody can move. Deployments pin the digest;
- **package lock files** (`package-lock.json`, `go.sum`, `poetry.lock`) store a digest per dependency,
  so the build refuses a dependency whose content changed under the same version number.

In each case, the hash being collision-resistant is what makes the name trustworthy, which is why
Git's move away from SHA-1 matters.

## The questions a hash is not for

| question | not a plain hash, because | use instead |
|---|---|---|
| is this password right? | a fast hash lets an attacker try billions of guesses a second | a slow, salted KDF, lesson 5 |
| did somebody who knows our secret send this? | anybody can compute a hash | HMAC, lesson 6 |
| who wrote this? | a hash has no key | a signature, lesson 3 |
| can I hide this value by hashing it? | a short or predictable value is found by trying candidates | encryption, or a keyed hash |

The last row catches people often. Hashing a CPF, a phone number or an e-mail address does not
anonymise it: there are only about a billion valid CPFs, and hashing all of them takes minutes on a
laptop. A hashed identifier is still personal data, and the LGPD treats it as such.
