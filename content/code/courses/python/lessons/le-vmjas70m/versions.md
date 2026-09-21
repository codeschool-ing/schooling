---
title: `==`, `>=`, `~=`, and what a version number promises
version: 1
---

```sh
MAJOR . MINOR . PATCH
  2   .  31   .   0
```

Semantic versioning is a **promise the author makes**: a patch release fixes something, a minor
release adds something without breaking what was there, and a major release is allowed to break
things. Everything below rests on that promise being kept, and most of the time it is.

## The specifiers, resolved in a fresh environment

```sh
requests==2.31.0    →  2.31.0
requests~=2.31.0    →  2.31.0
requests~=2.31      →  2.34.2
requests>=2.26      →  2.34.2
```

Four requests, three different answers, run this afternoon against the real index.

- **`==2.31.0`** — exactly that. No surprises and no fixes either.
- **`~=2.31.0`** — "compatible release": the **last component may move**, so this means
  `>=2.31.0, ==2.31.*`. Patch releases, nothing more.
- **`~=2.31`** — the same rule with one component fewer, so the *minor* may move:
  `>=2.31, ==2.*`. That is why it resolved three minor versions ahead.
- **`>=2.26`** — anything newer, including a major release that was allowed to break you.

**`~=` is the one worth understanding**, and the difference between its two forms is the number
of components you wrote, which is easy to mistype and produces no error.

## The other two

```sh
requests>=2.26,<3        a range, written out
requests!=2.32.0         everything except a release that was broken
```

A comma is an **and**. `>=2.26,<3` is the explicit form of `~=2.26` and is worth preferring
precisely because it cannot be misread.

## What a specifier does not pin

```sh
$ python -m pip show requests
Requires: certifi, charset-normalizer, idna, urllib3
```

```sh
requests 2.31.0 asks for:
  urllib3 (<3, >=1.21.1)
  charset-normalizer (<4, >=2)
  certifi (>=2017.4.17)
```

Pinning `requests==2.31.0` exactly pins **one** package. `urllib3` may be anything under 3,
`certifi` anything at all since 2017. Two installs of the same `requirements.txt`, a month apart,
can produce different code — which is the next section.
