---
title: Mixins: inheritance used for parts
version: 1
---

**A mixin is a small class that is never used alone and exists to be inherited alongside others, to
add one capability.** It is composition's idea, a class built from parts, delivered through
inheritance's mechanism. Python supports it directly, because a class may have several parents, and
it inherits both the convenience and the hidden coupling of the first section.

Mixins are sometimes presented as the answer to the class explosion: instead of `BookStudentSms`,
inherit `Book`, `Student` and `Sms` together. That still needs one declared class per combination,
since `class X(A, B, C)` is a class somebody writes. What a mixin does well is narrower: adding the
same small, unrelated ability to many classes that otherwise have nothing in common.

## Four mixins and three classes

```schooling-example
{"language": "python", "file": "mixins.py", "parts": [
 {"code": "# mixins.py\nimport json\n\n\nclass AsDictMixin:\n    def as_dict(self) -> dict:\n        return {k: v for k, v in vars(self).items() if not k.startswith(\"_\")}", "note": "One ability: the object's public fields as a dictionary. It has no `__init__` and no state, which is what makes it safe to mix into anything."},
 {"code": "\n\nclass JsonMixin:\n    def to_json(self) -> str:\n        return json.dumps(self.as_dict(), ensure_ascii=False)", "note": "This one calls `self.as_dict()`, a method it does not define. It quietly assumes another mixin will be there."},
 {"code": "\n\nclass ShelfLabelMixin:\n    def label(self) -> str:\n        return f\"{self.shelf} | {self.title}\"\n\n\nclass BarcodeLabelMixin:\n    def label(self) -> str:\n        return f\"*{self.code}*\"", "note": "Two ways to print a label, both called `label`, both reaching for fields the host class is expected to have."},
 {"code": "\n\nclass Book(JsonMixin, AsDictMixin, ShelfLabelMixin, BarcodeLabelMixin):\n    def __init__(self, title: str, shelf: str, code: str):\n        self.title = title\n        self.shelf = shelf\n        self.code = code\n\n\nclass Film(JsonMixin, AsDictMixin, BarcodeLabelMixin, ShelfLabelMixin):\n    def __init__(self, title: str, shelf: str, code: str):\n        self.title = title\n        self.shelf = shelf\n        self.code = code", "note": "The same four mixins in both classes. The only difference is the order of the last two in the parentheses."},
 {"code": "\n\nclass Member(JsonMixin):\n    def __init__(self, name: str):\n        self.name = name", "note": "A member that wants JSON and took the mixin with that name."},
 {"code": "\n\nif __name__ == \"__main__\":\n    book = Book(\"Iracema\", \"869.3 ALE\", \"B-0042\")\n    film = Film(\"Cidade de Deus\", \"DVD 791 MEI\", \"F-0007\")\n    print(book.to_json())\n    print(book.label())\n    print(film.label())\n    print([cls.__name__ for cls in Film.__mro__])\n    try:\n        Member(\"Bia\").to_json()\n    except AttributeError as caught:\n        print(caught)"}
]}
```

```
ana@laptop:~/patterns/composition$ python3 mixins.py
{"title": "Iracema", "shelf": "869.3 ALE", "code": "B-0042"}
869.3 ALE | Iracema
*F-0007*
['Film', 'JsonMixin', 'AsDictMixin', 'BarcodeLabelMixin', 'ShelfLabelMixin', 'object']
'Member' object has no attribute 'as_dict'
```

The first line is the mixin working as advertised: `Book` got JSON for free. The next three lines
are the costs.

**The order of the parents is behaviour.** `Book` and `Film` inherit the same four classes, and one
prints a shelf label while the other prints a barcode. Python walks the method resolution order and
runs the first `label` it finds; the fourth line shows that order for `Film`, with
`BarcodeLabelMixin` ahead of `ShelfLabelMixin`. Nothing warned about two methods of the same name.
Reorder a class's parents to tidy them up and you have changed what it does.

**A mixin can depend on another without saying so.** `Member` took `JsonMixin` and got an
`AttributeError` the first time it was used, because `to_json` needs `as_dict` from a mixin
`Member` never heard of. That is the fragile base class again, now between siblings: one parent
relies on a method that only another parent provides.

## The same idea in the other three languages

| language | how a class gets a mixin | two mixins with the same method |
|---|---|---|
| Python | list it among the parents | the earlier one in the method resolution order wins, silently |
| Java | an `interface` with `default` methods | compile error until the class overrides the method |
| Go | embed two structs | compile error, *ambiguous selector*, when the method is called |
| TypeScript | a function that returns `class extends Base` | the one applied last wins, silently |

Java and Go refuse the ambiguity, so the clash in `mixins.py` could not compile there. Python and
TypeScript resolve it by a rule, and the rule is correct and easy to forget.

## When a mixin is the right size

The standard library's own mixins show what the safe kind looks like. `collections.abc.Mapping`
gives a class `get`, `keys`, `items` and `__contains__` once the class writes `__getitem__`,
`__iter__` and `__len__`, and **the documentation lists those three as what the mixin requires**.
Its self-calls are the contract, the same as `Notice.body` in the last section.

So a mixin is reasonable when it is stateless, adds methods that no other parent will define, and
states which methods or fields of the host it relies on. When it needs its own state, or two mixins
start to know about each other, they want to be objects the class holds. A `Labeller` in a field
does not care about parent order, and a missing one fails when the object is made, not when a
method is first called.
