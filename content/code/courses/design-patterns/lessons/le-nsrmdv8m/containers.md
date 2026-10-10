---
title: Containers: wiring done by a machine
version: 1
---

**A dependency injection container is a composition root that works out the wiring for you: you
register which class answers for each need, and it builds an object by reading what its
constructor asks for.** Spring, Guice, .NET's built-in container, NestJS and Angular all have one at
their centre. None of them is magic, and the quickest way to stop treating them as magic is to
build one.

## Thirty lines of container

```schooling-example
{"language": "python", "file": "container.py", "parts": [
 {"code": "# container.py\nimport inspect\nfrom typing import get_type_hints\n\n\nclass Container:\n    def __init__(self):\n        self._providers = {}\n        self._shared = {}", "note": "Two tables: how to build each thing, and the things already built that are meant to be shared."},
 {"code": "\n    def register(self, key, provider, shared=False):\n        self._providers[key] = (provider, shared)", "note": "A key is usually a protocol, such as `Notifier`. The provider is a class to construct or a function to call. `shared=True` means one instance for the life of the container."},
 {"code": "\n    def resolve(self, key):\n        if key in self._shared:\n            return self._shared[key]\n        if key not in self._providers:\n            raise LookupError(f\"nothing registered for {key.__name__}\")\n        provider, shared = self._providers[key]\n        obj = self._build(provider)\n        if shared:\n            self._shared[key] = obj\n        return obj", "note": "Resolving returns a shared instance if there is one, refuses a key nobody registered, and otherwise builds."},
 {"code": "\n    def _build(self, provider):\n        if not inspect.isclass(provider):\n            return provider()\n        hints = get_type_hints(provider.__init__)\n        hints.pop(\"return\", None)\n        args = {name: self.resolve(kind) for name, kind in hints.items()}\n        return provider(**args)", "note": "The trick every container performs. It reads the type hints of `__init__` and resolves each one before calling the constructor. This is called autowiring."}
]}
```

`wired.py` asks the container for an `OverdueNotices` without ever saying how to make one. It then
shows the two lifetimes, and what happens when a registration is missing.

```schooling-example
{"language": "python", "file": "wired.py", "parts": [
 {"code": "# wired.py\nfrom datetime import date\n\nfrom container import Container\nfrom overdue import (Clock, FixedClock, ListedLoans, Loan, LoanStore, Notifier,\n                     OverdueNotices, PrintNotifier)", "note": "The same job and protocols as before. The container needs the protocols as keys."},
 {"code": "\n\ndef configure(c: Container) -> None:\n    c.register(LoanStore, lambda: ListedLoans([\n        Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16))]))\n    c.register(Notifier, PrintNotifier, shared=True)\n    c.register(Clock, lambda: FixedClock(date(2026, 3, 20)))\n    c.register(OverdueNotices, OverdueNotices)", "note": "Registration replaces `build` from the composition root. `ListedLoans` and `FixedClock` need values a container cannot guess, so they are registered as functions."},
 {"code": "\n\nif __name__ == \"__main__\":\n    c = Container()\n    configure(c)\n    notices = c.resolve(OverdueNotices)\n    print(\"sent:\", notices.send_all())\n    print(\"same notifier:\", c.resolve(Notifier) is c.resolve(Notifier))\n    print(\"same clock:\", c.resolve(Clock) is c.resolve(Clock))", "note": "One `resolve` builds four objects: the container reads `loans`, `notifier` and `clock` off the constructor and resolves each."},
 {"code": "\n    bare = Container()\n    bare.register(LoanStore, lambda: ListedLoans([]))\n    bare.register(Notifier, PrintNotifier)\n    bare.register(OverdueNotices, OverdueNotices)\n    try:\n        bare.resolve(OverdueNotices)\n    except LookupError as err:\n        print(\"refused:\", err)", "note": "A second container with no clock registered. The constructor of `OverdueNotices` says it needs one, so the container refuses at `resolve`, before any notice is sent."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 wired.py
to Bia: 'Dom Casmurro' is 4 days late, fine 200 cents
sent: 1
same notifier: True
same clock: False
refused: nothing registered for Clock
```

The notifier was registered as shared, so both requests got the same object; the clock was not, so
each request built a fresh one. That is the whole idea of a **lifetime**. Real containers add a
third, one instance per web request, which is the reason they exist in web frameworks at all.

## When a container is worth it

Compare the two roots of this lesson. `build` in `main.py` is plain code: you can read it, step
through it in a debugger, and a misspelt name is an error before the program does anything.
`configure` is shorter, but the wiring now happens inside `_build`, and a missing registration is
found only when something is resolved. **A container trades code you can read for code you
configure, and the trade pays only when the wiring is large or repetitive.**

It pays in a framework that builds hundreds of objects per request and must give each request its
own database session. It does not pay in a script, a command-line tool or a service of twenty
classes, which is most Python code. The Python community mostly wires by hand for this reason;
FastAPI's `Depends` is the best-known exception, and it is a per-request container in disguise.

| language | what people reach for | the usual habit |
|---|---|---|
| Java | Spring, Guice, Dagger (wiring generated at compile time) | a container in almost every application |
| TypeScript | NestJS and Angular, each with one built in; InversifyJS | a container whenever the framework has one |
| Go | Google's `wire` (generates the wiring you would write), Uber's `fx` | wiring by hand in `main` |
| Python | FastAPI's `Depends`; packages exist but are rarely needed | wiring by hand in `main` |

Dagger and `wire` are worth a second look: they write the composition root as ordinary code at
build time, so the wiring is checked before the program runs. That is the container's convenience
without its main cost.
