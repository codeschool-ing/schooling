---
title: "Liskov substitution: children keep their parents' promises"
version: 1
---

**The Liskov substitution principle says that code written against a parent type must keep working,
without knowing it, when it is handed any child of that type.** Barbara Liskov put it in a keynote
in 1987, and with Jeannette Wing in 1994 gave it the precise form used today. It is the rule that
makes polymorphism safe: the caller in lesson 1 that called `deliver` without asking which channel
it had was relying on it.

The common misunderstanding is that substitution is a matter of types. If the child has every
method of the parent, with the same names and the same arguments, the compiler is satisfied, and
in Python nothing is checked at all. **A child can match its parent's signature perfectly and still
break every caller**, because what callers rely on is behaviour: what a method accepts, what it
promises to return, what stays true about the object.

## A promise in a docstring

Lesson 1's items, cut down to what this section needs, and with the promise of `lend` written down:

```schooling-example
{"language": "python", "file": "items.py", "parts": [
 {"code": "# items.py\nfrom datetime import date, timedelta\n\n\nclass Item:\n    loan_days = 14\n\n    def __init__(self, title: str):\n        self.title = title\n\n    def lend(self, on: date) -> date:\n        \"\"\"Lend the item on a day and return its due date, which is later.\"\"\"\n        return on + timedelta(days=self.loan_days)", "note": "The parent's contract: any day is accepted, and the date returned is after it. Callers will write code that leans on both halves."},
 {"code": "\n\nclass Book(Item):\n    pass\n\n\nclass Film(Item):\n    loan_days = 7", "note": "Two children that keep the promise: a book for 14 days, a film for 7."},
 {"code": "\n\nclass ReferenceBook(Item):\n    def lend(self, on: date) -> date:\n        raise ValueError(f\"{self.title!r} is for the reading room only\")", "note": "Same name, same argument, same declared return type. A type checker accepts it. It does not keep the promise: it refuses to lend at all."},
 {"code": "\n\ndef check_out(items: list[Item], on: date) -> None:\n    for item in items:\n        print(f\"{item.title:<22} due {item.lend(on)}\")", "note": "A caller written against `Item`, as the desk's code would be. It has never heard of reference books."},
 {"code": "\n\nif __name__ == \"__main__\":\n    check_out([Book(\"Dom Casmurro\"), Film(\"Central do Brasil\"), ReferenceBook(\"Aurélio\")],\n              date(2026, 3, 2))"}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 items.py
Dom Casmurro           due 2026-03-16
Central do Brasil      due 2026-03-09
Traceback (most recent call last):
  File "/home/ana/patterns/solid-1/items.py", line 35, in <module>
    check_out([Book("Dom Casmurro"), Film("Central do Brasil"), ReferenceBook("Aurélio")],
  File "/home/ana/patterns/solid-1/items.py", line 31, in check_out
    print(f"{item.title:<22} due {item.lend(on)}")
                                  ^^^^^^^^^^^^^
  File "/home/ana/patterns/solid-1/items.py", line 26, in lend
    raise ValueError(f"{self.title!r} is for the reading room only")
ValueError: 'Aurélio' is for the reading room only
```

`check_out` is correct: it does what the type `Item` says can be done. The fault is in
`ReferenceBook`, which claims to be an `Item` and is not one in the sense the caller needs. The
usual reaction is to fix the caller, with an `isinstance(item, ReferenceBook)` check before `lend`.
That check is the symptom. Every function that lends anything now needs it, and every new child that
refuses something needs another.

## The rules, stated precisely

Liskov and Wing's formulation breaks the promise into parts a reviewer can check one at a time:

| rule | what it means for a child | `ReferenceBook` |
|---|---|---|
| preconditions cannot be strengthened | it accepts at least everything the parent accepts | breaks it: the parent lends on any day, the child on none |
| postconditions cannot be weakened | it guarantees at least everything the parent guarantees | never reaches a return |
| invariants are kept | whatever is always true of the parent stays true | — |
| history rule | it does not allow state changes the parent forbids | — |

A child may go the other way freely: accept **more** than the parent, or promise **more**. A
`Film` that accepted a date in the past, or guaranteed a due date that is never a Sunday, would
still be a perfectly good `Item`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-contract\" aria-label=\"Two panels about the promise of Item.lend. On the left, what a method accepts: the parent accepts any day, drawn as a box; a dashed box around it shows that a child may accept more. ReferenceBook accepts no day at all, drawn as an empty box inside the parent's, which breaks the rule. On the right, what a method returns: the parent promises a later day, drawn as a box; a smaller box inside it shows that a child may promise more, such as never a Sunday. Laptop returns the same day, drawn as a point outside the parent's box, which breaks the rule.\"><text x=\"175.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what lend accepts</text><rect x=\"20.0\" y=\"34.0\" width=\"310.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"175.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a child may accept more</text><rect x=\"55.0\" y=\"70.0\" width=\"240.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Item: any day</text><rect x=\"115.0\" y=\"150.0\" width=\"120.0\" height=\"46.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"175.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">ReferenceBook</text><text x=\"175.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">no day: breaks it</text><text x=\"175.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preconditions: never stronger</text><path d=\"M360.0 20.0 L360.0 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"540.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what lend returns</text><rect x=\"400.0\" y=\"50.0\" width=\"280.0\" height=\"190.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Item: a later day</text><rect x=\"450.0\" y=\"110.0\" width=\"180.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"540.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a child may promise more:</text><text x=\"540.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">never a Sunday</text><circle cx=\"540.0\" cy=\"258.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"552.0\" y=\"258.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">Laptop: the same day, outside</text><text x=\"540.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">postconditions: never weaker</text></svg>", "caption": "A child may accept more than its parent and promise more. It may not accept less, as ReferenceBook does, or promise less, as Laptop does."}
```

## What the principle says about the fix

The honest conclusion is that a reference book is not a lendable item, and the hierarchy said it
was. Lesson 1 marked that by giving it `loan_days = 0`, which looks harmless and is the same
violation in a quieter form, as the next section shows. The repair is to stop claiming it: an
`Item` with a title and a shelf, and lending as a separate capability that only some items have.
Splitting what an object claims into the parts each caller needs is lesson 4's first principle.

In every language the check falls to people and to tests. Java's compiler verifies that `lend`
has the right signature and nothing about what it does; Go's interfaces, TypeScript's types and
Python's protocols are the same. The next section shows the tool that does check behaviour: one set
of tests, written for the parent, run against every child.
