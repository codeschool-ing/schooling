---
title: scrypt
version: 1
---

**scrypt, from 2009, makes every hash fill a block of memory and read it back in an order that
depends on the password.** Time alone can be bought cheaply with more chips running side by side. Memory cannot,
because every guess in flight needs its own block, so scrypt is **memory-hard**: the cost of a guess
is time and memory together.

It has three parameters:

| | name | what it sets |
|---|---|---|
| `N` | cost | how many blocks, a power of two; doubling it doubles the memory and the time |
| `r` | block size | each block is `128 × r` bytes; `r=8` makes it 1024 |
| `p` | parallelism | how many independent runs, each needing the memory again in turn |

The memory one hash needs is `128 × r × N` bytes. OWASP's first setting, `N=2^17, r=8, p=1`, is
128 MiB. Python has scrypt in `hashlib`, and asking for that setting fails:

```
ana@api:~/shelf$ python3 -c 'import hashlib, os; print(hashlib.scrypt(b"correct horse battery staple", salt=os.urandom(16), n=2**17, r=8, p=1).hex())'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ValueError: [digital envelope routines] memory limit exceeded
```

That is OpenSSL refusing, and it is the memory-hardness made visible: its default ceiling for one
scrypt call is 32 MiB, far below what the setting needs. Raise it with `maxmem`, in bytes, and the
same call works; `dklen` is how many bytes of hash to return:

```
ana@api:~/shelf$ python3 -c 'import hashlib, os; print(hashlib.scrypt(b"correct horse battery staple", salt=os.urandom(16), n=2**17, r=8, p=1, maxmem=2**28, dklen=32).hex())'
15138593db714e1e35b06840f0e8aee87051114838f86079c91ac73d6b6824f9
```

The memory is real. Peak memory of the whole process for four values of `N`, each twice the one
before:

```
ana@api:~/shelf$ for e in 14 15 16 17; do python3 -c "import hashlib, resource; hashlib.scrypt(b'x', salt=bytes(16), n=2**$e, r=8, p=1, maxmem=2**28); print('N=2^$e', resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024, 'MiB')"; done
N=2^14 29 MiB
N=2^15 45 MiB
N=2^16 77 MiB
N=2^17 141 MiB
```

From 29 to 141 MiB, and each step adds twice what the last one added. Take away the 13 MiB that is
Python itself and what is left is exactly `128 × 8 × N`: 16, 32, 64 and 128 MiB.

**OWASP's sheet lists five scrypt settings that give a similar minimum level**, trading memory for
parallel runs:

| N | r | p | memory per run |
|---|---|---|---|
| 2^17 | 8 | 1 | 128 MiB |
| 2^16 | 8 | 2 | 64 MiB |
| 2^15 | 8 | 3 | 32 MiB |
| 2^14 | 8 | 5 | 16 MiB |
| 2^13 | 8 | 10 | 8 MiB |

## What hashlib does not give you

`hashlib.scrypt` returns bytes and nothing else: no salt, no parameters, no format. To store it you
have to keep the salt, `N`, `r` and `p` beside it and invent a way to write them down. You also
compare the result yourself, with `hmac.compare_digest`, which takes the same time whether the first
byte differs or the last; `==` stops at the first difference. Every one of those is a place to make a mistake that
no test of a correct password would catch.

That, more than speed, is the practical argument against it in a new system: bcrypt and Argon2id
come with a library that draws the salt, writes the string and verifies it, and scrypt in `hashlib`
does not. Its row in `hashrate.py` was also the slowest of the six, at 524.392 ms. That says nothing bad
about scrypt and something about OWASP's settings: they are a minimum level of defence, not a time,
and the section on choosing parameters measures what that means.
