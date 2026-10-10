---
title: Singleton, and why to distrust it
version: 1
---

**A singleton is a class that allows exactly one instance of itself and gives everybody a way to
reach it.** It is the best-known pattern in the book and the one experienced developers argue
against most often, because those two halves are different promises and the second one is a global
variable with a respectable name.

"Exactly one instance" is often a real need. A program should have one connection pool, one
configuration, one catalogue in memory. "Reachable from anywhere" is the part that causes the
trouble, and it is not required for the first: one instance created at start-up and passed to
whoever needs it is also exactly one.

## Two singletons in Python

The classic form overrides `__new__`, the method Python calls to create an instance, so it hands
back the same object every time. The Pythonic form is simpler and you have used it already: **a
module is imported once and cached, so an object created at module level is a singleton without
any pattern at all.**

```python
# catalogue.py
class Catalogue:
    def __init__(self):
        self.titles = []

    def add(self, title: str) -> None:
        self.titles.append(title)


shared = Catalogue()
```

```schooling-example
{"language": "python", "file": "singleton.py", "parts": [
 {"code": "# singleton.py\nimport catalogue\nfrom catalogue import shared", "note": "The module is imported twice, under two names. Python runs `catalogue.py` once and hands both names the same module object."},
 {"code": "\n\nclass Settings:\n    _instance = None\n\n    def __new__(cls):\n        if cls._instance is None:\n            cls._instance = super().__new__(cls)\n            cls._instance.daily_fine = 50\n        return cls._instance", "note": "The classic singleton. The first call creates the instance and stores it on the class; every later call returns that one."},
 {"code": "\n\ndef desk_a() -> None:\n    Settings().daily_fine = 75\n    shared.add(\"Vidas Secas\")\n\n\ndef desk_b() -> None:\n    print(\"desk b sees fine:\", Settings().daily_fine)\n    print(\"desk b sees titles:\", catalogue.shared.titles)", "note": "Two functions that never mention each other. The first changes the fine and adds a title; nothing in its signature says it touches anything shared."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(\"same settings:\", Settings() is Settings())\n    print(\"same catalogue:\", shared is catalogue.shared)\n    desk_a()\n    desk_b()", "note": "Both singletons hold, and then the second function sees what the first one did."}
]}
```

Save `catalogue.py` next to it and run `singleton.py`:

```
ana@laptop:~/patterns/gof$ python3 singleton.py
same settings: True
same catalogue: True
desk b sees fine: 75
desk b sees titles: ['Vidas Secas']
```

The two `True`s are the pattern working. The last two lines are its cost: `desk_b` reports a fine
of 75 and a title it never added, changed by a function it has never heard of.

## Three reasons to distrust it

**It hides dependencies.** `desk_b()` takes no arguments and depends on two pieces of global state.
That is the service locator of lesson 5 under another name, with the same consequence: the
signature lies, and you learn what a function uses by reading all of it.

**It leaks between tests.** A test that sets the fine to 75 leaves it at 75 for the next test, and
the suite starts passing or failing according to the order it runs in. Singletons usually grow a
`reset()` method for this reason, which is a method that exists only to undo the pattern.

**It is a trap under threads.** The `if cls._instance is None` check and the assignment below it
are two steps. Two threads can both see `None` and both create an instance. Lesson 18 runs exactly
that race and counts the duplicates.

## What to do instead

Keep "exactly one" and drop "reachable from anywhere". Create the object once, in the composition
root of lesson 5, and pass it to the classes that need it. There is still one catalogue, and now
every class that uses it says so in its constructor, and a test can hand it a fresh one.

A module-level object is acceptable for things that hold no state a test cares about: a logger, a
compiled regular expression, a table of constants. When the object holds data that changes, such
as settings somebody can edit or a cache, treat the module-level instance as a convenience for
`main` and pass it on from there.

| language | how a singleton is usually written |
|---|---|
| Java | a `private` constructor with a `static final` instance, or an `enum` with one value |
| Go | a package-level variable, often set up with `sync.Once` |
| TypeScript | a module that exports one instance: modules are evaluated once |
| Python | a module-level object; `__new__` only when a class must enforce it |

In every one of the four, the frameworks that manage objects for you, Spring's beans or a container
like lesson 5's with `shared=True`, give you a single instance without the global access. That is
the version worth having.
