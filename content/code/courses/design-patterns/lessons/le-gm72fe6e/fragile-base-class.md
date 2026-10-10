---
title: The fragile base class
version: 1
---

**A subclass depends on how its parent works inside, and the parent's author cannot see that
dependency.** The parent can change in a way that is correct, tested and harmless to every caller,
and still break a child somebody else wrote. The name for this is the fragile base class problem,
and it is the strongest reason this lesson's title says *almost always*.

The usual picture is that inheritance reuses the parent's *interface*: its public methods, with the
meanings their names suggest. That picture is wrong in one specific way. A child that overrides a
method also inherits every place where the parent calls that method on `self`, and those calls are
not part of any interface anybody wrote down.

Make `~/patterns/composition` and work there for the whole lesson:

```sh
mkdir -p ~/patterns/composition
cd ~/patterns/composition
```

## A shelf, and a shelf that counts

The library keeps its new arrivals on a shelf object. Somebody else wrote it, and it has two ways to
put titles on it:

```python
# shelf.py
class Shelf:
    def __init__(self):
        self._titles: list[str] = []

    def add(self, title: str) -> None:
        self._titles.append(title)

    def add_all(self, titles: list[str]) -> None:
        for title in titles:
            self.add(title)

    def __len__(self) -> int:
        return len(self._titles)
```

The monthly report wants to know how many titles were shelved. Inheritance looks like the shortest
way: a `CountingShelf` that is a `Shelf` with a counter, bumping it in both methods.

```schooling-example
{"language": "python", "file": "counting.py", "parts": [
 {"code": "# counting.py\nfrom shelf import Shelf\n\n\nclass CountingShelf(Shelf):\n    def __init__(self):\n        super().__init__()\n        self.added = 0", "note": "A shelf with one extra field. Everything else comes from the parent."},
 {"code": "\n    def add(self, title: str) -> None:\n        self.added += 1\n        super().add(title)", "note": "One title, one more on the counter, then the parent does the shelving."},
 {"code": "\n    def add_all(self, titles: list[str]) -> None:\n        self.added += len(titles)\n        super().add_all(titles)", "note": "Several titles, several more on the counter. Read on its own, each method is correct."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = CountingShelf()\n    shelf.add(\"Dom Casmurro\")\n    shelf.add_all([\"Vidas Secas\", \"Iracema\", \"O Cortiço\"])\n    print(\"on the shelf:\", len(shelf))\n    print(\"counted:     \", shelf.added)", "note": "One title, then three: four on the shelf, and the counter should say four."}
]}
```

```
ana@laptop:~/patterns/composition$ python3 counting.py
on the shelf: 4
counted:      7
```

Seven. `add_all` added three to the counter and then called the parent's `add_all`, which calls
`self.add` once per title. `self` is a `CountingShelf`, so each of those calls lands in the child's
`add`, which counts again. **The child was broken by a line inside the parent that it never
looked at.** Nothing in `Shelf`'s public methods said that `add_all` is built on `add`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 320\" role=\"img\" data-fig=\"l02-self-call\" aria-label=\"A sequence diagram of counting.py adding three titles. The program calls add_all on the CountingShelf, which adds 3 to its counter and calls the parent Shelf's add_all. The parent loops and calls self.add once per title; because self is the CountingShelf, each of those three calls lands back in the child's add, which adds 1 to the counter each time before calling the parent's add. The three titles are counted twice: 1 for the first title, plus 3, plus 3, makes 7, while the shelf holds 4.\"><defs><marker id=\"l02-self-call-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-self-call-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"25.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the program</text><path d=\"M100.0 44.0 L100.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"275.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CountingShelf</text><path d=\"M350.0 44.0 L350.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"525.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shelf</text><path d=\"M600.0 44.0 L600.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M100.0 80.0 L346.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-self-call-dp-ah-paper-dim)\"></path><text x=\"225.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">add_all(3 titles)</text><text x=\"225.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">added += 3</text><path d=\"M350.0 135.0 L596.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-self-call-dp-ah-paper-dim)\"></path><text x=\"475.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">super().add_all(titles)</text><path d=\"M600.0 190.0 L354.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l02-self-call-dp-ah-amber)\"></path><text x=\"475.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">self.add(title)  × 3</text><text x=\"475.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">self is the CountingShelf</text><text x=\"225.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">added += 1  × 3</text><path d=\"M350.0 245.0 L596.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-self-call-dp-ah-paper-dim)\"></path><text x=\"475.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">super().add(title)  × 3</text><text x=\"330.0\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">counted: 1 + 3 + 3 = 7</text><text x=\"370.0\" y=\"300.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">on the shelf: 4</text></svg>", "caption": "The parent's add_all calls add on self, and self is the child. Every title added in a batch is counted twice."}
```

## The fix that makes it worse

Once you know about the self-call, the fix is obvious: stop counting in `add_all`, since the parent
will route every title through `add` anyway.

```schooling-example
{"language": "python", "file": "counting.py", "parts": [
 {"code": "# counting.py\nfrom shelf import Shelf\n\n\nclass CountingShelf(Shelf):\n    def __init__(self):\n        super().__init__()\n        self.added = 0\n\n    def add(self, title: str) -> None:\n        self.added += 1\n        super().add(title)", "note": "Only `add` is overridden now. The child counts on the parent sending every title through it."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = CountingShelf()\n    shelf.add(\"Dom Casmurro\")\n    shelf.add_all([\"Vidas Secas\", \"Iracema\", \"O Cortiço\"])\n    print(\"on the shelf:\", len(shelf))\n    print(\"counted:     \", shelf.added)"}
]}
```

```
ana@laptop:~/patterns/composition$ python3 counting.py
on the shelf: 4
counted:      4
```

Correct, and now the child depends on that self-call being there. A few months later the author of
`Shelf` notices that appending one title at a time is slower than extending the list in one go. They
make a change that every one of their own tests agrees with:

```python
# shelf.py
class Shelf:
    def __init__(self):
        self._titles: list[str] = []

    def add(self, title: str) -> None:
        self._titles.append(title)

    def add_all(self, titles: list[str]) -> None:
        self._titles.extend(titles)

    def __len__(self) -> int:
        return len(self._titles)
```

```
ana@laptop:~/patterns/composition$ python3 counting.py
on the shelf: 4
counted:      1
```

Nothing in `counting.py` changed, and its report is now wrong by three. The shelf still holds four
titles, so a test of `Shelf` passes, and no error is raised anywhere. **Two correct changes, made
by two people who never spoke, produced a wrong number and nothing else.**

## Why the parent cannot protect you

The author of `Shelf` did nothing wrong by any rule they could have known. To avoid breaking
`CountingShelf` they would have had to know it existed, and know which of their internal self-calls
it relied on. A class used by one team can be reasoned about; a class subclassed across a codebase,
or published in a library, has children its author will never read.

There are only two honest ways out. The parent can **document its self-use** as part of its
contract ("`add_all` calls `add` for each title") and then never change it, which is what classes
designed for extension do. Or the child can stop inheriting and **hold** a shelf instead, so the
parent's insides are none of its business. The section after next does the second, and it fixes
both runs above at once.

Java's `HashSet` has exactly this trap, and Joshua Bloch used it in *Effective Java* to argue the
same point: `HashSet` inherits `addAll` from `AbstractCollection`, which calls `add` once per
element, so a subclass that counts in both methods counts every element twice. Go cannot have the problem, because an embedded struct's methods never call back into the
struct that embeds it.
