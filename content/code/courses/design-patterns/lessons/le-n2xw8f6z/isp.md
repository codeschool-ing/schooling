---
title: "Interface segregation: depend only on what you use"
version: 1
---

**The interface segregation principle says that no client should be forced to depend on methods it
does not use.** When one interface serves several kinds of client, each of them depends on all of
it, and a change made for one reaches the others. The cure is several small interfaces, each shaped
by what one kind of client needs.

The principle is sometimes summarised as "interfaces should have one method", which turns it into a
rule about size. Size is not the measure. An interface with five methods that every client calls is
well segregated; an interface with two methods, where half the clients use one and half the other,
is not. The question is the same as lesson 3's single responsibility, asked from the other side:
not who changes this code, but who **uses** it.

Martin found the principle at Xerox, in the 1990s, in the software of a printer. One `Job` class
served printing, stapling and faxing, so the stapling code depended on the faxing methods, and a
change to fax handling meant rebuilding and redeploying every part of the system that touched a
job, including the parts that only stapled.

## Python hides it, until you write a test

Make `~/patterns/solid-2` and work there for this lesson:

```sh
mkdir -p ~/patterns/solid-2
cd ~/patterns/solid-2
```

The library's catalogue was written as one abstract class with everything anybody needed, and a
kiosk in the entrance hall uses it to search:

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [
 {"code": "# catalogue.py\nfrom abc import ABC, abstractmethod\n\n\nclass Catalogue(ABC):\n    @abstractmethod\n    def search(self, words: str) -> list[str]: ...", "note": "The one method the kiosk needs."},
 {"code": "\n    @abstractmethod\n    def lend(self, title: str, member: str) -> None: ...\n\n    @abstractmethod\n    def give_back(self, title: str) -> None: ...", "note": "The desk's two methods."},
 {"code": "\n    @abstractmethod\n    def add_title(self, title: str) -> None: ...\n\n    @abstractmethod\n    def remove_title(self, title: str) -> None: ...\n\n    @abstractmethod\n    def export_csv(self) -> str: ...", "note": "The back office's three. Six methods for three kinds of client, and every client is typed against all six."},
 {"code": "\n\ndef kiosk(catalogue: Catalogue, words: str) -> None:\n    for title in catalogue.search(words):\n        print(\"found:\", title)", "note": "The kiosk calls one method and declares that it needs a whole `Catalogue`."}
]}
```

In production nothing goes wrong: the real catalogue implements all six methods, and the kiosk calls
one. The cost shows the first time somebody tests the kiosk with a stand-in that answers one search:

```python
# fake_kiosk.py
from catalogue import Catalogue, kiosk


class OneTitle(Catalogue):
    def search(self, words: str) -> list[str]:
        return ["Vidas Secas"]


kiosk(OneTitle(), "secas")
```

```
ana@laptop:~/patterns/solid-2$ python3 fake_kiosk.py
placeholder
```

Python refuses to make the stand-in, and names five methods the kiosk will never call. **To test a
search box, you are asked to implement lending, returns and a CSV export.** Somebody will do it, with
five methods that raise `NotImplementedError`, and from then on every change to the desk's or the
back office's methods also means editing a fake for a kiosk that does not care.

## What the other languages make of it

In Java the same arrangement fails at compile time instead: a class that `implements Catalogue` and
leaves out a method is refused, and a change to any method's signature recompiles every client.
TypeScript and Go check the shape at compile time, so a fake passed where a `Catalogue` is expected
must have all six methods there too. Python with a `Protocol` instead of an abstract class would run
the fake happily and leave the complaint to a type checker. In all four, the fix is the same, and
it is about the declaration rather than the class: let the kiosk say it needs something that can
search, and nothing more. The next two sections show where that leads.
