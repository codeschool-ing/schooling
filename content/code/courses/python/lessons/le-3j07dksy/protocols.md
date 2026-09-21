---
title: What it must DO, rather than what it must BE
version: 1
---

```python
from typing import Protocol

class Writer(Protocol):
    def write(self, text: str) -> int: ...

def report(out: Writer, rows: list[dict]) -> None:
    out.write(format(rows))
```

`report` accepts anything with a `write(str) -> int` method. A file, an `io.StringIO`, a socket
wrapper, a test double you wrote in four lines — **and none of them has to import `Writer` or
inherit from anything.**

## Why this is the Pythonic one

Duck typing has always been the language's answer: if it has the method, it works. Every
annotation up to here has been the opposite — naming a class and demanding that class or a
subclass.

A `Protocol` annotates the duck typing rather than giving it up. The check is STRUCTURAL: the
checker compares the methods, not the ancestry.

## Where it earns its place

```python
class SupportsClose(Protocol):
    def close(self) -> None: ...
```

- a function that takes "something with a `read`"
- a test double, which now needs no base class and no mock library
- a boundary between two modules, where lesson 6's composition argument applies

## The ones already written

```python
from typing import SupportsInt, SupportsFloat
from collections.abc import Iterable, Sized
```

`Iterable` and `Sized` are protocols in all but name — that is why `Iterable[str]` accepts a
generator, a set and a list without any of them being related.

## `runtime_checkable`

```python
@runtime_checkable
class Writer(Protocol): ...

isinstance(f, Writer)      # now allowed — and it checks the NAMES only
```

`isinstance` against a protocol needs the decorator, and it checks that the methods exist, not
what they take or return. Useful, and weaker than what the checker does.

## And the cost

A `Protocol` is one more name in a file. For two methods used in one place, the class you already
have is simpler — this is for the boundary you want to be able to substitute.
