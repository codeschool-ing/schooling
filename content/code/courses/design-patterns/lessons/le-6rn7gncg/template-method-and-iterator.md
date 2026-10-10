---
title: Template method and iterator: fixed steps, and walking a collection
version: 1
---

**Template method fixes the outline of an algorithm in a base class and lets subclasses fill in
particular steps; iterator gives a way to walk through a collection one element at a time without
knowing how the collection is stored.** The first is one of the few GoF patterns built on
inheritance, and the second is so useful that every modern language has absorbed it.

## Template method: the outline is not negotiable

Lesson 2 met template method as one of the honest uses of inheritance, so this is a reminder with
the library's reports rather than a second lesson. Every report has a title, an underline, its
rows and a footer. What the rows are and what the footer says differs.

```schooling-example
{"language": "python", "file": "template.py", "parts": [
 {"code": "# template.py\nfrom abc import ABC, abstractmethod\n\n\nclass Report(ABC):\n    def render(self) -> str:\n        rows = self.rows()\n        lines = [self.title(), \"-\" * len(self.title())]\n        lines += [self.format_row(row) for row in rows] or [\"  (nothing to report)\"]\n        lines.append(self.footer(rows))\n        return \"\\n\".join(lines)", "note": "The base class owns `render`, the template. It calls the steps in a fixed order and handles the empty case once, for every report."},
 {"code": "\n    @abstractmethod\n    def title(self) -> str: ...\n\n    @abstractmethod\n    def rows(self) -> list[tuple]: ...", "note": "Two steps every report must provide, marked abstract, so a subclass that forgets one cannot even be built."},
 {"code": "\n    def format_row(self, row: tuple) -> str:\n        return \"  \" + \" | \".join(str(cell) for cell in row)\n\n    def footer(self, rows: list[tuple]) -> str:\n        return f\"{len(rows)} rows\"", "note": "Two hooks with defaults. A subclass overrides them only if it wants something else."},
 {"code": "\n\nclass OverdueReport(Report):\n    def __init__(self, loans: list[tuple[str, str, int]]):\n        self._loans = loans\n\n    def title(self) -> str:\n        return \"Overdue loans\"\n\n    def rows(self) -> list[tuple]:\n        return [loan for loan in self._loans if loan[2] > 0]\n\n    def footer(self, rows: list[tuple]) -> str:\n        return f\"fines due: {sum(days * 50 for _, _, days in rows)} cents\"\n\n\nclass PopularReport(Report):\n    def __init__(self, counts: dict[str, int]):\n        self._counts = counts\n\n    def title(self) -> str:\n        return \"Most borrowed this month\"\n\n    def rows(self) -> list[tuple]:\n        return sorted(self._counts.items(), key=lambda kv: -kv[1])[:2]\n\n\nif __name__ == \"__main__\":\n    loans = [(\"Bia\", \"Dom Casmurro\", 4), (\"Caio\", \"Vidas Secas\", 0), (\"Duda\", \"Quincas Borba\", 9)]\n    print(OverdueReport(loans).render())\n    print(PopularReport({\"Torto Arado\": 11, \"Vidas Secas\": 7, \"Dom Casmurro\": 9}).render())", "note": "One report overrides the footer and the other keeps the default. Neither can change the order of the steps."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 template.py
Overdue loans
-------------
  Bia | Dom Casmurro | 4
  Duda | Quincas Borba | 9
fines due: 650 cents
Most borrowed this month
------------------------
  Torto Arado | 11
  Dom Casmurro | 9
2 rows
```

**The base class calls the subclass, not the other way round**: the inversion of control of
lesson 5, inside one class hierarchy. That is also its weakness. A subclass of `Report` depends on
when and in what order `render` calls its methods, which is the fragile base class of lesson 2. If
the variations multiply, pass the steps in as strategies instead, which is the same outline built
by composition.

## Iterator: walking without knowing the shape

The shelf stores its books in a dictionary keyed by shelf mark. The code that prints a shelf list
should not know that, and should not change if the shelf moves to a sorted list or a database
cursor. It should only be able to ask for the next book.

```schooling-example
{"language": "python", "file": "iterator.py", "parts": [
 {"code": "# iterator.py\nclass MarkWalker:\n    def __init__(self, marks: list[str]):\n        self._marks, self._next = sorted(marks), 0\n\n    def __iter__(self):\n        return self\n\n    def __next__(self) -> str:\n        if self._next == len(self._marks):\n            raise StopIteration\n        self._next += 1\n        return self._marks[self._next - 1]", "note": "The GoF shape, written out in full: an object that remembers where it is and hands out one element per call to `__next__`, raising `StopIteration` at the end."},
 {"code": "\n\nclass Shelf:\n    def __init__(self):\n        self._books: dict[str, str] = {}\n\n    def put(self, mark: str, title: str) -> None:\n        self._books[mark] = title\n\n    def __iter__(self):\n        for mark in MarkWalker(list(self._books)):\n            yield mark, self._books[mark]\n\n    def section(self, prefix: str):\n        return ((mark, title) for mark, title in self if mark.startswith(prefix))", "note": "The shelf hands out an iterator when asked. A generator does it in three lines: `yield` turns the method into an iterator object with `__next__` built for you."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Shelf()\n    shelf.put(\"869.3 RAM\", \"Vidas Secas\")\n    shelf.put(\"869.3 ASS\", \"Dom Casmurro\")\n    shelf.put(\"791 MEI\", \"Cidade de Deus\")\n    for mark, title in shelf:\n        print(mark, title)\n    walker = iter(shelf)\n    print(\"by hand:\", next(walker), next(walker))\n    print(\"section 869:\", [title for _, title in shelf.section(\"869\")])", "note": "A `for` loop asks for an iterator with `iter()` and calls `next()` on it until `StopIteration`. Done by hand, the same two calls show what the loop does."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 iterator.py
791 MEI Cidade de Deus
869.3 ASS Dom Casmurro
869.3 RAM Vidas Secas
by hand: ('791 MEI', 'Cidade de Deus') ('869.3 ASS', 'Dom Casmurro')
section 869: ['Dom Casmurro', 'Vidas Secas']
```

The loop printed in shelf-mark order, though the books went in another order and the dictionary
keeps insertion order. Nobody outside `Shelf` knows a dictionary is involved, or that `MarkWalker`
exists. `section` filters lazily: it produces each match when asked, so a shelf of a million
books would be walked once, not copied into a list first.

In most of this course you will write the generator and never the class. `MarkWalker` is here
because it is what a generator writes for you, and because it is what the GoF book describes: in
C++ in 1994, there was no `yield`. Java has `Iterator` with `hasNext` and `next` and the enhanced
`for` that calls them; JavaScript has the same protocol with `[Symbol.iterator]` and `function*`;
Go added range-over-function iterators in Go 1.23. The pattern has become a language feature in
all four.
