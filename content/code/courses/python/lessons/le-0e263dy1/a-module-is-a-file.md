---
title: A module is a file, and an import is a lookup
version: 2
---

```python
import math
math.sqrt(16)
```

`math` is a file called `math.py` — or, for this one, something built into the interpreter.
`import` finds it, runs it once, and binds the name `math` to the result.

## The four forms

```python
import math                      # math.sqrt
from math import sqrt            # sqrt
from math import sqrt, pi        # both names
import numpy as np               # an alias
```

**`import module` is the default**, because `math.sqrt(x)` says where `sqrt` came from and
`sqrt(x)` does not. In a file of three hundred lines, that is the difference between reading and
searching.

`from … import` earns its place when the name is used constantly and is unambiguous — `from
pathlib import Path`, `from collections import Counter`. An alias is for a long name used often,
and the aliases people use are conventions: `np`, `pd`, `plt`. **Do not invent a new one.**

## `import *`

```python
from math import *       # no
```

Every public name, in your file, with nothing saying so. Two things then happen and neither is
loud: a name of yours is silently replaced, and the reader of line two hundred cannot find out
where `gamma` came from.

The one place it is defensible is an interactive session, where there is no line two hundred.

## The module is run once

```python
# config.py
print("loading config")
SETTINGS = read_settings()
```

The first `import config` runs the file. Every later one — from any other module — gets the same
already-loaded object, and the print happens once. That is why a module's top level is a fine
place for a constant and a bad place for work with an effect.

## Importing does not copy

```python
from config import SETTINGS      # the same dictionary, by another name
```

Lesson 3's `b = a`, across a file boundary. Changing it through one name changes it for every
module that imported it — which is occasionally what a registry wants, and is usually a surprise.
