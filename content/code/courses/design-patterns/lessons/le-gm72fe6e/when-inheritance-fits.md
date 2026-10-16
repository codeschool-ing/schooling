---
title: When inheritance is the right tool
version: 1
---

**Inheritance fits when three things hold.** The child really is a kind of the parent everywhere
the parent is used, the parent was designed to be extended, and the hierarchy varies along one axis
only. The *almost* in this lesson's title is these cases, and they are common enough that a rule
of "never inherit" would be as wrong as "always".

The belief to replace is that composition is the modern choice and inheritance the old one, so
inheritance in new code is a smell. Python's own standard library inherits all the time, on
purpose, in exactly the places where the three conditions hold. Here are the three places you will
meet most.

## A family of errors

Exceptions are the clearest true *is a* in most codebases. A `LoanRefused` is a `LibraryError` in
every sense that matters: anywhere that catches `LibraryError` must also catch `LoanRefused`, and
should. The hierarchy has one axis, *what went wrong*, and nobody needs an exception that is both a
refusal and an expiry at once.

## A skeleton with holes in it

The second case is a parent that owns an algorithm and leaves named steps for the children to fill
in. Every notice the library sends has the same shape, a greeting, a body and a signature, and only
the body always differs:

```schooling-example
{"language": "python", "file": "fits.py", "parts": [
 {"code": "# fits.py\nfrom abc import ABC, abstractmethod\n\n\nclass LibraryError(Exception):\n    \"\"\"Anything the library refuses, with a sentence a person can read.\"\"\"\n\n\nclass LoanRefused(LibraryError):\n    pass\n\n\nclass ReservationExpired(LibraryError):\n    pass", "note": "Three lines per exception and no behaviour of their own. What the classes carry is the hierarchy, so an `except` can choose how broadly to catch."},
 {"code": "\n\nclass Notice(ABC):\n    def render(self, name: str) -> str:\n        return \"\\n\".join([f\"Dear {name},\", self.body(), self.sign_off()])", "note": "The parent owns the order of the parts. A child cannot forget the greeting, because it never writes `render`."},
 {"code": "\n    @abstractmethod\n    def body(self) -> str: ...\n\n    def sign_off(self) -> str:\n        return \"Biblioteca do Bairro\"", "note": "Two holes, documented by how they are declared. `body` must be filled in; `sign_off` has a default a child may replace. These are the only self-calls a child is invited to rely on."},
 {"code": "\n\nclass OverdueNotice(Notice):\n    def __init__(self, title: str, cents: int):\n        self.title = title\n        self.cents = cents\n\n    def body(self) -> str:\n        return f\"'{self.title}' is late; the fine so far is {self.cents} cents.\"", "note": "A child fills in the one step it is asked for."},
 {"code": "\n\nclass ReadyNotice(Notice):\n    def __init__(self, title: str):\n        self.title = title\n\n    def body(self) -> str:\n        return f\"'{self.title}' is waiting for you at the desk.\"\n\n    def sign_off(self) -> str:\n        return \"Biblioteca do Bairro, open until 19:00\"", "note": "This one also replaces the optional step."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(OverdueNotice(\"Dom Casmurro\", 250).render(\"Bia\"))\n    print(ReadyNotice(\"Iracema\").render(\"Caio\"))\n    for error in (LoanRefused(\"Bia owes 250 cents\"), ReservationExpired(\"held for 3 days\")):\n        try:\n            raise error\n        except LibraryError as caught:\n            print(type(caught).__name__, \"->\", caught)\n    try:\n        Notice()\n    except TypeError as caught:\n        print(caught)", "note": "Two notices, two errors caught by their common parent, and an attempt to make a notice with no body."}
]}
```

```
ana@laptop:~/patterns/composition$ python3 fits.py
Dear Bia,
'Dom Casmurro' is late; the fine so far is 250 cents.
Biblioteca do Bairro
Dear Caio,
'Iracema' is waiting for you at the desk.
Biblioteca do Bairro, open until 19:00
LoanRefused -> Bia owes 250 cents
ReservationExpired -> held for 3 days
Can't instantiate abstract class Notice without an implementation for abstract method 'body'
```

Compare this with the shelf from the first section. `Shelf.add_all` calling `self.add` was an
accident of implementation that a child happened to depend on. `Notice.render` calling `self.body`
is the whole point of the class, declared with `@abstractmethod` and enforced when somebody forgets
it, as the last line shows. **A self-call is dangerous when it is hidden and safe when it is the
documented contract.** Lesson 6 names this shape the template method.

Even here composition was possible: a `Notice` could hold a `body` function and a `sign_off` string.
With two holes and one axis of variation, the subclass is shorter and reads better, which is
reason enough.

## A framework that asks you to inherit

The third case is a framework that hands you a parent and calls your methods. You have written one
already: every test in `testing-cicd` was a method on a subclass of `unittest.TestCase`, and the
test runner called `setUp` and your `test_` methods on it. Django's models, Java's servlets and
Android's activities work the same way. Here the parent was designed for extension by people who
expected thousands of children, its hooks are documented, and arguing with it costs more than it
saves.

## The conditions, as questions

Before writing `class X(Y)`, ask:

| question | if the answer is no |
|---|---|
| Can an `X` be used everywhere a `Y` is, with no surprises? | it is not an *is a*; hold a `Y` instead (lesson 3 makes this precise) |
| Was `Y` written to be extended, with its self-calls documented? | wrap it; do not subclass it |
| Is there only one thing that varies among the children? | a second axis will multiply; make that axis a part |
| Is the hierarchy one or two levels deep? | a deep tree is a chain of fragile bases |

Languages differ in how they help with the second question. Java and C# let a class refuse children
with `final` or `sealed`, and Kotlin's classes are closed unless marked `open`, which makes
designed-for-extension a declaration rather than a hope. Python has `typing.final`, which a type
checker enforces and the interpreter ignores. TypeScript has no way to forbid subclassing, and Go,
having no inheritance, never asks the question.
