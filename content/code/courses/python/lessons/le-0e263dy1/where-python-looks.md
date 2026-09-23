---
title: `sys.path`, and the file you named `random.py`
version: 2
---

```python
import sys
sys.path
# ['', '/usr/lib/python3.12', '/usr/lib/python3/dist-packages', ...]
```

An import walks that list in order and takes the first match. The first entry is the directory of
the script being run — which is the whole of this section.

## The shadowing

```
$ ls
random.py      my_game.py
```

`my_game.py` says `import random`. Python looks in the current directory first, finds YOUR
`random.py`, and imports that. Then `random.choice(...)` raises `AttributeError: module 'random'
has no attribute 'choice'` — naming a function that certainly exists, in a module that is
certainly installed.

**The error is telling the truth about the wrong file.** `random.__file__` prints where the
module actually came from, and it is the one command that settles this in five seconds.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"An import walks the path list in order and takes the first match. The first entry is the directory of the script being run, so a file of your own called random.py is found before the standard library ever gets asked.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"56\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">import random walks this list, in this order</text> <rect x=\"56\" y=\"34\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"206\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the directory of the script being run</text> <text x=\"380\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">and yours is here: random.py</text> <rect x=\"56\" y=\"86\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"206\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">/usr/lib/python3.12</text> <text x=\"380\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the real one is here, and never asked</text> <rect x=\"56\" y=\"138\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"206\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">/usr/lib/python3/dist-packages</text> <path d=\"M34 190 L34 42\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"26\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">first match wins, and the walk stops</text> <text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">random.__file__ prints where the module actually came from.</text> <text x=\"360\" y=\"249\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">It is the one command that settles this in five seconds.</text> </svg>", "caption": "Nothing is wrong with the machinery. The import found a random.py — it just was not the one you meant."}
```

The names people take by accident are the obvious ones: `random.py`, `json.py`, `email.py`,
`test.py`, `string.py`, `types.py`. It is also why `__pycache__` matters here — a stale `.pyc`
of your shadowing module can outlive the file you deleted.

## What else is on the path

Site packages — where `pip install` puts things — and the standard library. You do not edit
`sys.path` in ordinary code: appending to it at the top of a file to reach a module one directory
up is the arrangement that works on your machine and nowhere else.

The supported answers are a package with an `__init__.py`, running with `python -m`, and — for
anything real — installing your project, which lesson 18 covers.

## Where it came from

```python
import json
json.__file__          # /usr/lib/python3.12/json/__init__.py
```

Three questions get answered by that one line: is it mine or the library's, is it the version I
think, and is it installed at all. **Reach for it the moment an import does something
surprising.**
