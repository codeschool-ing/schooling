---
title: A login that gives nothing away
version: 1
---

**A failed login must not say whether the account exists, in its words or in its timing.** A login
form that answers "no such user" to one name and "wrong password" to another tells a stranger who
has an account, and on some services that alone is private information.

`passwords.py` says "wrong name or password" in both cases, and the common belief is that this
settles it. It does not, because the reply also has a duration. A login for a name that exists runs
Argon2id; a login that stopped at "no such row" would answer as soon as the database did. Timing a
few replies would separate the two.

So `login` checks every failed name against `DECOY`, a hash of a random string made when the program
starts, with the same parameters as every other hash. Four failed logins, two for Ana with a wrong
password and two for a name that does not exist:

```
ana@api:~/shelf$ for name in ana nobody ana nobody; do python3 -c "import time, passwords; t = time.perf_counter(); passwords.login('$name', 'not her password'); print('$name', round((time.perf_counter() - t) * 1000), 'ms')"; done
ana 143 ms
nobody 139 ms
ana 139 ms
nobody 130 ms
```

And the database lookup alone, which is all an unknown name would cost if `login` returned as soon as
the row was missing:

```
ana@api:~/shelf$ python3 -c "import time, passwords; t = time.perf_counter(); passwords.accounts().execute('SELECT * FROM users WHERE name = ?', ('nobody',)).fetchone(); print(round((time.perf_counter() - t) * 1000, 1), 'ms')"
0.6 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Time for one failed login, measured: ana with a wrong password 143 ms; the unknown name nobody, checked against the decoy, 139 ms; the database lookup alone, which is all an unknown name would cost without the decoy, 0.6 ms.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ana, a wrong password</text><rect x=\"250\" y=\"30\" width=\"371.8\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"629.8\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">143 ms</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nobody, checked against the decoy</text><rect x=\"250\" y=\"72\" width=\"361.40000000000003\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"619.4000000000001\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">139 ms</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nobody, if login returned at once</text><rect x=\"250\" y=\"114\" width=\"2\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.6 ms</text><line x1=\"250\" y1=\"160\" x2=\"640.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"250.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"250.0\" y1=\"156\" x2=\"250.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"380.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><line x1=\"380.0\" y1=\"156\" x2=\"380.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"510.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><line x1=\"510.0\" y1=\"156\" x2=\"510.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"640.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><line x1=\"640.0\" y1=\"156\" x2=\"640.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"445.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">milliseconds</text></svg>", "caption": "The first two bars are the answer the decoy buys: a stranger timing the reply cannot tell them apart. The third is what an unknown name would cost without it."}
```

Between 130 and 143 ms in all four, against 0.6 ms without the decoy. The few milliseconds between
them are the ordinary noise of a machine doing other things; a stranger timing replies across a
network sees far more noise than that, and nothing as large as the hash.

Three details keep it honest:

| detail | why |
|---|---|
| the decoy uses `HASHER`, so it follows any change of parameters | a decoy made with old ones would take a different time |
| `login` returns `False` for an unknown name even if the decoy matched | it cannot, since nobody knows the random string, but the code does not rely on that |
| the rehash happens only after a correct password | a successful login may take longer; a failed one has nothing to reveal |

**Registration is the other door.** `passwords.py register` says the name is taken, which is honest
and, for a shop, acceptable; a service where having an account is itself sensitive answers every
registration the same way and sends the details to the address given.

What this section does not stop is somebody trying many passwords against one account, or one
password against many. The hash makes each try expensive for both sides, and limiting how often one
client may try is lesson 12.
