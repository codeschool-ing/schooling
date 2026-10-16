---
title: "Value objects: equal when their values are equal"
version: 1
---

**A value object is defined entirely by its values: two of them with the same values are
interchangeable, and none of them ever changes.** Fifty cents is fifty cents; nobody asks *which*
fifty cents. A date, an ISBN, an address and an amount of money are values. When a value has to be
different, you make a new one, the way `3 + 1` does not change the 3.

The wrong idea is that a primitive will do. An amount is an `int`, a currency is a `str`, a fine is
`days * 50`. Then the rules of money live wherever money is touched: one function forgets the
currency, another accepts `0.5`, a third adds euros to reais because both are integers. Each rule
of the value is repeated across the code and enforced nowhere. **A value object is the place those
rules live, once.** Lesson 14 calls the primitive version a smell, *primitive obsession*.

Lesson 1 kept money as whole cents in an `int`, which was right for one class. Now money appears in
fines, in payments and in the limit on borrowing, so it gets a type:

```schooling-example
{"language": "python", "file": "money.py", "parts": [
 {"code": "# money.py\nfrom dataclasses import dataclass, replace\n\n\n@dataclass(frozen=True)\nclass Money:\n    cents: int\n    currency: str = \"BRL\"", "note": "`frozen=True` makes every field read-only after construction, and the generated `__eq__` compares fields. Those two lines are most of what a value object is."},
 {"code": "\n    def __post_init__(self) -> None:\n        if not isinstance(self.cents, int):\n            raise TypeError(f\"cents must be an int, not {type(self.cents).__name__}\")", "note": "A value object refuses to exist in a state that makes no sense. Half a cent is one of those states."},
 {"code": "\n    def __add__(self, other: \"Money\") -> \"Money\":\n        if other.currency != self.currency:\n            raise ValueError(f\"cannot add {other.currency} to {self.currency}\")\n        return Money(self.cents + other.cents, self.currency)\n\n    def __sub__(self, other: \"Money\") -> \"Money\":\n        return self + Money(-other.cents, other.currency)\n\n    def times(self, n: int) -> \"Money\":\n        return Money(self.cents * n, self.currency)", "note": "Arithmetic returns a new `Money` and never changes `self`. Adding two currencies is refused here, once, instead of in every function that adds fines."},
 {"code": "\n    def __str__(self) -> str:\n        return f\"{self.currency} {self.cents // 100}.{self.cents % 100:02d}\""},
 {"code": "\n\nif __name__ == \"__main__\":\n    daily = Money(50)\n    fine = daily.times(3) + Money(25)\n    print(fine, \"|\", fine == Money(175), \"|\", fine is Money(175))\n    print(replace(fine, cents=0))\n    try:\n        fine.cents = 0\n    except AttributeError as err:\n        print(\"refused:\", type(err).__name__, err)\n    for bad in (lambda: fine + Money(100, \"EUR\"), lambda: Money(0.5)):\n        try:\n            bad()\n        except (ValueError, TypeError) as err:\n            print(\"refused:\", err)", "note": "Three days' fine plus 25 cents, compared with a `Money` built separately; then the three refusals."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 money.py
BRL 1.75 | True | False
BRL 0.00
refused: FrozenInstanceError cannot assign to field 'cents'
refused: cannot add EUR to BRL
refused: cents must be an int, not float
```

Three days at 50 cents plus 25 is `BRL 1.75`, and it equals a `Money(175)` made separately:
the first `True`. It is not the same object, the `False` after it, and that does not matter for a
value. `replace` makes a changed copy, here with zero cents, and leaves the original alone. Writing
to a field is refused with `FrozenInstanceError`, adding euros to reais is refused, and so is half
a cent.

## What immutability buys

An immutable value can be shared without fear. The `FINE_LIMIT` of the next section is one
`Money(1000)` that every member compares against; if some code could set its `cents` to 0, every
member would be over the limit at once. Because it is frozen, nobody can, and nobody has to make a
defensive copy before handing it out.

It also makes the entity's job simpler. A member's `owed` is a `Money`. To add a fine, the member
replaces it with `owed + fine`: one assignment, in one method of the member, and nothing else can
change the amount behind the member's back.

| language | a value object |
|---|---|
| Python | `@dataclass(frozen=True)`, or a `NamedTuple` |
| Java | a `record`, whose fields are final and whose `equals` compares them |
| Go | a small struct passed by value, with unexported fields and methods that return new structs |
| TypeScript | a class with `readonly` fields, or `Object.freeze`; `===` still compares references, so add an `equals` method |

TypeScript is the awkward one: `readonly` stops writes at compile time, but two equal values are
still two different references to `===`. An `equals(other)` method, used deliberately, is the
usual answer.

## Entity or value?

The same concept can be either, depending on the context, which is lesson 11 again. In lending, a
copy of *Vidas Secas* is an entity: copy `C-0107` is out to Bia and copy `C-0108` is on the shelf,
and they are not interchangeable. In acquisitions, the two copies on an order are a quantity, 2,
and nobody cares which is which until they arrive. Ask whether anyone would care that it was
swapped for an equal one. If not, make it a value.
