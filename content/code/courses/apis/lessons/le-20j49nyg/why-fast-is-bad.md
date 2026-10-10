---
title: x
version: 1
---

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
