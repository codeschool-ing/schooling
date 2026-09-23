---
title: `==`, `>=`, `~=`, and what a version number promises
version: 2
---

```localised
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 278\" role=\"img\" aria-label=\"Four specifiers over the same range of releases. Two equals signs admit one version; the compatible-release operator with three components lets only the patch move; with two components it lets the minor move as well; and greater-or-equal admits everything from there up.\"> <text x=\"150\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2.26</text> <rect x=\"149\" y=\"34\" width=\"2\" height=\"8\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <text x=\"385\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2.31</text> <rect x=\"384\" y=\"34\" width=\"2\" height=\"8\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <text x=\"535\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2.34.2</text> <rect x=\"534\" y=\"34\" width=\"2\" height=\"8\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <text x=\"620\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3.0</text> <rect x=\"619\" y=\"34\" width=\"2\" height=\"8\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <rect x=\"150\" y=\"44\" width=\"470\" height=\"2\" rx=\"0\" fill=\"var(--wire)\"></rect> <text x=\"690\" y=\"214\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what it resolved to, run against the real index</text> <text x=\"14\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests==2.31.0</text> <rect x=\"381\" y=\"62\" width=\"8\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"690\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2.31.0</text> <text x=\"14\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests~=2.31.0</text> <rect x=\"385\" y=\"102\" width=\"12\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"690\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2.31.0</text> <text x=\"14\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests~=2.31</text> <rect x=\"385\" y=\"142\" width=\"235\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"690\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2.34.2</text> <text x=\"14\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests&gt;=2.26</text> <rect x=\"150\" y=\"182\" width=\"470\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"690\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2.34.2</text> <text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">The two in the middle differ by one component and by three minor versions.</text> <text x=\"360\" y=\"255\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">A rule that reads like a typo is the one to write down rather than to remember.</text> </svg>", "caption": "Four requests, three different answers — and the two that look alike are the pair that differ most."}
```

- **`==2.31.0`** — exactly that. No surprises and no fixes either.
- **`~=2.31.0`** — "compatible release": the **last component may move**, so this means
  `>=2.31.0, ==2.31.*`. Patch releases, nothing more.
- **`~=2.31`** — the same rule with one component fewer, so the *minor* may move:
  `>=2.31, ==2.*`. That is why it resolved three minor versions ahead.
- **`>=2.26`** — anything newer, including a major release that was allowed to break you.

**`~=` is the one worth understanding**, and the difference between its two forms is the number
of components you wrote, which is easy to mistype and produces no error.

## The other two

| specifier | means |
|---|---|
| `requests>=2.26,<3` | a range, written out |
| `requests!=2.32.0` | everything except a release that was broken |

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
