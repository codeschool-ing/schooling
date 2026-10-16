---
title: Inheritance: one class defined as a change to another
version: 1
---

**Inheritance says that one class is another class with some differences.** The child gets every
field and method of its parent and may add to them or replace them. It is the feature most
courses teach first and the one this course will spend lesson 2 arguing you should reach for
last, so it is worth seeing exactly what it does before anybody argues about it.

The library lends more than books. A book goes out for 14 days, a film on DVD for 7, and a
reference book does not go out at all. Those three share almost everything: a title, a shelf mark,
a way of saying how long a loan lasts. Inheritance puts the shared part in one place.

```schooling-example
{"language": "python", "file": "items.py", "parts": [
 {"code": "# items.py\nclass Item:\n    loan_days = 14\n\n    def __init__(self, title: str, shelf: str):\n        self.title = title\n        self.shelf = shelf\n\n    def describe(self) -> str:\n        return f\"{self.title} [{self.shelf}], {self.loan_days} days\"", "note": "The parent holds what every item has. `loan_days` is a class attribute: one value shared by every instance, until a child says otherwise."},
 {"code": "\n\nclass Book(Item):\n    pass", "note": "`Book(Item)` reads as *a Book is an Item*. With nothing in its body it is an `Item` under another name, which is enough for `isinstance` to tell them apart."},
 {"code": "\n\nclass Film(Item):\n    loan_days = 7\n\n    def __init__(self, title: str, shelf: str, minutes: int):\n        super().__init__(title, shelf)\n        self.minutes = minutes\n\n    def describe(self) -> str:\n        return super().describe() + f\", {self.minutes} min\"", "note": "A film changes one value, adds a field and extends one method. `super()` is the parent's version, so the child adds to the description instead of rewriting it."},
 {"code": "\n\nclass ReferenceBook(Item):\n    loan_days = 0\n\n    def describe(self) -> str:\n        return f\"{self.title} [{self.shelf}], reading room only\"", "note": "This one replaces `describe` entirely. Hold on to it: lesson 3 uses it to show what goes wrong when a child cannot keep a promise its parent made."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = [\n        Book(\"Grande Sertão: Veredas\", \"869.3 ROS\"),\n        Film(\"Central do Brasil\", \"DVD 791 SAL\", 113),\n        ReferenceBook(\"Aurélio\", \"R 469.3 FER\"),\n    ]\n    for item in shelf:\n        print(item.describe())\n    print(isinstance(shelf[1], Item), isinstance(shelf[1], Book))\n    print([cls.__name__ for cls in Film.__mro__])"}
]}
```

```
ana@laptop:~/patterns/oo$ python3 items.py
Grande Sertão: Veredas [869.3 ROS], 14 days
Central do Brasil [DVD 791 SAL], 7 days, 113 min
Aurélio [R 469.3 FER], reading room only
True False
['Film', 'Item', 'object']
```

The last line is the **method resolution order**: when `describe` is called on a film, Python looks
in `Film`, then `Item`, then `object`, and runs the first one it finds. Every language with
inheritance has this lookup; Java and C# walk the same chain from child to parent. Python also
allows a class to have several parents, and then the order is worked out by a rule called C3 —
that is what `__mro__` exists to show you when it matters.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" data-fig=\"l01-items\" aria-label=\"A class diagram of items.py. Item, at the top, has the fields title, shelf and loan_days and the method describe. Three classes point up to it with hollow arrowheads, meaning each is an Item: Book adds nothing; Film sets loan_days to 7, adds minutes and overrides describe; ReferenceBook sets loan_days to 0 and overrides describe. A call to describe on a Film looks in Film first, then Item, then object.\"><rect x=\"260.0\" y=\"14.0\" width=\"180.0\" height=\"96.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"25.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Item</text><path d=\"M260.0 36.5 L440.0 36.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"268.0\" y=\"47.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title: str</text><text x=\"268.0\" y=\"62.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shelf: str</text><text x=\"268.0\" y=\"76.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loan_days = 14</text><path d=\"M260.0 88.0 L440.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"268.0\" y=\"99.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">describe()</text><rect x=\"40.0\" y=\"170.0\" width=\"180.0\" height=\"22.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M130.0 170.0 L130.0 145.0 L350.0 145.0 L350.0 110.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M350.0 110.5 L357.0 122.5 L343.0 122.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"130.0\" y=\"208.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">changes nothing</text><rect x=\"260.0\" y=\"170.0\" width=\"180.0\" height=\"82.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Film</text><path d=\"M260.0 192.5 L440.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"268.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loan_days = 7</text><text x=\"268.0\" y=\"218.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">minutes: int</text><path d=\"M260.0 229.5 L440.0 229.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"268.0\" y=\"240.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">describe()</text><path d=\"M350.0 170.0 L350.0 145.0 L350.0 145.0 L350.0 110.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M350.0 110.5 L357.0 122.5 L343.0 122.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"350.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">adds and extends</text><rect x=\"480.0\" y=\"170.0\" width=\"180.0\" height=\"67.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ReferenceBook</text><path d=\"M480.0 192.5 L660.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"488.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loan_days = 0</text><path d=\"M480.0 215.0 L660.0 215.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"488.0\" y=\"226.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">describe()</text><path d=\"M570.0 170.0 L570.0 145.0 L350.0 145.0 L350.0 110.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M350.0 110.5 L357.0 122.5 L343.0 122.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"570.0\" y=\"253.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">replaces describe</text><text x=\"560.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hollow head: &quot;is a&quot;</text></svg>", "caption": "Three children of one parent. Each inherits the fields and the method, and two of them change what describe does."}
```

## What inheritance couples

A child depends on more of its parent than the parent's public methods. `Film.describe` calls
`super().describe()` and relies on what it returns; `Film.__init__` relies on the parent's
constructor taking exactly a title and a shelf. Change either in `Item` and every child is
affected, including children written by people who never told you they existed. **That is the
cost: the parent's insides become part of the child's contract.** Lesson 2 names it the fragile
base class and measures how fast it grows.

Go has no inheritance at all, by design. It embeds one struct in another, which gives the outer one
the inner one's methods and nothing else; there is no `super`, and the inner struct never calls
back into the outer. JavaScript's `class … extends` is inheritance over prototypes and behaves like
Python's for everything in this lesson.
