---
title: Why fast is the wrong property
version: 1
---

**A password hash is slow on purpose.** The server pays the cost once, when somebody logs in, and
nobody notices a few tens of milliseconds. Whoever holds a leaked table pays it once for every
guess, against every account, and that is where the cost adds up.

The usual objection is that SHA-256 is a secure hash, so it must be fine for passwords. It is secure
for its own job, which is fingerprinting data: a file, a message, a block of a download. For that
job, speed is a feature, and SHA-256 is built to be as fast as hardware allows. The property that
makes it good there is exactly the one that makes it wrong here.

Measure it rather than take it on trust. `hashrate.py` computes each hash over and over for two
seconds and counts. Save it in `~/shelf` the same way as lesson 1's files:

```schooling-example
{
  "language": "python",
  "file": "shelf/hashrate.py",
  "parts": [
    {
      "code": "# shelf/hashrate.py\n\"\"\"How many password hashes this machine computes in a second.\n\n    python3 hashrate.py           SHA-256 against bcrypt, scrypt and Argon2id\n    python3 hashrate.py argon2    Argon2id at several settings, to choose one\n\"\"\"\nimport hashlib\nimport os\nimport sys\nimport time\n\nimport bcrypt\nfrom argon2.low_level import Type, hash_secret\n\nPASSWORD = b\"correct horse battery staple\"\nSALT = os.urandom(16)",
      "note": "Two libraries from Ubuntu's archive, `python3-bcrypt` and `python3-argon2`; SHA-256 and scrypt come with Python's own `hashlib`. One password and one random salt serve every row, so the rows differ only in the algorithm and its settings."
    },
    {
      "code": "\n\ndef rate(fn, seconds=2.0):\n    \"\"\"Hashes per second: call fn for `seconds`, and at least three times.\"\"\"\n    n, start = 0, time.perf_counter()\n    while n < 3 or time.perf_counter() - start < seconds:\n        fn()\n        n += 1\n    return n / (time.perf_counter() - start)",
      "note": "The measurement: call one hash over and over for two seconds and divide. The floor of three calls keeps a slow setting from being judged on a single sample."
    },
    {
      "code": "\n\ndef sha256():\n    return hashlib.sha256(SALT + PASSWORD).digest()\n\n\ndef bcrypt_at(cost):\n    return lambda: bcrypt.hashpw(PASSWORD, bcrypt.gensalt(cost))\n\n\ndef scrypt_at(n, r, p):\n    return lambda: hashlib.scrypt(PASSWORD, salt=SALT, n=n, r=r, p=p,\n                                  maxmem=2 * 128 * r * n, dklen=32)\n\n\ndef argon2id_at(m, t, p):\n    return lambda: hash_secret(PASSWORD, SALT, time_cost=t, memory_cost=m,\n                               parallelism=p, hash_len=16, type=Type.ID)",
      "note": "One function per algorithm. scrypt's `maxmem` is twice what the settings need, which is `128 × r × N` bytes; leave it out and OpenSSL refuses anything above its default limit, as the section on scrypt shows. `hash_secret` is Argon2's low-level call, where every parameter is named."
    },
    {
      "code": "\n\nCOMPARE = [\n    (\"SHA-256\", \"one pass\", sha256),\n    (\"bcrypt\", \"cost 10\", bcrypt_at(10)),\n    (\"bcrypt\", \"cost 11\", bcrypt_at(11)),\n    (\"bcrypt\", \"cost 12\", bcrypt_at(12)),\n    (\"scrypt\", \"N=2^17 r=8 p=1\", scrypt_at(2**17, 8, 1)),\n    (\"Argon2id\", \"m=19456 t=2 p=1\", argon2id_at(19456, 2, 1)),\n]\n\nTUNE = [\n    (\"Argon2id\", f\"m={m} t={t} p={p}\", argon2id_at(m, t, p))\n    for m, t, p in [(7168, 5, 1), (9216, 4, 1), (12288, 3, 1), (19456, 2, 1),\n                    (47104, 1, 1), (65536, 2, 1), (102400, 2, 8), (262144, 2, 1)]\n]",
      "note": "What the program can measure. `COMPARE` is SHA-256 against the three password hashes, each at the minimum OWASP's Password Storage Cheat Sheet gives, with bcrypt at two more costs. `TUNE` is Argon2id alone: the sheet's five settings, the library's default and two larger ones."
    },
    {
      "code": "\n\ndef span(seconds):\n    \"\"\"A duration in the largest unit that keeps it above one.\"\"\"\n    for unit, size in ((\"days\", 86400), (\"h\", 3600), (\"min\", 60)):\n        if seconds >= size:\n            return f\"{seconds / size:.1f} {unit}\"\n    return f\"{seconds:.1f} s\"",
      "note": "Seconds made readable. The last column is how long this machine needs for a million hashes at that row's settings."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    rows = TUNE if sys.argv[1:] == [\"argon2\"] else COMPARE\n    print(f\"{'algorithm':<9} {'settings':<18} {'hashes/s':>11} {'ms each':>9} {'a million':>12}\")\n    for name, settings, fn in rows:\n        r = rate(fn)\n        print(f\"{name:<9} {settings:<18} {r:>11,.1f} {1000 / r:>9.3f} {span(1e6 / r):>12}\",\n              flush=True)",
      "note": "With no argument it compares; with `argon2` it tunes. `flush=True` prints each row as soon as it is measured, because a whole run takes several seconds."
    }
  ]
}
```

Run it. It takes a few seconds per row, and the slowest rows are the point:

```
ana@api:~/shelf$ python3 hashrate.py
algorithm settings              hashes/s   ms each    a million
SHA-256   one pass           1,101,475.6     0.001        0.9 s
bcrypt    cost 10                   16.0    62.651       17.4 h
bcrypt    cost 11                    7.9   127.267     1.5 days
bcrypt    cost 12                    3.9   256.682     3.0 days
scrypt    N=2^17 r=8 p=1             1.9   524.392     6.1 days
Argon2id  m=19456 t=2 p=1           23.3    42.992       11.9 h
```

Your numbers will differ, because your computer is not this one, and they will differ a little
between two runs on the same machine; read the columns against each other rather than as values.
On this run **SHA-256 computed 1,101,475.6 hashes a second**, so a million guesses took 0.9 s. The
password hashes computed between 1.9 and 23.3 a second, and the same million guesses took between
11.9 hours and 6.1 days.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Hashes per second on the lab machine, on a logarithmic scale from 1 to 10 million: SHA-256 one pass: 1,101,475.6 per second, a million in 0.9 s; bcrypt cost 10: 16.0 per second, a million in 17.4 h; bcrypt cost 11: 7.9 per second, a million in 1.5 days; bcrypt cost 12: 3.9 per second, a million in 3.0 days; scrypt N=2^17 r=8 p=1: 1.9 per second, a million in 6.1 days; Argon2id m=19456 t=2 p=1: 23.3 per second, a million in 11.9 h\"><text x=\"610\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a million take</text><text x=\"20\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SHA-256</text><text x=\"92\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one pass</text><rect x=\"210\" y=\"40\" width=\"336.62431480178157\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"538.6243148017816\" y=\"49\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1,101,475.6</text><text x=\"610\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">0.9 s</text><text x=\"20\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bcrypt</text><text x=\"92\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cost 10</text><rect x=\"210\" y=\"74\" width=\"67.08668474797298\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"283.086684747973\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16.0</text><text x=\"610\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">17.4 h</text><text x=\"20\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bcrypt</text><text x=\"92\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cost 11</text><rect x=\"210\" y=\"108\" width=\"50.0106522290389\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"266.0106522290389\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7.9</text><text x=\"610\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.5 days</text><text x=\"20\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bcrypt</text><text x=\"92\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cost 12</text><rect x=\"210\" y=\"142\" width=\"32.93074239147637\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"248.93074239147637\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3.9</text><text x=\"610\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3.0 days</text><text x=\"20\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">scrypt</text><text x=\"92\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">N=2^17 r=8 p=1</text><rect x=\"210\" y=\"176\" width=\"15.530557767371903\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"231.5305577673719\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.9</text><text x=\"610\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6.1 days</text><text x=\"20\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Argon2id</text><text x=\"92\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">m=19456 t=2 p=1</text><rect x=\"210\" y=\"210\" width=\"76.18125845716395\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"292.18125845716395\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">23.3</text><text x=\"610\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">11.9 h</text><line x1=\"210\" y1=\"250\" x2=\"600\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"210.0\" y1=\"34\" x2=\"210.0\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"210.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><line x1=\"265.7142857142857\" y1=\"34\" x2=\"265.7142857142857\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"265.7142857142857\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><line x1=\"321.42857142857144\" y1=\"34\" x2=\"321.42857142857144\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"321.42857142857144\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><line x1=\"377.1428571428571\" y1=\"34\" x2=\"377.1428571428571\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"377.1428571428571\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1k</text><line x1=\"432.8571428571429\" y1=\"34\" x2=\"432.8571428571429\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"432.8571428571429\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10k</text><line x1=\"488.57142857142856\" y1=\"34\" x2=\"488.57142857142856\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"488.57142857142856\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100k</text><line x1=\"544.2857142857142\" y1=\"34\" x2=\"544.2857142857142\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"544.2857142857142\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1M</text><line x1=\"600.0\" y1=\"34\" x2=\"600.0\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"600.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10M</text><text x=\"405.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hashes per second on one core, each mark ten times the last</text></svg>", "caption": "One run of hashrate.py on the lab machine. The scale is logarithmic: SHA-256 sits more than five marks to the right of the slowest password hash, over half a million times faster."}
```

Two cautions about what this measures. It is one Python loop on one core, and anybody serious about
a leaked table uses hardware built for the job, which is far faster than this for every row. The
ratio between the rows is what carries over, and it carries over unevenly: scrypt and Argon2id need
a block of memory for every hash in flight, which is exactly what a graphics card running thousands
of guesses side by side is short of. The sections on those two come back to it.

**The cost is paid per guess, so it multiplies with the size of the guess list.** A short list of
common passwords costs little even against a slow hash, which is why the rules for the password
itself, at the end of this lesson, still matter. A slow hash turns a leak into a race the
defender can win: time to notice, warn the users and reset the passwords, before most of them fall.
