---
title: bcrypt
version: 1
---

**bcrypt is the oldest of the three, from 1999, and it was designed from the start to be made
slower as computers get faster.** It has one setting, the **cost**, and it writes everything it needs to check a password
later into the string it returns.

```
ana@api:~/shelf$ python3 -c 'import bcrypt; print(bcrypt.hashpw(b"correct horse battery staple", bcrypt.gensalt(12)).decode())'
$2b$12$bxn1iU7qxqWf6kP97SJxK.5XHQsQk1G1YXILs7rJqQnOs8xPZz1p.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 170\" role=\"img\" aria-label=\"The bcrypt string $2b$12$bxn1iU7qxqWf6kP97SJxK.5XHQsQk1G1YXILs7rJqQnOs8xPZz1p. cut into four fields: $2b$ names the algorithm and its version, 12$ is the cost, the next 22 characters are the salt and the last 31 are the hash.\"><rect x=\"30\" y=\"40\" width=\"112\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"86.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$2b$</text><line x1=\"86.0\" y1=\"74\" x2=\"86.0\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"86.0\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">algorithm</text><text x=\"86.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">bcrypt, version 2b</text><rect x=\"148\" y=\"40\" width=\"112\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"204.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12$</text><line x1=\"204.0\" y1=\"74\" x2=\"204.0\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"204.0\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cost</text><text x=\"204.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2^12 rounds</text><rect x=\"266\" y=\"40\" width=\"159.2\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"345.6\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bxn1iU7qxqWf6kP97SJxK.</text><line x1=\"345.6\" y1=\"74\" x2=\"345.6\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"345.6\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">salt</text><text x=\"345.6\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">22 characters, 16 bytes</text><rect x=\"431.2\" y=\"40\" width=\"218.6\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"540.5\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5XHQsQk1G1YXILs7rJqQnOs8xPZz1p.</text><line x1=\"540.5\" y1=\"74\" x2=\"540.5\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"540.5\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash</text><text x=\"540.5\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">31 characters, 23 bytes</text></svg>", "caption": "Everything verify needs is in the one string: the version, the cost and the salt travel with the hash."}
```

That one string is what a database stores, in one text column. Verifying a password reads the cost
and the salt out of it, hashes what was typed with them, and compares; nothing about the settings
has to be stored anywhere else. Python's `bcrypt.gensalt()` chose cost 12 when it was given no
number, which is the `$2b$12$` in both strings of the section on salt.

## The cost doubles the time

The cost is an exponent: bcrypt runs its expensive step 2^cost times, so **one more is twice the
work**. The three bcrypt rows of `hashrate.py` show it: 62.651 ms a hash at cost 10, 127.267 at 11,
256.682 at 12. OWASP's Password Storage Cheat Sheet asks for a cost of at least 10, and as high as
the server's verification time allows. Because the cost sits in each stored string, raising it later
changes only the new hashes, and the old ones still verify with the cost they were made with.

## The 72-byte limit

bcrypt reads at most **72 bytes** of the password and ignores the rest. Python's bcrypt 3.2.2, the
one Ubuntu 24.04 packages, does that without a word. Two passwords that agree on their first 72 bytes
and differ after them:

```
ana@api:~/shelf$ python3 -c 'import bcrypt; h = bcrypt.hashpw(b"a" * 72 + b"X", bcrypt.gensalt()); print(bcrypt.checkpw(b"a" * 72 + b"Y", h))'
True
```

`True`: a password ending in `Y` was accepted against a hash of one ending in `X`. Anything a user
types after the 72nd byte protects nothing.

The usual reading is that this is 72 characters, which is long enough for anybody. It is 72
**bytes**, and in UTF-8 a letter with an accent takes two:

```
ana@api:~/shelf$ python3 -c 'p = "canção"; print(len(p), len(p.encode()))'
6 8
```

A passphrase in Portuguese reaches the limit well before 72 letters, and the passphrase is exactly
what the rules at the end of this lesson encourage. Three ways out, from OWASP's sheet:

| choice | what it means |
|---|---|
| refuse passwords over 72 bytes | say so at registration, and count bytes, not characters |
| pre-hash with HMAC and a secret key, then base64 | the sheet's formula is `bcrypt(base64(hmac-sha384(password, pepper)))`; plain SHA-256 first is not safe |
| use Argon2id for anything new | it has no such limit |

The last one, on the same pair of passwords:

```
ana@api:~/shelf$ python3 -c 'from argon2 import PasswordHasher; ph = PasswordHasher(); h = ph.hash("a" * 72 + "X"); print(ph.verify(h, "a" * 72 + "Y"))'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/lib/python3/dist-packages/argon2/_password_hasher.py", line 188, in verify
    return verify_secret(
           ^^^^^^^^^^^^^^
  File "/usr/lib/python3/dist-packages/argon2/low_level.py", line 206, in verify_secret
    raise VerifyMismatchError(error_to_str(rv))
argon2.exceptions.VerifyMismatchError: The password does not match the supplied hash
```

Argon2id refuses the second password, which is right. The error is the library's way of saying "no
match"; `passwords.py`, at the end of this lesson, catches it and turns it into a failed login.

**bcrypt is not memory-hard.** Its working state is a few kilobytes, so hardware that runs many
guesses at once has no trouble fitting them. That, and the 72 bytes, is why OWASP's sheet keeps it
for systems that already use it, and recommends Argon2id for everything else.
