---
title: Choosing the parameters
version: 1
---

**The parameters are a budget, not a constant.** You choose them by measuring on the machine that
will run them, starting from a published minimum and raising it until a hash costs as much as one
login can afford. Then you write them down in one place, because they will change again.

The tempting rule is "the bigger the better". It fails twice. Every login holds its memory for as
long as the hash runs, so twenty people logging in at once need twenty times `m`. And every login
costs the server what it costs an attacker per guess, so a setting that takes seconds turns the
login route into the cheapest way to exhaust the server. OWASP's sheet warns about exactly that, and
lesson 12 limits how often one client may ask.

`hashrate.py argon2` measures OWASP's five settings, the library's default and two larger ones:

```
ana@api:~/shelf$ python3 hashrate.py argon2
algorithm settings              hashes/s   ms each    a million
Argon2id  m=7168 t=5 p=1            35.3    28.368        7.9 h
Argon2id  m=9216 t=4 p=1            34.1    29.326        8.1 h
Argon2id  m=12288 t=3 p=1           30.6    32.691        9.1 h
Argon2id  m=19456 t=2 p=1           25.0    40.003       11.1 h
Argon2id  m=47104 t=1 p=1            9.8   102.377     1.2 days
Argon2id  m=65536 t=2 p=1            5.2   192.576     2.2 days
Argon2id  m=102400 t=2 p=8           5.5   181.533     2.1 days
Argon2id  m=262144 t=2 p=1           1.1   871.884    10.1 days
```

**OWASP's five rows give an equal level of defence, and on this machine they are not equal in
time**: 28.368 ms at `m=7168 t=5` and 102.377 ms at `m=47104 t=1`. Memory costs time too, because
it has to be filled. The library's default, eight lanes over 100 MiB, took 181.533 ms, less than one
lane over 64 MiB, because its lanes run side by side on separate cores.

Put the memory beside the time and the choice becomes arithmetic. The milliseconds are this run's;
the memory follows from `m`:

| setting | ms per hash, this run | memory per login | twenty logins at once |
|---|---|---|---|
| `m=19456 t=2 p=1` | 40.003 | 19 MiB | 380 MiB |
| `m=47104 t=1 p=1` | 102.377 | 46 MiB | 920 MiB |
| `m=65536 t=2 p=1` | 192.576 | 64 MiB | 1.25 GiB |
| `m=262144 t=2 p=1` | 871.884 | 256 MiB | 5 GiB |

The procedure, in order:

1. Start from OWASP's minimum, which is `m=19456 t=2 p=1` for Argon2id.
2. Measure on a machine like the one that serves logins, not on your laptop.
3. Raise `m` first, then `t`, until one hash takes what a login can spend. The sheet's rule is that
   it should take less than one second.
4. Multiply the memory by the logins you expect at the same moment, and check the server has it.
5. Write the result in one place in the code, and let old hashes upgrade as people log in.

The last step is what the next section builds. A setting chosen today is wrong in a few years,
because hardware gets cheaper, and the stored strings are what make changing it painless.
