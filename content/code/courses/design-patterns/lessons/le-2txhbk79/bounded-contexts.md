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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l11-three-books\" aria-label=\"Three bounded contexts side by side, each a dashed boundary with its own class called Book. In acquisitions, Book has isbn, supplier, unit_cents and quantity, and the method total_cents. In the catalogue, Book has isbn, title, authors and subjects, and the method citation. In lending, Book has barcode, isbn, loan_days and on_loan_to, and the method lend. The three are joined only by the isbn field, which a line under the three boxes connects; one catalogue Book corresponds to many lending Books, one per copy.\"><rect x=\"20.0\" y=\"14.0\" width=\"200.0\" height=\"172.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"120.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">acquisitions</text><text x=\"120.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">&quot;a line on an order&quot;</text><rect x=\"50.0\" y=\"66.0\" width=\"140.0\" height=\"111.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"77.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M50.0 88.5 L190.0 88.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"58.0\" y=\"99.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">isbn</text><text x=\"58.0\" y=\"114.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">supplier</text><text x=\"58.0\" y=\"128.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">unit_cents</text><text x=\"58.0\" y=\"143.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">quantity</text><path d=\"M50.0 154.5 L190.0 154.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"58.0\" y=\"165.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">total_cents()</text><rect x=\"260.0\" y=\"14.0\" width=\"200.0\" height=\"172.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">catalogue</text><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">&quot;a work with an ISBN&quot;</text><rect x=\"290.0\" y=\"66.0\" width=\"140.0\" height=\"111.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"77.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M290.0 88.5 L430.0 88.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"298.0\" y=\"99.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">isbn</text><text x=\"298.0\" y=\"114.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title</text><text x=\"298.0\" y=\"128.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">authors</text><text x=\"298.0\" y=\"143.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">subjects</text><path d=\"M290.0 154.5 L430.0 154.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"298.0\" y=\"165.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">citation()</text><rect x=\"500.0\" y=\"14.0\" width=\"200.0\" height=\"172.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"600.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">lending</text><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">&quot;the thing with a barcode&quot;</text><rect x=\"530.0\" y=\"66.0\" width=\"140.0\" height=\"111.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"77.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M530.0 88.5 L670.0 88.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"538.0\" y=\"99.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">barcode</text><text x=\"538.0\" y=\"114.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">isbn</text><text x=\"538.0\" y=\"128.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loan_days</text><text x=\"538.0\" y=\"143.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">on_loan_to</text><path d=\"M530.0 154.5 L670.0 154.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"538.0\" y=\"165.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend()</text><path d=\"M120.0 186.0 L120.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M360.0 186.0 L360.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M600.0 186.0 L600.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M120.0 210.0 L600.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">joined only by the ISBN, never by sharing the class</text><text x=\"660.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">many per ISBN</text></svg>", "caption": "One word, three models. Each context keeps the Book its own people mean, and the ISBN is the only thing they share."}
```

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
acquisitions: 2 copies, 9980 cents
catalogue:    Graciliano Ramos. Vidas Secas.
lending:      C-0107 out to Bia
lending:      C-0108 out to None
shared:       {'978-65-5555-001-6'}
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
