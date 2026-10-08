---
title: Indicators of compromise
version: 1
---

An **indicator of compromise (IoC)** is an observable fact that, seen in your environment, suggests a
compromise already happened: an address, a domain, a file's hash, a file name, a registry key, a user
agent. Lesson 8's report carried three. They are useful for exactly one question, **"have we seen this
here?"**, and they answer it fast: a lookup, not an investigation.

Their weakness is that each one is a single, concrete value, and values change. A file's **hash** is the
extreme case:

```
ana@soc:~/week$ printf 'quarterly figures, version 1\n' > a.txt
ana@soc:~/week$ printf 'quarterly figures, version 2\n' > b.txt
ana@soc:~/week$ sha256sum a.txt b.txt
ff9443882788a453030f3813ef6c6e6ba3f4066f050e5bde8092177f2ff099cd  a.txt
99bc73d19e5480a4c68c5188874c2329b563923d5e92453a5648b26b40ce677b  b.txt
```

Two files differing in one character, `1` against `2`, and their SHA-256 fingerprints have nothing in
common. A hash identifies one exact file with complete precision, which is why it is the best evidence
in a forensic report (lesson 16) and the weakest detection there is: whoever made the file changes a byte
and every list carrying the old hash is out of date.

IoCs come in three grades of usefulness:

| grade | example | how it is used |
|---|---|---|
| **atomic** | `203.0.113.66`, one hash | looked up as it is; true or false, no context |
| **computed** | a hash, a pattern derived from a sample | needs the same computation on your side |
| **behavioural** | "many accounts from one source, then success" | needs a rule, and is the subject of this lesson's third section |

The first two are where most shared feeds stop. The third is where detection lasts.
