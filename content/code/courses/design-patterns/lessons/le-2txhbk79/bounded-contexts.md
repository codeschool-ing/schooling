---
title: "Bounded contexts: where a word stops meaning one thing"
version: 1
---

**A bounded context is the boundary inside which one model, and the language that goes with it,
applies without exceptions.** Inside it, *book* means one thing. Outside it, *book* may mean
something else, and that is allowed. The boundary is drawn on purpose, in the code, so that the two
meanings never share a class.

The wrong idea is the one enterprise model: a single `Book` class that the whole system shares,
with every field anybody has ever needed. It starts reasonable and grows. The catalogue adds
`subjects`, lending adds `barcode` and `on_loan_to`, acquisitions adds `supplier` and `unit_cents`.
Soon half the fields are `None` for any given use, nobody can say whether `Book` means a title or a
copy on a shelf, and a change asked for by acquisitions needs a review from lending. **One model for
everybody turns into a model that is right for nobody.**

## Three books

Ask three people in the library what a book is. The cataloguer says: a work with an ISBN, a title,
authors and subjects. The person at the lending desk says: the thing with a barcode sticker that is
either on the shelf or out with somebody. The person who orders from suppliers says: a line on an
order, with a supplier, a price and a quantity. All three are right, inside their own work.

@@fig:l11-three-books@@

So each context gets its own `Book`, in its own module. Three short files:

```python
# catalogue.py
from dataclasses import dataclass


@dataclass(frozen=True)
class Book:
    isbn: str
    title: str
    authors: tuple[str, ...]
    subjects: tuple[str, ...]

    def citation(self) -> str:
        return f"{', '.join(self.authors)}. {self.title}."
```

```python
# lending.py
from dataclasses import dataclass


@dataclass
class Book:
    barcode: str
    isbn: str
    loan_days: int = 14
    on_loan_to: str | None = None

    def lend(self, member: str) -> None:
        if self.on_loan_to is not None:
            raise ValueError(f"copy {self.barcode} is out to {self.on_loan_to}")
        self.on_loan_to = member
```

```python
# acquisitions.py
from dataclasses import dataclass


@dataclass(frozen=True)
class Book:
    isbn: str
    supplier: str
    unit_cents: int
    quantity: int

    def total_cents(self) -> int:
        return self.unit_cents * self.quantity
```

And a fourth that walks one title through all three. It imports the modules by name and writes
`lending.Book` and `catalogue.Book` in full, so it is always clear which book is meant:

```python
# tour.py
import acquisitions
import catalogue
import lending

ISBN = "978-65-5555-001-6"

ordered = acquisitions.Book(ISBN, "Livraria Paulista", unit_cents=4990, quantity=2)
described = catalogue.Book(ISBN, "Vidas Secas", ("Graciliano Ramos",), ("Brazilian fiction", "drought"))
copies = [lending.Book("C-0107", ISBN), lending.Book("C-0108", ISBN)]

print("acquisitions:", ordered.quantity, "copies,", ordered.total_cents(), "cents")
print("catalogue:   ", described.citation())
copies[0].lend("Bia")
for copy in copies:
    print("lending:     ", copy.barcode, "out to", copy.on_loan_to)
print("shared:      ", {ordered.isbn, described.isbn, copies[0].isbn})
```

```
ana@laptop:~/patterns/ddd-strategic$ python3 tour.py
placeholder
```

One order line for two copies, 9980 cents. One catalogue entry. Two lending books, one out to Bia
and one on the shelf. The only thing the three share is the ISBN, and the last line shows it is the
same string in all of them. That is how contexts refer to each other: **by a stable identifier,
never by sharing the object.** The catalogue can add a field for the translator tomorrow and
lending will not notice.

Notice what lending's `Book` really is: a copy, many per ISBN. Lending's people still call it a
book, and inside the lending context that is the right word. Renaming it `Copy` everywhere to
please the cataloguers would make the lending code speak a language the lending desk does not.

## A boundary in the code, not necessarily on the network

A bounded context is a boundary of meaning. It does not have to be a separate service, a separate
database or a separate team, though it can be any of those. In one program it is a module or a
package with a rule that the others do not reach into its classes:

| language | the usual boundary for a context in one program |
|---|---|
| Python | a package; other contexts import only what its `__init__.py` exposes |
| Java | a package, or a JPMS module whose `module-info.java` exports one API package |
| Go | a package, with an `internal/` directory that other packages cannot import |
| TypeScript | a workspace package, or a folder with one `index.ts` that the others import |

Go's `internal/` is the strictest of the four, because the compiler refuses the import. In the
others the line is a convention, held by review or by a lint rule, the same trade lesson 1 found
with Python's underscore.
