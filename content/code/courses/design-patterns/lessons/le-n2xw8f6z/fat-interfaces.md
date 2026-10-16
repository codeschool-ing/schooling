---
title: What a fat interface costs
version: 1
---

**A fat interface is one that promises more than some of its implementers can deliver or some of
its clients need.** The first half breaks substitution, because an implementer that cannot do
something has to refuse it. The second half spreads change, because a client tied to methods it
never calls is affected when they change. Lesson 3 met the first half without naming it.

It is tempting to believe that a broad interface is generous: offer everything, and each client
takes what it wants. The trouble is that a type is a promise in both directions. A class that
claims an interface promises every method on it, and a client that asks for an interface may be
handed anything that makes that promise.

## Three symptoms

| symptom | where you have seen it |
|---|---|
| implementers that raise `NotImplementedError` or refuse a method | `ReferenceBook.lend` in lesson 3 |
| test doubles that must stub methods the test never touches | `OneTitle` in the last section |
| a change to one method forcing rebuilds or edits in unrelated clients | Martin's printer at Xerox |

All three come from one cause: the interface was shaped by the **implementer**, the thing that
happened to have all those methods, instead of by the clients that use it.

## The reference book again

Lesson 3 ended with a verdict on `ReferenceBook`: it is not lendable, and the hierarchy said it was.
The hierarchy said so because `Item` held two promises at once, *I can be described* and *I can be
lent*, and every item had to make both. Segregating them means two declarations: a class for what
every item has, and a protocol for the capability only some items have.

```schooling-example
{"language": "python", "file": "items.py", "parts": [
 {"code": "# items.py\nfrom datetime import date, timedelta\nfrom typing import Protocol, runtime_checkable\n\n\nclass Item:\n    def __init__(self, title: str):\n        self.title = title\n\n    def describe(self) -> str:\n        return self.title", "note": "What every item in the library has: a title and a way to describe itself. Nothing about lending."},
 {"code": "\n\n@runtime_checkable\nclass Lendable(Protocol):\n    title: str\n\n    def lend(self, on: date) -> date: ...", "note": "The capability, declared on its own. `runtime_checkable` lets `isinstance` ask whether an object has the shape; normally a protocol is only for type checkers."},
 {"code": "\n\nclass Book(Item):\n    def lend(self, on: date) -> date:\n        return on + timedelta(days=14)\n\n\nclass Film(Item):\n    def lend(self, on: date) -> date:\n        return on + timedelta(days=7)", "note": "Books and films are items and also have `lend`, so they satisfy `Lendable` without naming it."},
 {"code": "\n\nclass ReferenceBook(Item):\n    def describe(self) -> str:\n        return f\"{self.title}, reading room only\"", "note": "The reference book is an item and makes no claim to be lendable. It has nothing to refuse."},
 {"code": "\n\ndef catalogue_page(items: list[Item]) -> None:\n    for item in items:\n        print(\"*\", item.describe())\n\n\ndef check_out(items: list[Lendable], on: date) -> None:\n    for item in items:\n        print(f\"{item.title:<22} due {item.lend(on)}\")", "note": "Each client asks for what it uses. The catalogue page takes any `Item`; the desk takes only things that can be lent."},
 {"code": "\n\nif __name__ == \"__main__\":\n    book, film, dictionary = Book(\"Dom Casmurro\"), Film(\"Central do Brasil\"), ReferenceBook(\"Aurélio\")\n    catalogue_page([book, film, dictionary])\n    check_out([book, film], date(2026, 3, 2))\n    print([isinstance(x, Lendable) for x in (book, film, dictionary)])"}
]}
```

```
ana@laptop:~/patterns/solid-2$ python3 items.py
* Dom Casmurro
* Central do Brasil
* Aurélio, reading room only
Dom Casmurro           due 2026-03-16
Central do Brasil      due 2026-03-09
[True, True, False]
```

All three appear on the catalogue page, two are checked out, and the last line confirms the shape:
the book and the film are `Lendable`, the dictionary is not. **Nothing in this program refuses
anything, because nothing claims what it cannot do.** The contract test of lesson 3 would now be
run over `Lendable` things, and `ReferenceBook` would never be in its list.

## Where the fat interface usually comes from

Fat interfaces are rarely designed. They are extracted: somebody has a class with fifteen methods,
needs an interface for testing or for a second implementation, and lifts all fifteen into one. The
interface then describes the class, and every client inherits the class's whole surface.

The alternative is to ask each client what it calls and give that list a name. For the catalogue
that gives three names, and they are the subject of the next section. **An interface belongs to
the client that uses it more than to the class that implements it**, which is also the first half
of dependency inversion, two sections on.
