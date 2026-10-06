---
title: Functions built to be slow: PBKDF2, bcrypt and Argon2id
version: 1
---

**A password hashing function is a key derivation function made deliberately expensive, with the
expense set by a parameter.** Verifying one password at sign-in can take a quarter of a second and
nobody notices. An attacker who has to pay that quarter of a second for every guess is held to a
few guesses a second per processor core instead of billions.

## Three generations

The same accounts, stored with each of the three functions in use today:

```
ana@lab:~/lab$ vcrypt store pbkdf2 data/users.csv > store-pbkdf2.txt; head -1 store-pbkdf2.txt
ana.lima:pbkdf2-sha256$600000$Y4EQQZxYKFu48z/W4kMoJA$LYyvtlwg1k0omO8QxI9lQqXZTn6lmzxBIOlFHHd9KlA
ana@lab:~/lab$ vcrypt store bcrypt data/users.csv > store-bcrypt.txt; head -1 store-bcrypt.txt
ana.lima:$2b$12$KH4JXJSw706kRRwsTOcP4ucIrNKVCxYXbzzr2G6VMceO8RCZpem9u
ana@lab:~/lab$ vcrypt store argon2id data/users.csv > store-argon2.txt; head -1 store-argon2.txt
ana.lima:$argon2id$v=19$m=19456,t=2,p=1$FuRufmOK/RUsaLq6VND23g$oxCtde9brxDZYJOg4ii5u7zqa2dwZ4354f5oFjT5qxc
```

Each line is self-describing: it names the algorithm, the cost it was computed with, the salt and
the result. That is why the parameters live **beside** the hash and never only in the code: raise
the cost tomorrow and every old hash still says how to verify it. Reading the three:

| stored string | algorithm | cost parameters | salt |
|---|---|---|---|
| `pbkdf2-sha256$600000$…` | PBKDF2 with HMAC-SHA-256 | 600,000 iterations | 16 bytes |
| `$2b$12$…` | bcrypt | cost 12, which means 2¹² rounds of its key setup | 16 bytes |
| `$argon2id$v=19$m=19456,t=2,p=1$…` | Argon2id, version 1.3 | 19,456 KiB of memory, 2 passes, 1 lane | 16 bytes |

The audit of the Argon2id store finds no shared value, because each line carries its own salt:

```
ana@lab:~/lab$ vcrypt audit store-argon2.txt
8 accounts, 8 different stored values
  no two accounts share a stored value
```

## What each one adds

**PBKDF2** (2000) repeats an HMAC many times. It is simple, it is in every standard library, and it
is the one compliance frameworks such as FIPS 140 accept. Its weakness is that each iteration
needs almost no memory, so GPUs and custom chips run thousands of guesses in parallel cheaply.
OWASP's current figure for PBKDF2-HMAC-SHA256 is 600,000 iterations, which is what the lab uses.

**bcrypt** (1999) uses a key setup that needs a small amount of memory, which slowed GPUs more than
PBKDF2 did. It has served well for 25 years. Two limits to know: it **ignores everything after the
72nd byte** of a password, and its cost only grows in doubling steps. Cost 10 is the minimum anybody
recommends today, and 12 is common.

**Argon2id** (2015) won the Password Hashing Competition and is RFC 9106. It is **memory-hard**: each
guess must fill and revisit a block of memory, here 19 MiB, and memory is what GPUs and custom chips
cannot cheaply multiply. Its three parameters trade memory, passes and parallelism. OWASP's
minimum, used in the lab, is 19 MiB with 2 passes; RFC 9106 recommends 64 MiB with 3 passes, or 2
GiB with 1 pass where the server can afford it.

## Choosing, today

- **New systems: Argon2id**, with the largest memory cost the sign-in server can afford under load.
- **FIPS-bound systems: PBKDF2-HMAC-SHA256** at 600,000 iterations or more.
- **Existing bcrypt: keep it**, at cost 10 or more, and plan the move with the upgrade path of
  section 06.
- **Never** a plain or salted fast hash, and never an algorithm somebody invented for the purpose.

A quarter of a second is a budget, not a law. The cost is set by measuring the sign-in server: pick
the largest parameters that keep one verification under the time you are willing to make a user
wait, and remember that an attacker sending many sign-in attempts can use that cost against the
server, which is one reason sign-in is also rate-limited.
