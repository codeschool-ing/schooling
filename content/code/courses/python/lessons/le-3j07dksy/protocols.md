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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"Naming a class demands that class or a subclass, so anything written elsewhere is refused however well it fits. A Protocol compares the methods instead, so the same three objects are accepted without importing anything or inheriting from anything.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"182\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">by name — it must inherit</text> <rect x=\"20\" y=\"36\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"182\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">class Writer</text> <rect x=\"20\" y=\"92\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">YourWriter(Writer)</text> <path d=\"M182 86 L182 72\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"20\" y=\"136\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"182\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">io.StringIO</text> <rect x=\"20\" y=\"180\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"182\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">a four-line test double</text> <text x=\"182\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the two with no arrow inherit from nothing of ours</text> <text x=\"558\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">by shape — it must have the method</text> <rect x=\"396\" y=\"36\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">write(self, text: str) -&gt; int</text> <rect x=\"396\" y=\"92\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">YourWriter(Writer)</text> <rect x=\"396\" y=\"136\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">io.StringIO</text> <rect x=\"396\" y=\"180\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">a four-line test double</text> <text x=\"558\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">all three: each of them has the method</text> </svg>", "caption": "A Protocol does not give up duck typing — it annotates it. The check compares the methods, not the ancestry."}
```

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
