---
title: `site-packages`, `sys.path`, and the import that found the wrong copy
version: 1
---

```sh
$ python -c "import sys; [print(repr(p)) for p in sys.path]"
''
'/usr/lib/python311.zip'
'/usr/lib/python3.11'
'/usr/lib/python3.11/lib-dynload'
'/tmp/project/.venv/lib/python3.11/site-packages'
```

**`import` walks that list in order and stops at the first match.** Everything confusing about
imports is a consequence of those two facts.

Inside an environment the list is short: the current directory, the standard library, and one
`site-packages`. The machine's own libraries are not on it at all, which is the isolation.

## The empty string, which is first

```python
# json.py, sitting in your project directory
print("this is not the standard library")
```

```sh
$ python -c "import json; print(json.__file__)"
this is not the standard library
/tmp/project/json.py
```

The empty string means **the directory the script is in** (or the working directory for `-c` and
the REPL), and it comes before the standard library. A file named after a module shadows it for
your whole program — and the error usually surfaces three imports away, inside a library that
imported `json` and got yours.

`random.py`, `email.py`, `types.py`, `test.py`, `token.py` and `queue.py` are the ones people
write by accident. If an import starts behaving impossibly, look for a file with that name beside
you before anything else.

## `pip show -f`

```sh
$ python -m pip show -f requests
Location: /tmp/project/.venv/lib/python3.11/site-packages
Files:
  requests/__init__.py
  requests/api.py
  ...
```

`Location` is the answer to "which copy is being imported", and comparing it against
`requests.__file__` settles an argument in one line:

```python
import requests
print(requests.__version__, requests.__file__)
```

**Those two lines are the first thing to run** when a library behaves like a different version
from the one you installed. More often than not the file is somewhere you did not expect — a user
installation under `~/.local`, or the system's own copy, because the environment was not active
when the command ran.

## `__pycache__`

Compiled bytecode, written beside each module the first time it is imported and reused while the
source is unchanged. It is invisible day to day, belongs in `.gitignore`, and is worth deleting
by hand exactly once: when a `.py` you deleted keeps being importable, because its `.pyc` is
still there.
