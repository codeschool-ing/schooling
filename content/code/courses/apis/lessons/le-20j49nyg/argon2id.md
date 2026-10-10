---
title: Argon2id
version: 1
---

**Argon2 won the Password Hashing Competition in 2015 and is specified in RFC 9106.** It is
memory-hard like scrypt, and its three costs are separate settings. It comes in three variants, and
**Argon2id** is the one to use. Argon2d reads memory in an order that depends on the password, which
resists hardware best and can leak through timing. Argon2i reads it in a fixed order, which leaks
nothing and is weaker against hardware. Argon2id does the first half of its first pass the way
Argon2i does, and everything after it the way Argon2d does.

Its three parameters, with the names the stored string uses:

| | what it sets | unit |
|---|---|---|
| `m` | memory, filled and read on every hash | KiB |
| `t` | passes over that memory | a count |
| `p` | lanes the memory is divided into, which can run on separate cores | a count |

**`p` is not a multiplier.** Doubling `m` doubles the memory, and doubling `t` doubles the time, but
`p=8` splits the same `m` into eight lanes; it does not use eight times as much. OWASP's sheet says
so in those terms, because it is the parameter most often read wrong.

Python's `argon2` library writes its hash as a **PHC string**, the same idea as bcrypt's with names
for the fields:

```
ana@api:~/shelf$ python3 -c 'from argon2 import PasswordHasher; print(PasswordHasher(memory_cost=19456, time_cost=2, parallelism=1).hash("correct horse battery staple"))'
$argon2id$v=19$m=19456,t=2,p=1$a/RjYqg2aPC6PMMVzqVVbQ$40Wj1p8F++dmvFO0JQq0vg
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 190\" role=\"img\" aria-label=\"The Argon2id string $argon2id$v=19$m=19456,t=2,p=1$a/RjYqg2aPC6PMMVzqVVbQ$40Wj1p8F++dmvFO0JQq0vg cut into five fields separated by dollar signs: the variant argon2id, the version v=19, the parameters m=19456,t=2,p=1, the salt and the hash, both in base64 without padding.\"><rect x=\"20\" y=\"40\" width=\"71.4\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"55.7\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$argon2id</text><line x1=\"55.7\" y1=\"74\" x2=\"55.7\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"55.7\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">variant</text><text x=\"55.7\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">id: Argon2id</text><rect x=\"96.4\" y=\"40\" width=\"45.0\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"118.9\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$v=19</text><line x1=\"118.9\" y1=\"74\" x2=\"118.9\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"118.9\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">version</text><text x=\"118.9\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">19 = 0x13</text><rect x=\"146.4\" y=\"40\" width=\"117.6\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"205.2\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$m=19456,t=2,p=1</text><line x1=\"205.2\" y1=\"74\" x2=\"205.2\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"205.2\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">parameters</text><text x=\"205.2\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">KiB, passes, lanes</text><rect x=\"269.0\" y=\"40\" width=\"163.79999999999998\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.9\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$a/RjYqg2aPC6PMMVzqVVbQ</text><line x1=\"350.9\" y1=\"74\" x2=\"350.9\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"350.9\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">salt</text><text x=\"350.9\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">16 bytes, base64</text><rect x=\"437.79999999999995\" y=\"40\" width=\"163.79999999999998\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"519.6999999999999\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$40Wj1p8F++dmvFO0JQq0vg</text><line x1=\"519.6999999999999\" y1=\"74\" x2=\"519.6999999999999\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"519.6999999999999\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash</text><text x=\"519.6999999999999\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">16 bytes, base64</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">m: memory in KiB</text><text x=\"210\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">t: passes over it</text><text x=\"400\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p: lanes it is split into</text></svg>", "caption": "The PHC string format: fields between dollar signs, the parameters as name=value pairs."}
```

Read it field by field: the variant, `argon2id`; the version of the algorithm, `v=19`; the three
costs, `m=19456,t=2,p=1`; the salt; the hash. Like bcrypt's, it is everything a later check needs,
which is what lets the parameters change without anybody losing their password: each row says
which ones it was made with.

The library's own defaults, when you call `PasswordHasher()` with no arguments, are larger than what
that string used:

```
ana@api:~/shelf$ python3 -c 'from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.memory_cost, ph.time_cost, ph.parallelism)'
102400 2 8
```

100 MiB, two passes, eight lanes. The memory is taken for real, as it was for scrypt: the peak of
the whole process for three values of `m`, where about 10 MiB is Python itself:

```
ana@api:~/shelf$ for m in 19456 47104 102400; do python3 -c "import resource; from argon2 import PasswordHasher; PasswordHasher(memory_cost=$m, time_cost=2, parallelism=1).hash('x'); print('m=$m', resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024, 'MiB')"; done
m=19456 29 MiB
m=47104 56 MiB
m=102400 110 MiB
```

## OWASP's settings

OWASP's Password Storage Cheat Sheet gives five **minimum** settings for Argon2id and says they
provide an equal level of defence, trading memory for passes:

| m | memory | t | p |
|---|---|---|---|
| 47104 | 46 MiB | 1 | 1 |
| 19456 | 19 MiB | 2 | 1 |
| 12288 | 12 MiB | 3 | 1 |
| 9216 | 9 MiB | 4 | 1 |
| 7168 | 7 MiB | 5 | 1 |

The sheet adds that the first two are not for Argon2i, and that the settings are to be benchmarked
on the system that will run them rather than copied. The string above uses the second row, and so
does `passwords.py`. Choosing among them, or above them, is the next section.
