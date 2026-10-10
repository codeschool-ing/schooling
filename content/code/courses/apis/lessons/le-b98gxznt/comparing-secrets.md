---
title: Comparing secrets
version: 1
---

**`==` is the wrong tool for comparing a secret, because how long it takes depends on the answer.** To
compare two strings, `==` walks them from the start and stops at the first character that differs.
That is the fast and sensible thing for every other comparison a program makes, and for a secret it
leaks how much of a guess was right.

The effect is easy to measure on your own machine. Two strings of a hundred thousand characters, the
first time differing in the first character and the second time in the last:

```
ana@api:~/shelf$ python3 -m timeit -s 'a = "x" * 100_000; b = "y" + "x" * 99_999' 'a == b'
20000000 loops, best of 5: 19.8 nsec per loop
ana@api:~/shelf$ python3 -m timeit -s 'a = "x" * 100_000; b = "x" * 99_999 + "y"' 'a == b'
100000 loops, best of 5: 3.25 usec per loop
```

Nanoseconds against microseconds: the comparison that found the difference at once was over a
hundred times quicker. Scale that down to a 43-character key and the difference shrinks to almost
nothing, but **almost nothing, measured many thousands of times, is a signal**. A server whose
refusal takes a little longer when the first characters of a guess are right tells a patient caller,
one character at a time, which characters are right. Networks add noise, and noise is averaged away by
asking more often. This is a **timing side channel**: the answer was correct, and the time it took
said more than the answer.

`hmac.compare_digest` exists to say nothing. It looks at every character whatever it finds, so the
time depends on the length of the strings and not on where they differ:

```
ana@api:~/shelf$ python3 -m timeit -s 'import hmac; a = "x" * 100_000; b = "y" + "x" * 99_999' 'hmac.compare_digest(a, b)'
5000 loops, best of 5: 73.7 usec per loop
ana@api:~/shelf$ python3 -m timeit -s 'import hmac; a = "x" * 100_000; b = "x" * 99_999 + "y"' 'hmac.compare_digest(a, b)'
5000 loops, best of 5: 73.4 usec per loop
```

The two times are the same to within the noise of the machine. **Slower, and on purpose**: for a
secret, a comparison that takes the same time every time is the one that is correct.

## Where `keys.py` uses it

Twice, at the two places where something sent is checked against something stored:

| where | what is compared |
|---|---|
| `check_password` | the scrypt of what was sent against the stored scrypt |
| `by_key` | the SHA-256 of the key sent against the stored SHA-256 |

The token is the third case and is handled another way: `by_token` looks up the hash of what was sent
in the database rather than comparing strings itself. A difference in timing there would be about how
much of a SHA-256 matched, and the caller cannot steer a hash's first characters by changing the
token, so it teaches them nothing. **Comparing hashes rather than secrets is the other half of the
same defence**, and `keys.py` does both where it compares.

Every language has its version of this function: `crypto.timingSafeEqual` in Node.js,
`MessageDigest.isEqual` in Java, `subtle.ConstantTimeCompare` in Go. Whichever you write in, a secret
is never compared with the ordinary equality operator.
