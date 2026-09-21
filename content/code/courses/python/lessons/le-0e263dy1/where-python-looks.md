---
title: `sys.path`, and the file you named `random.py`
version: 1
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
