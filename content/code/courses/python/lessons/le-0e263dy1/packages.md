---
title: A directory of modules, and the two kinds of import
version: 1
---

```
report/
    __init__.py
    load.py
    format.py
```

A package is a directory. `import report.load` works because the directory has an
`__init__.py` — and since Python 3.3 it mostly works without one too, which is a change that
causes confusion rather than removing it. **Write the `__init__.py`.** An empty file is the
clearest thing you can say.

## What `__init__.py` is for

It runs when the package is first imported. Two honest uses:

```python
# report/__init__.py
from .load import load_rows        # re-export, so callers write report.load_rows
__version__ = "1.2.0"
```

Anything longer than that is work happening at import, which is the previous section's problem
one level up.

## Absolute and relative

```python
from report.load import load_rows     # absolute
from .load import load_rows           # relative — the package this file is in
from ..shared import utils            # one level up
```

**Absolute inside a project, relative inside a package meant to be moved or renamed.** The rule
that matters more: a relative import only works when the file is being imported AS PART OF a
package. Run `python report/load.py` directly and `from .something import x` raises — the file
was run, so it is not in a package, and the dot has nothing to refer to.

That error — `attempted relative import with no known parent package` — means exactly that, and
the fix is `python -m report.load`.

## The circular import

```python
# a.py
import b
# b.py
import a
```

Each one is half-built when the other reads it, and the failure is an `AttributeError` about a
name that plainly exists. It is nearly always a sign that something belongs in a third module
both of them import — or that the two were one module all along.
